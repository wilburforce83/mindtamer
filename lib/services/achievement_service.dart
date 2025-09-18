import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

import '../data/hive/boxes.dart';
import '../data/models/achievement.dart' as model;
import '../crafting/models.dart';

class AchievementService {
  static final AchievementService _i = AchievementService._();
  factory AchievementService() => _i;
  AchievementService._();

  bool _loaded = false;
  late final List<Map<String, dynamic>> _defs;
  late final Map<String, Map<String, dynamic>> _byId;

  Future<void> init() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/mindtamer_achievements.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _defs = List<Map<String, dynamic>>.from(json['achievements'] as List);
    _byId = {for (final m in _defs) (m['id'] as String): m};
    _loaded = true;
  }

  // Public: record an equip event
  Future<void> recordEquip(CraftedItem item) async {
    await init();
    final meta = playerMetaBox();
    // Track unique slot usage for ALL_SLOTS_ONCE
    try {
      final slots = (meta.get('ach_unique_equipped_slots') as List?)?.cast<String>().toSet() ?? <String>{};
      slots.add(item.def.slot.name);
      await meta.put('ach_unique_equipped_slots', slots.toList());
    } catch (_) {}
    // Track unique accessories equipped by key
    try {
      final isAccessory = (item.def.equipSlot == 'ring' || item.def.equipSlot == 'neck');
      if (isAccessory) {
        final acc = (meta.get('ach_unique_accessories') as List?)?.cast<String>().toSet() ?? <String>{};
        acc.add(item.def.key);
        await meta.put('ach_unique_accessories', acc.toList());
      }
    } catch (_) {}
    // Evaluate equip achievements
    await _evaluate(event: 'equip', ctx: {
      'event': 'equip',
      'slot': item.def.slot.name,
      'equipSlot': item.def.equipSlot,
      'accessories_equipped': _uniqueCount(meta, 'ach_unique_accessories'),
      'equipped_slots': _uniqueCount(meta, 'ach_unique_equipped_slots'),
    });
  }

  // Public: record battle end
  Future<void> recordBattleEnd({
    required bool victory,
    required int turns,
    bool isBoss = false,
    int damageTaken = 0,
    int itemsUsedTotal = 0,
    int itemsUsedHeal = 0,
    int skillsUsedHeal = 0,
    int hpPct = 100,
    String? weaponKey,
  }) async {
    await init();
    final meta = playerMetaBox();
    final weaponType = _inferWeaponType(weaponKey ?? '');
    // Increment counters for weapon victories
    if (victory && weaponType != null) {
      final key = 'wins_${weaponType.toLowerCase()}';
      final c = (meta.get('ach_counters') as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? <String, int>{};
      c[key] = (c[key] ?? 0) + 1;
      await meta.put('ach_counters', c);
    }
    await _evaluate(event: 'battle_end', ctx: {
      'event': 'battle_end',
      'victory': victory,
      'turns': turns,
      'is_boss': isBoss,
      'damage_taken': damageTaken,
      'items_used.total': itemsUsedTotal,
      'items_used.heal': itemsUsedHeal,
      'skills_used.heal': skillsUsedHeal,
      'hp_pct': hpPct,
      'weapon_type': weaponType,
    });
  }

  // Internal: evaluator for a small subset of conditions used in JSON
  Future<void> _evaluate({required String event, required Map<String, dynamic> ctx}) async {
    final achBox = achievementBox();
    final earned = achBox.values.map((a) => a.key).toSet();
    for (final def in _defs) {
      final trig = def['trigger'] as Map<String, dynamic>?;
      if (trig == null) continue;
      if (trig['event'] != event) continue;
      final id = def['id'] as String;
      if (earned.contains(id)) continue;

      final cond = (trig['condition'] ?? '').toString();
      final counterKey = (trig['counter_key'] ?? '').toString();
      final threshold = int.tryParse((trig['threshold'] ?? '').toString());

      // Allow straight counter/threshold triggers
      if (counterKey.isNotEmpty && threshold != null) {
        final v = _counter(counterKey);
        if (v >= threshold) {
          await _award(id);
          continue;
        }
      }
      // Minimal condition checks used by our pack
      if (_matches(cond, ctx)) {
        await _award(id);
      }
    }
  }

  bool _matches(String cond, Map<String, dynamic> ctx) {
    // Split on && and evaluate simple comparisons
    final parts = cond.split('&&').map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final p in parts) {
      if (p.contains("unique('")) {
        final m = RegExp(r"unique\('([a-zA-Z0-9_]+)'\)\s*>?=\s*(\d+)").firstMatch(p);
        if (m == null) return false;
        final key = m.group(1)!;
        final n = int.parse(m.group(2)!);
        if (_uniqueCount(playerMetaBox(), _mapUniqueKey(key)) < n) return false;
        continue;
      }
      if (p.contains("counter('")) {
        final m = RegExp(r"counter\('([a-zA-Z0-9_]+)'\)\s*>?=\s*(\d+)").firstMatch(p);
        if (m == null) return false;
        final key = m.group(1)!;
        final n = int.parse(m.group(2)!);
        if (_counter(key) < n) return false;
        continue;
      }
      // key comparisons like event=='battle_end'
      final mEq = RegExp(r"([a-zA-Z0-9_\.]+)\s*==\s*'?([A-Za-z0-9_]+)'?").firstMatch(p);
      if (mEq != null) {
        final key = mEq.group(1)!;
        final val = mEq.group(2)!;
        final ctxVal = ctx[key];
        if (ctxVal == null) return false;
        if (ctxVal.toString().toLowerCase() != val.toLowerCase()) return false;
        continue;
      }
      // numeric comparisons like hp_pct<=5, turns>=15, damage_taken==0
      final mNum = RegExp(r"([a-zA-Z0-9_\.]+)\s*([<>]=|==|<|>)\s*(\d+)").firstMatch(p);
      if (mNum != null) {
        final key = mNum.group(1)!;
        final op = mNum.group(2)!;
        final n = int.parse(mNum.group(3)!);
        final v = int.tryParse((ctx[key] ?? '0').toString()) ?? 0;
        bool ok;
        switch (op) {
          case '==': ok = v == n; break;
          case '>=': ok = v >= n; break;
          case '<=': ok = v <= n; break;
          case '>': ok = v > n; break;
          case '<': ok = v < n; break;
          default: ok = false; break;
        }
        if (!ok) return false;
        continue;
      }
      // booleans like victory==true, is_boss==true are handled by mEq above
    }
    return true;
  }

  String _mapUniqueKey(String k) {
    switch (k) {
      case 'accessories_equipped': return 'ach_unique_accessories';
      case 'equipped_slots': return 'ach_unique_equipped_slots';
    }
    return k;
  }

  int _uniqueCount(Box meta, String key) {
    try { return ((meta.get(key) as List?)?.length ?? 0); } catch (_) { return 0; }
  }

  int _counter(String key) {
    try {
      final c = (playerMetaBox().get('ach_counters') as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? <String, int>{};
      return c[key] ?? 0;
    } catch (_) { return 0; }
  }

  Future<void> _award(String id) async {
    final box = achievementBox();
    try {
      await box.put(id, model.Achievement(id: id, key: id, earnedAt: DateTime.now().toUtc()));
    } catch (_) {}
  }

  static String? _inferWeaponType(String key) {
    final k = key.toLowerCase();
    if (k.contains('axe')) return 'Axe';
    if (k.contains('bow') && !k.contains('cross')) return 'Bow';
    if (k.contains('cross') && k.contains('bow')) return 'Crossbow';
    if (k.contains('dagger') || k.contains('knife')) return 'Dagger';
    if (k.contains('sword')) return 'Sword';
    if (k.contains('mace') || k.contains('hammer')) return 'Mace';
    if (k.contains('staff') || k.contains('rod') || k.contains('wand')) return 'Staff';
    return null;
  }

  // UI helper: get definition by id
  Map<String, dynamic>? defOf(String id) => _byId[id];
}

