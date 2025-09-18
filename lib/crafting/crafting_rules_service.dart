import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

class CraftingRulesService {
  static final CraftingRulesService _i = CraftingRulesService._();
  factory CraftingRulesService() => _i;
  CraftingRulesService._();

  bool _loaded = false;
  late final Map<String, dynamic> _json;

  Future<void> init() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/crafting_rules.json');
    _json = json.decode(raw) as Map<String, dynamic>;
    _loaded = true;
  }

  String _eraForTier(int tier) {
    if (tier <= 6) return 'early';
    if (tier <= 10) return 'mid';
    return 'late';
  }

  int rollBaseDef({required int tier, required SlotId slot}) {
    final bands = (_json['def_bands_by_tier'] as Map?) ?? const {};
    List band = (bands['$tier'] as List?) ?? (_json['def_bands']?[_eraForTier(tier)] as List? ?? const [1, 2]);
    int min = (band.isNotEmpty ? int.tryParse(band[0].toString()) : null) ?? 1;
    int max = (band.length > 1 ? int.tryParse(band[1].toString()) : null) ?? (min + 1);
    if (max < min) max = min;
    final r = Random();
    final base = min + r.nextInt((max - min) + 1);
    // Slot weighting: chest 1.0, head 0.7, hands 0.6, legs 0.8, feet 0.6
    const weights = {
      SlotId.chest: 1.0,
      SlotId.head: 0.7,
      SlotId.hands: 0.6,
      SlotId.legs: 0.8,
      SlotId.feet: 0.6,
      SlotId.weapon: 0.0,
    };
    final w = weights[slot] ?? 1.0;
    return (base * w).round().clamp(0, 9999);
  }

  Map<String, int> rollEnchantments({
    required bool isWeapon,
    required int tier,
    required Rarity rarity,
    required ElementType element,
  }) {
    final era = _eraForTier(tier);
    final kind = isWeapon ? 'weapon' : 'armor';
    final section = (((_json['enchantments'] ?? const {}) as Map)[kind] ?? const {}) as Map;
    final eraSec = (section[era] ?? const {}) as Map;
    final rarSec = (eraSec[rarity.name] ?? const {}) as Map;
    final countRange = (rarSec['count_range'] as List?) ?? const [1, 2];
    final minC = int.tryParse(countRange.first.toString()) ?? 1;
    final maxC = int.tryParse((countRange.length > 1 ? countRange[1] : countRange.first).toString()) ?? minC;
    final ranges = (rarSec['stat_ranges'] ?? const {}) as Map;
    if (ranges.isEmpty) return const {};

    // Element preference order
    var order = _preferredStatsFor(element, isWeapon: isWeapon)
        .where((s) => ranges.containsKey(s))
        .toList();
    // For armor, deprioritize DEF so we don't only ever roll DEF
    // and add a bit of variety by shuffling non-DEF candidates.
    if (!isWeapon && order.isNotEmpty) {
      final nonDef = order.where((s) => s != 'def').toList();
      final onlyDef = nonDef.isEmpty;
      final rlocal = Random();
      nonDef.shuffle(rlocal);
      final defs = order.where((s) => s == 'def').toList();
      order = onlyDef ? defs : [...nonDef, ...defs];
    }
    if (order.isEmpty) return const {};

    final r = Random();
    final count = minC + r.nextInt((maxC - minC + 1).clamp(1, 3));
    final chosen = <String>{};
    final out = <String, int>{};
    for (final s in order) {
      if (chosen.length >= count) break;
      chosen.add(s);
      final band = (ranges[s] as List?) ?? const [0, 0];
      final mn = (band.isNotEmpty ? int.tryParse(band[0].toString()) : null) ?? 0;
      final mx = (band.length > 1 ? int.tryParse(band[1].toString()) : null) ?? mn;
      final v = mn + (mx > mn ? r.nextInt(mx - mn + 1) : 0);
      if (v != 0) out['mod_${s.toLowerCase()}'] = v;
    }
    return out;
  }

  List<String> _preferredStatsFor(ElementType e, {required bool isWeapon}) {
    switch (e) {
      case ElementType.fire:
        return isWeapon ? ['atk', 'spd', 'def', 'spirit', 'hp'] : ['def', 'hp', 'atk', 'spd', 'spirit'];
      case ElementType.water:
        return isWeapon ? ['spirit', 'atk', 'hp', 'def', 'spd'] : ['hp', 'spirit', 'def', 'spd', 'atk'];
      case ElementType.air:
        return isWeapon ? ['spd', 'atk', 'spirit', 'hp', 'def'] : ['spd', 'def', 'hp', 'spirit', 'atk'];
      case ElementType.nature:
        return isWeapon ? ['hp', 'atk', 'spirit', 'spd', 'def'] : ['hp', 'def', 'spirit', 'spd', 'atk'];
      case ElementType.metal:
        return isWeapon ? ['def', 'atk', 'hp', 'spd', 'spirit'] : ['def', 'hp', 'atk', 'spd', 'spirit'];
      case ElementType.light:
        return isWeapon ? ['spirit', 'atk', 'spd', 'hp', 'def'] : ['spirit', 'hp', 'def', 'spd', 'atk'];
      case ElementType.shadow:
        return isWeapon ? ['atk', 'spd', 'spirit', 'def', 'hp'] : ['def', 'spd', 'atk', 'spirit', 'hp'];
    }
  }
}
