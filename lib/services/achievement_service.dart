import 'package:hive/hive.dart';

import '../crafting/models.dart';
import '../data/hive/boxes.dart';
import '../data/models/achievement.dart' as model;
import 'achievement_definitions.dart';

class AchievementService {
  static final AchievementService _i = AchievementService._();
  factory AchievementService() => _i;
  AchievementService._();

  bool _loaded = false;
  late final List<Map<String, dynamic>> _defs;
  late final Map<String, Map<String, dynamic>> _byId;

  Future<void> init() async {
    if (_loaded) return;
    _defs = buildAchievementDefinitions();
    _byId = {for (final m in _defs) (m['id'] as String): m};
    _loaded = true;
  }

  List<Map<String, dynamic>> allDefinitions() => List.unmodifiable(_defs);

  Map<String, dynamic>? defOf(String id) => _byId[id];

  Set<String> earnedIds() {
    try {
      return achievementBox().values.map((e) => e.id).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  int progressCurrentFor(Map<String, dynamic> def) {
    final kind = def['progress_kind']?.toString();
    final key = def['progress_key']?.toString();
    if (kind == null || key == null || key.isEmpty) return 0;
    switch (kind) {
      case 'counter':
        return _counter(key);
      case 'unique':
        return _uniqueCount(playerMetaBox(), _mapUniqueKey(key));
    }
    return 0;
  }

  int progressTargetFor(Map<String, dynamic> def) {
    return int.tryParse((def['progress_target'] ?? '0').toString()) ?? 0;
  }

  double progressFractionFor(Map<String, dynamic> def) {
    final target = progressTargetFor(def);
    if (target <= 0) return 0;
    final current = progressCurrentFor(def);
    return (current / target).clamp(0.0, 1.0);
  }

  Future<void> recordJournalSaved({
    required Iterable<String> tags,
    required bool hasBody,
    required int wordCount,
    required String sentiment,
  }) async {
    await init();
    final meta = playerMetaBox();
    await _incrementCounter('journal_entries');
    if (hasBody) {
      await _incrementCounter('journal_entries_with_body');
    }
    for (final tag in tags) {
      await _addUnique('ach_unique_journal_tags', tag.trim().toLowerCase());
    }
    await _evaluate(event: 'journal_saved', ctx: {
      'event': 'journal_saved',
      'tag_count': tags.length,
      'has_body': hasBody,
      'word_count': wordCount,
      'sentiment': sentiment,
      'journal_entries': _counter('journal_entries'),
      'unique_journal_tags':
          _uniqueCount(meta, _mapUniqueKey('journal_tags')),
    });
  }

  Future<void> recordMoodSnapshot({
    required int snapshotsToday,
    required DateTime timestamp,
  }) async {
    await init();
    final meta = playerMetaBox();
    await _incrementCounter('mood_records');
    await _addUnique('ach_unique_mood_days', _dayKey(timestamp));
    await _evaluate(event: 'mood_recorded', ctx: {
      'event': 'mood_recorded',
      'snapshots_today': snapshotsToday,
      'mood_records': _counter('mood_records'),
      'unique_mood_days': _uniqueCount(meta, _mapUniqueKey('mood_days')),
    });
  }

  Future<void> recordMedPlanCreated({
    required int totalPlans,
    required int scheduleCount,
  }) async {
    await init();
    await _setCounter('med_plans', totalPlans);
    await _evaluate(event: 'med_plan_created', ctx: {
      'event': 'med_plan_created',
      'schedule_count': scheduleCount,
      'med_plans': _counter('med_plans'),
    });
  }

  Future<void> recordMedLog({
    required bool taken,
    required DateTime day,
  }) async {
    await init();
    final meta = playerMetaBox();
    await _incrementCounter('med_logs_total');
    if (taken) {
      await _incrementCounter('med_taken');
      await _addUnique('ach_unique_med_days', _dayKey(day));
    } else {
      await _incrementCounter('med_skipped');
    }
    await _evaluate(event: 'med_logged', ctx: {
      'event': 'med_logged',
      'taken': taken,
      'med_taken': _counter('med_taken'),
      'med_logs_total': _counter('med_logs_total'),
      'unique_med_days': _uniqueCount(meta, _mapUniqueKey('med_days')),
    });
  }

  Future<void> recordEquip(CraftedItem item) async {
    await init();
    final meta = playerMetaBox();
    await _incrementCounter('equip_actions');
    try {
      final slots =
          (meta.get('ach_unique_equipped_slots') as List?)?.cast<String>().toSet() ??
              <String>{};
      slots.add(item.def.slot.name);
      await meta.put('ach_unique_equipped_slots', slots.toList());
    } catch (_) {}
    try {
      final isAccessory =
          item.def.equipSlot == 'ring' || item.def.equipSlot == 'neck';
      if (isAccessory) {
        final acc = (meta.get('ach_unique_accessories') as List?)
                ?.cast<String>()
                .toSet() ??
            <String>{};
        acc.add(item.def.key);
        await meta.put('ach_unique_accessories', acc.toList());
      }
    } catch (_) {}
    await _evaluate(event: 'equip', ctx: {
      'event': 'equip',
      'slot': item.def.slot.name,
      'equipSlot': item.def.equipSlot,
      'equip_actions': _counter('equip_actions'),
      'accessories_equipped':
          _uniqueCount(meta, _mapUniqueKey('accessories_equipped')),
      'equipped_slots': _uniqueCount(meta, _mapUniqueKey('equipped_slots')),
    });
  }

  Future<void> recordSpriteEquipped() async {
    await init();
    await _incrementCounter('sprite_equips');
    await _evaluate(event: 'sprite_equipped', ctx: {
      'event': 'sprite_equipped',
      'sprite_equips': _counter('sprite_equips'),
    });
  }

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
    await _incrementCounter('battles_total');
    if (victory) {
      await _incrementCounter('battles_won');
    } else {
      await _incrementCounter('battles_lost');
    }
    if (victory && isBoss) {
      await _incrementCounter('boss_defeats');
    }
    final weaponType = _inferWeaponType(weaponKey ?? '');
    await _evaluate(event: 'battle_end', ctx: {
      'event': 'battle_end',
      'victory': victory,
      'turns': turns,
      'is_boss': isBoss,
      'damage_taken': damageTaken,
      'items_used_total': itemsUsedTotal,
      'items_used_heal': itemsUsedHeal,
      'skills_used_heal': skillsUsedHeal,
      'hp_pct': hpPct,
      'weapon_type': weaponType,
      'battles_total': _counter('battles_total'),
      'battles_won': _counter('battles_won'),
      'boss_defeats': _counter('boss_defeats'),
    });
  }

  Future<void> recordCraft({
    required String mode,
    required CraftedItem result,
  }) async {
    await init();
    await _incrementCounter('craft_total');
    switch (mode) {
      case 'echo_echo':
        await _incrementCounter('craft_from_echoes');
        break;
      case 'item_echo':
        await _incrementCounter('craft_upgrades');
        break;
      case 'item_item':
        await _incrementCounter('craft_fusions');
        break;
    }
    final qualityRank = _rarityRank(result.rarity);
    if (qualityRank >= _rarityRank(Rarity.rare)) {
      await _incrementCounter('craft_rare_or_better');
    }
    await _evaluate(event: 'craft', ctx: {
      'event': 'craft',
      'mode': mode,
      'rarity': result.rarity.name,
      'quality_rank': qualityRank,
      'slot': result.def.slot.name,
      'tier': result.tier,
      'craft_total': _counter('craft_total'),
      'craft_from_echoes': _counter('craft_from_echoes'),
      'craft_upgrades': _counter('craft_upgrades'),
      'craft_fusions': _counter('craft_fusions'),
      'craft_rare_or_better': _counter('craft_rare_or_better'),
    });
  }

  Future<void> recordItemUsed({
    required String type,
    required bool healing,
    required bool inBattle,
  }) async {
    await init();
    await _incrementCounter('item_uses');
    if (healing) {
      await _incrementCounter('healing_item_uses');
    }
    if (inBattle) {
      await _incrementCounter('battle_item_uses');
    }
    await _evaluate(event: 'item_used', ctx: {
      'event': 'item_used',
      'type': type,
      'healing': healing,
      'in_battle': inBattle,
      'item_uses': _counter('item_uses'),
      'healing_item_uses': _counter('healing_item_uses'),
    });
  }

  Future<void> recordItemCollected({
    required String type,
    int qty = 1,
  }) async {
    await init();
    await _incrementCounter('items_collected', by: qty);
    await _evaluate(event: 'item_collected', ctx: {
      'event': 'item_collected',
      'type': type,
      'qty': qty,
      'items_collected': _counter('items_collected'),
    });
  }

  Future<void> recordEchoCollected({
    required String element,
    required String rarity,
  }) async {
    await init();
    final meta = playerMetaBox();
    await _incrementCounter('echoes_collected');
    await _addUnique('ach_unique_echo_elements', element.toLowerCase());
    await _evaluate(event: 'echo_collected', ctx: {
      'event': 'echo_collected',
      'element': element,
      'rarity': rarity,
      'echoes_collected': _counter('echoes_collected'),
      'unique_echo_elements':
          _uniqueCount(meta, _mapUniqueKey('echo_elements')),
    });
  }

  Future<void> recordSummonCreated() async {
    await init();
    await _incrementCounter('summons_created');
    await _evaluate(event: 'summon_created', ctx: {
      'event': 'summon_created',
      'summons_created': _counter('summons_created'),
    });
  }

  Future<void> recordLevelReached(int level) async {
    await init();
    await _setCounter('level_reached', level);
    await _evaluate(event: 'progression', ctx: {
      'event': 'progression',
      'level': level,
      'level_reached': _counter('level_reached'),
    });
  }

  Future<void> _evaluate({
    required String event,
    required Map<String, dynamic> ctx,
  }) async {
    final achBox = achievementBox();
    final earned = achBox.values.map((a) => a.id).toSet();
    for (final def in _defs) {
      final trig = def['trigger'] as Map<String, dynamic>?;
      if (trig == null) continue;
      if (trig['event'] != event) continue;
      final id = def['id'] as String;
      if (earned.contains(id)) continue;

      final cond = (trig['condition'] ?? '').toString();
      final counterKey = (trig['counter_key'] ?? '').toString();
      final threshold = int.tryParse((trig['threshold'] ?? '').toString());

      if (counterKey.isNotEmpty && threshold != null) {
        final v = _counter(counterKey);
        if (v >= threshold) {
          await _award(id);
          continue;
        }
      }
      if (_matches(cond, ctx)) {
        await _award(id);
      }
    }
  }

  bool _matches(String cond, Map<String, dynamic> ctx) {
    if (cond.trim().isEmpty) return true;
    final parts =
        cond.split('&&').map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final p in parts) {
      if (p.contains("unique('")) {
        final m = RegExp(r"unique\('([a-zA-Z0-9_]+)'\)\s*>?=\s*(\d+)")
            .firstMatch(p);
        if (m == null) return false;
        final key = m.group(1)!;
        final n = int.parse(m.group(2)!);
        if (_uniqueCount(playerMetaBox(), _mapUniqueKey(key)) < n) {
          return false;
        }
        continue;
      }
      if (p.contains("counter('")) {
        final m = RegExp(r"counter\('([a-zA-Z0-9_]+)'\)\s*>?=\s*(\d+)")
            .firstMatch(p);
        if (m == null) return false;
        final key = m.group(1)!;
        final n = int.parse(m.group(2)!);
        if (_counter(key) < n) return false;
        continue;
      }
      final mEq = RegExp(r"([a-zA-Z0-9_\.]+)\s*==\s*'?([A-Za-z0-9_]+)'?")
          .firstMatch(p);
      if (mEq != null) {
        final key = mEq.group(1)!;
        final val = mEq.group(2)!;
        final ctxVal = ctx[key];
        if (ctxVal == null) return false;
        if (ctxVal.toString().toLowerCase() != val.toLowerCase()) {
          return false;
        }
        continue;
      }
      final mNum =
          RegExp(r"([a-zA-Z0-9_\.]+)\s*([<>]=|==|<|>)\s*(\d+)").firstMatch(p);
      if (mNum != null) {
        final key = mNum.group(1)!;
        final op = mNum.group(2)!;
        final n = int.parse(mNum.group(3)!);
        final v = int.tryParse((ctx[key] ?? '0').toString()) ?? 0;
        final ok = switch (op) {
          '==' => v == n,
          '>=' => v >= n,
          '<=' => v <= n,
          '>' => v > n,
          '<' => v < n,
          _ => false,
        };
        if (!ok) return false;
        continue;
      }
    }
    return true;
  }

  String _mapUniqueKey(String k) {
    switch (k) {
      case 'accessories_equipped':
        return 'ach_unique_accessories';
      case 'equipped_slots':
        return 'ach_unique_equipped_slots';
      case 'journal_tags':
        return 'ach_unique_journal_tags';
      case 'mood_days':
        return 'ach_unique_mood_days';
      case 'med_days':
        return 'ach_unique_med_days';
      case 'echo_elements':
        return 'ach_unique_echo_elements';
    }
    return k;
  }

  int _uniqueCount(Box meta, String key) {
    try {
      return ((meta.get(key) as List?)?.length ?? 0);
    } catch (_) {
      return 0;
    }
  }

  int _counter(String key) {
    try {
      final c = (playerMetaBox().get('ach_counters') as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v as int)) ??
          <String, int>{};
      return c[key] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _incrementCounter(String key, {int by = 1}) async {
    final c = (playerMetaBox().get('ach_counters') as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v as int)) ??
        <String, int>{};
    c[key] = (c[key] ?? 0) + by;
    await playerMetaBox().put('ach_counters', c);
  }

  Future<void> _setCounter(String key, int value) async {
    final c = (playerMetaBox().get('ach_counters') as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v as int)) ??
        <String, int>{};
    c[key] = value > (c[key] ?? 0) ? value : (c[key] ?? 0);
    await playerMetaBox().put('ach_counters', c);
  }

  Future<void> _addUnique(String key, String rawValue) async {
    final value = rawValue.trim().toLowerCase();
    if (value.isEmpty) return;
    final meta = playerMetaBox();
    final list = (meta.get(key) as List?)?.cast<String>().toSet() ?? <String>{};
    if (list.add(value)) {
      await meta.put(key, list.toList());
    }
  }

  Future<void> _award(String id) async {
    final box = achievementBox();
    try {
      await box.put(
        id,
        model.Achievement(
          id: id,
          key: id,
          earnedAt: DateTime.now().toUtc(),
        ),
      );
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
    if (k.contains('staff') || k.contains('rod') || k.contains('wand')) {
      return 'Staff';
    }
    return null;
  }

  int _rarityRank(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 0;
      case Rarity.uncommon:
        return 1;
      case Rarity.rare:
        return 2;
      case Rarity.epic:
        return 3;
      case Rarity.legendary:
        return 4;
    }
  }

  String _dayKey(DateTime date) {
    final local = date.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }
}
