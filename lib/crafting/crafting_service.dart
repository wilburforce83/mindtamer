import 'package:uuid/uuid.dart';
import 'models.dart';
import 'craft_debug.dart';
import 'asset_index_service.dart';
import 'gear_catalog_service.dart';
import 'crafting_rules_service.dart';
import '../data/hive/boxes.dart';

class CraftingService {
  final AssetIndexService assets;
  CraftingService(this.assets);
  final _uuid = const Uuid();

  Future<CraftedItem> craftArmorFromEchoes(Echo a, Echo b,
      {required String playerClass}) async {
    // Ensure all indices/rules are ready before routing
    await assets.init();
    await GearCatalogService().init();
    await CraftingRulesService().init();
    final rarity = (a.rarity.index >= b.rarity.index) ? a.rarity : b.rarity;
    final element = (a.rarity.index > b.rarity.index) ? a.element : b.element;
    // Decide outcome type: armor 60%, weapon 25%, accessory 15%
    final r = DateTime.now().microsecondsSinceEpoch % 100;
    String route = 'armor';
    ItemDef def;
    int tier = 1;
    if (r < 25) {
      // Weapon — prefer classAffinity
      if (assets.weaponDefs.isNotEmpty) {
        final pref = assets.weaponDefs
            .where((d) =>
                (d.classAffinity ?? '').toLowerCase() ==
                playerClass.toLowerCase())
            .toList();
        final pool = pref.isNotEmpty ? pref : assets.weaponDefs;
        pool.shuffle();
        def = pool.first;
      } else {
        // Fallback single weapon per class
        final cls = playerClass.toLowerCase();
        final fallbackPath =
            'assets/images/weapons/$cls/${_fallbackWeaponFile(cls)}';
        final key = fallbackPath.split('/').last.replaceAll('_32.png', '');
        def = ItemDef(
            key: key,
            iconPath: fallbackPath,
            slot: SlotId.weapon,
            classAffinity: playerClass);
      }
      route = 'weapon';
    } else if (r < 40) {
      // Accessory — choose whichever pool has items; prefer ring if both non-empty randomly
      final rings = assets.accessoryDefs['ring'] ?? const <ItemDef>[];
      final necks = assets.accessoryDefs['neck'] ?? const <ItemDef>[];
      List<ItemDef> pool = const <ItemDef>[];
      if (rings.isNotEmpty && necks.isNotEmpty) {
        pool = (r % 2 == 0) ? rings : necks;
      } else if (rings.isNotEmpty) {
        pool = rings;
      } else if (necks.isNotEmpty) {
        pool = necks;
      }
      if (pool.isNotEmpty) {
        pool = List<ItemDef>.from(pool)..shuffle();
        def = pool.first;
        route = 'accessory';
      } else {
        // fallback accessory (ring) when pools empty; if even that fails, fallback to armor
        final file = _fallbackRingFile();
        if (file != null) {
          final path = 'assets/images/accessories/rings/$file';
          final key = file.replaceAll('_32.png', '');
          def = ItemDef(
              key: key,
              iconPath: path,
              slot: SlotId.hands,
              classAffinity: null,
              equipSlot: 'ring');
          route = 'accessory';
        } else {
          final desiredSlot = _nextCraftSlot();
          final stage = _stageForTier(1);
          def = pickClassSlotStageArmorDef(playerClass, desiredSlot, stage) ??
              pickClassWeightedArmorDef(playerClass);
          route = 'armor';
        }
      }
    } else {
      // Armor — rotate slot and pick class+stage art
      final desiredSlot = _nextCraftSlot();
      final stage = _stageForTier(1);
      final slotName = desiredSlot.name;
      final catalogPath =
          GearCatalogService().imageFor(playerClass, 1, slotName);
      if (catalogPath != null && catalogPath.isNotEmpty) {
        final key = catalogPath.split('/').last.replaceAll('_32.png', '');
        def = ItemDef(
            key: key,
            iconPath: catalogPath,
            slot: desiredSlot,
            classAffinity: playerClass);
      } else {
        def = pickClassSlotStageArmorDef(playerClass, desiredSlot, stage) ??
            pickClassWeightedArmorDef(playerClass);
      }
      route = 'armor';
    }
    // Record debug RNG and route selection
    try {
      CraftDebug.record(roll: r, route: route);
    } catch (_) {}
    final titles = [...a.journalTitles, ...b.journalTitles];
    final isAccessory = (def.equipSlot != null && def.equipSlot!.isNotEmpty);
    final isWeapon = def.slot == SlotId.weapon;
    final name = (isWeapon || isAccessory)
        ? _nameFromFileAndTitles(element, titles, def: def)
        : _catalogName(playerClass, tier, element, titles, def: def);
    final stats = _buildStats(
      slot: def.slot,
      tier: tier,
      rarity: rarity,
      classBonus: false,
      playerClass: playerClass,
      classAffinity: def.classAffinity,
      element: element,
    );
    return CraftedItem(
      id: _uuid.v4(),
      def: def,
      tier: tier,
      rarity: rarity,
      element: element,
      displayName: name,
      dnaJournalTitles: _dedupeTitles(titles, maxKeep: 50),
      upgradeStepsInTier: 0,
      stats: stats,
      classAffinity: def.classAffinity,
    );
  }

  String _nameFromFileAndTitles(ElementType el, List<String> titles,
      {required ItemDef def}) {
    // Build base from the file key for non-armor (weapon/accessory).
    final base = _displayBaseFromKey(def.key, classAffinity: def.classAffinity);
    final words = _twoWordsFromTitles(titles);
    final w1 = words.isNotEmpty ? words[0] : _adjFor(el);
    final w2 = words.length >= 2 ? words[1] : _epithetFor(el);
    return '$base of $w1 $w2';
  }

  String _displayBaseFromKey(String key, {String? classAffinity}) {
    // Normalize underscores to words, special-case `_s_` → “'s ”
    final parts = key.split('_').where((t) => t.isNotEmpty).toList();
    if (parts.isEmpty) return _capWords(key);
    final out = <String>[];
    for (int i = 0; i < parts.length; i++) {
      final tok = parts[i];
      if (tok == 's' && out.isNotEmpty) {
        // attach possessive to previous token
        out[out.length - 1] = "${out.last}'s";
      } else {
        out.add(_cap(tok));
      }
    }
    return out.join(' ');
  }

  String _fallbackWeaponFile(String cls) {
    switch (cls) {
      case 'alchemist':
        return 'retort_staff_32.png';
      case 'artificer':
        return 'gear_mace_32.png';
      case 'empath':
        return 'prayer_staff_32.png';
      case 'oracle':
        return 'verdict_scepter_32.png';
      case 'sage':
        return 'sagewood_staff_32.png';
      case 'seer':
        return 'diviner_s_rod_32.png';
      case 'sentinel':
        return 'bastion_gladius_32.png';
      case 'shadow':
        return 'night_katars_32.png';
      case 'trickster':
        return 'flicker_dagger_32.png';
      case 'warden':
        return 'bulwark_longsword_32.png';
      default:
        return 'sagewood_staff_32.png';
    }
  }

  String? _fallbackRingFile() {
    return 'iron_band_32.png';
  }

  Future<CraftedItem> upgradeWithEcho(CraftedItem it, Echo e,
      {required String playerClass}) async {
    await assets.init();
    await GearCatalogService().init();
    await CraftingRulesService().init();
    final newSteps = it.upgradeStepsInTier + 1;
    final tierUp = (newSteps >= 3) ? 1 : 0;
    final tier = (tierUp == 1) ? (it.tier < 13 ? it.tier + 1 : 13) : it.tier;
    final steps = (tierUp == 1) ? 0 : newSteps;
    final upgradedRarity =
        (e.rarity.index > it.rarity.index) ? e.rarity : it.rarity;
    final element = e.element; // last infusion dominates
    final titles = [...it.dnaJournalTitles, ...e.journalTitles];
    final classBonus =
        it.classAffinity != null && it.classAffinity == playerClass;
    final stats = _buildStats(
      slot: it.def.slot,
      tier: tier,
      rarity: upgradedRarity,
      classBonus: classBonus,
      playerClass: playerClass,
      classAffinity: it.classAffinity,
      element: element,
    );
    final isAccessory = (it.def.equipSlot ?? '').isNotEmpty;
    final isWeapon = it.def.slot == SlotId.weapon;
    final displayName = (isWeapon || isAccessory)
        ? _nameFromFileAndTitles(element, titles, def: it.def)
        : _catalogName(playerClass, tier, element, titles, def: it.def);
    // Swap art when crossing era thresholds according to catalog (or anytime mapping exists)
    final slotName = it.def.slot.name;
    final newPath = GearCatalogService().imageFor(playerClass, tier, slotName);
    ItemDef? newDef;
    if (newPath != null && newPath.isNotEmpty && newPath != it.def.iconPath) {
      final key = newPath.split('/').last.replaceAll('_32.png', '');
      newDef = ItemDef(
          key: key,
          iconPath: newPath,
          slot: it.def.slot,
          classAffinity: it.classAffinity ?? playerClass);
    }
    return it.copyWith(
      def: newDef,
      tier: tier,
      rarity: upgradedRarity,
      element: element,
      displayName: displayName,
      dnaJournalTitles: _dedupeTitles(titles, maxKeep: 100),
      upgradeStepsInTier: steps,
      stats: stats,
    );
  }

  Future<CraftedItem> craftFromItems(CraftedItem a, CraftedItem b,
      {required String playerClass}) async {
    await assets.init();
    await GearCatalogService().init();
    await CraftingRulesService().init();
    // Fusion rules: choose slot (prefer same slot, else use first's), tier=max plus 30% chance +1
    final slot = (a.def.slot == b.def.slot) ? a.def.slot : a.def.slot;
    int tier = a.tier > b.tier ? a.tier : b.tier;
    if (DateTime.now().microsecondsSinceEpoch % 100 < 30) {
      tier = (tier < 13) ? tier + 1 : 13;
    }
    final rarity = (a.rarity.index >= b.rarity.index) ? a.rarity : b.rarity;
    final element = a.element; // preserve A's element for flavor
    final classAff = a.classAffinity ?? b.classAffinity;
    // Pick icon via catalog for class & tier
    final path = GearCatalogService().imageFor(playerClass, tier, slot.name);
    final def = (path != null && path.isNotEmpty)
        ? ItemDef(
            key: path.split('/').last.replaceAll('_32.png', ''),
            iconPath: path,
            slot: slot,
            classAffinity: classAff)
        : pickClassSlotStageArmorDef(playerClass, slot, _stageForTier(tier)) ??
            pickClassWeightedArmorDef(playerClass);

    // Base stats by rules
    final base = _buildStats(
      slot: slot,
      tier: tier,
      rarity: rarity,
      classBonus: false,
      playerClass: playerClass,
      classAffinity: def.classAffinity,
      element: element,
    );
    // Combine enchantment mods from inputs; similar armor (same slot, non-weapon) gets 1.5x multiplier
    bool similar = (a.def.slot == b.def.slot && a.def.slot != SlotId.weapon);
    double mul = similar ? 1.5 : 1.0;
    final mods = <String, int>{};
    void addMods(Map<String, num> s) {
      s.forEach((k, v) {
        if (!k.startsWith('mod_')) return;
        mods[k] = (mods[k] ?? 0) + v.round();
      });
    }

    addMods(a.stats);
    addMods(b.stats);
    mods.forEach((k, v) {
      base[k] = ((v * mul).round());
    });

    final titles = _dedupeTitles([...a.dnaJournalTitles, ...b.dnaJournalTitles],
        maxKeep: 50);
    final isAccessory = (def.equipSlot ?? '').isNotEmpty;
    final isWeapon = def.slot == SlotId.weapon;
    final name = (isWeapon || isAccessory)
        ? _nameFromFileAndTitles(element, titles, def: def)
        : _catalogName(playerClass, tier, element, titles, def: def);

    return CraftedItem(
      id: _uuid.v4(),
      def: def,
      tier: tier,
      rarity: rarity,
      element: element,
      displayName: name,
      dnaJournalTitles: titles,
      upgradeStepsInTier: 0,
      stats: base,
      classAffinity: def.classAffinity,
    );
  }

  ItemDef pickClassWeightedArmorDef(String playerClass) {
    final a = assets.armorDefs;
    // Bias towards player's classAffinity when possible (60% chance), else any
    final classPool = <ItemDef>[];
    final anyPool = <ItemDef>[];
    for (final list in a.values) {
      for (final d in list) {
        anyPool.add(d);
        if ((d.classAffinity ?? '').toLowerCase() ==
            playerClass.toLowerCase()) {
          classPool.add(d);
        }
      }
    }
    final rnd = DateTime.now().microsecondsSinceEpoch % 100;
    if (classPool.isNotEmpty && rnd < 60) {
      classPool.shuffle();
      return classPool.first;
    }
    anyPool.shuffle();
    return anyPool.isNotEmpty
        ? anyPool.first
        : const ItemDef(
            key: 'placeholder',
            iconPath: 'assets/images/ui/slots/chest_empty_32.png',
            slot: SlotId.chest);
  }

  ItemDef? pickClassChestFirstArmorDef(String playerClass) {
    final chestList = assets.armorDefs[SlotId.chest] ?? const <ItemDef>[];
    if (chestList.isEmpty) return null;
    // Prefer player's classAffinity
    final classChest = chestList
        .where((d) =>
            (d.classAffinity ?? '').toLowerCase() == playerClass.toLowerCase())
        .toList();
    if (classChest.isNotEmpty) {
      classChest.shuffle();
      return classChest.first;
    }
    // Else any chest
    final any = List<ItemDef>.from(chestList);
    any.shuffle();
    return any.isNotEmpty ? any.first : null;
  }

  ItemDef? pickClassSlotStageArmorDef(
      String playerClass, SlotId slot, String stage) {
    final list = (assets.armorDefs[slot] ?? const <ItemDef>[])
        .where((d) => d.iconPath.contains('/$stage/'))
        .toList();
    List<ItemDef> cls = list
        .where((d) =>
            (d.classAffinity ?? '').toLowerCase() == playerClass.toLowerCase())
        .toList();
    if (cls.isEmpty) {
      cls = list;
    }
    if (cls.isEmpty) return null;
    cls.shuffle();
    return cls.first;
  }

  String makeDisplayName(ElementType el, List<String> titles,
      {String? setHint, ItemDef? def}) {
    // If asset key encodes a base name (e.g., artificer_tinkers_rig_hands), use it
    String baseName = '';
    if (def != null && def.key.isNotEmpty) {
      final parts = def.key.split('_');
      // Remove class token (first) and slot token (last)
      if (parts.length >= 3) {
        final core = parts.sublist(1, parts.length - 1).join(' ');
        baseName = _capWords(_normalizeBaseName(core, def.classAffinity));
      }
    }
    final words = _twoWordsFromTitles(titles);
    final w1 = words.isNotEmpty ? words[0] : _adjFor(el);
    final w2 = words.length >= 2 ? words[1] : _epithetFor(el);
    final left = baseName.isNotEmpty ? baseName : _nounFor(el);
    final name = '$left of $w1 $w2';
    return setHint != null && setHint.isNotEmpty ? '$name ($setHint)' : name;
  }

  String _catalogName(
      String playerClass, int tier, ElementType el, List<String> titles,
      {ItemDef? def}) {
    final cat = GearCatalogService();
    final set = cat.setName(playerClass, tier);
    final connector = cat.connector(playerClass, tier);
    final words = _twoWordsFromTitles(titles);
    final w1 = words.isNotEmpty ? words[0] : _adjFor(el);
    final w2 = words.length >= 2 ? words[1] : _epithetFor(el);
    final base = (set != null && set.isNotEmpty)
        ? set
        : (def != null ? _baseNameFromDef(def, playerClass) : _nounFor(el));
    if (connector == 'possessive') {
      final apos = base.endsWith('s') ? "'" : "'s";
      return '$base$apos $w1 $w2';
    }
    return '$base of $w1 $w2';
  }

  String _baseNameFromDef(ItemDef def, String? classAffinity) {
    final parts = def.key.split('_');
    if (parts.length >= 3) {
      final core = parts.sublist(1, parts.length - 1).join(' ');
      return _capWords(_normalizeBaseName(core, classAffinity));
    }
    return _capWords(def.key);
  }

  String _normalizeBaseName(String s, String? classAffinity) {
    // Artificer set uses "Tinkers Rig" in file names; prefer display "Tinker Rig"
    var out = s;
    if ((classAffinity ?? '').toLowerCase() == 'artificer') {
      out = out.replaceAll(
          RegExp(r'\bTinkers\b', caseSensitive: false), 'Tinker');
    }
    return out;
  }

  // Cycle craft slots so we don’t always produce chest pieces.
  static const List<SlotId> _slotCycle = [
    SlotId.chest,
    SlotId.hands,
    SlotId.head,
    SlotId.legs,
    SlotId.feet,
  ];
  SlotId _nextCraftSlot() {
    try {
      final box = playerMetaBox();
      final cur = (box.get('craft_next_slot')?.toString() ?? 'chest');
      final idx = _slotCycle.indexWhere((s) => s.name == cur);
      final slot = idx >= 0 ? _slotCycle[idx] : SlotId.chest;
      // advance pointer
      final nextIdx = ((idx >= 0 ? idx : 0) + 1) % _slotCycle.length;
      box.put('craft_next_slot', _slotCycle[nextIdx].name);
      return slot;
    } catch (_) {
      return SlotId.chest;
    }
  }

  String _stageForTier(int tier) {
    if (tier <= 4) return 'early';
    if (tier <= 9) return 'mid';
    return 'late';
  }

  List<String> _twoWordsFromTitles(List<String> titles) {
    final txt = titles.join(' ').toLowerCase();
    final toks = txt
        .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ')
        .split(RegExp(r"\s+"))
        .where((t) => t.length >= 4 && !_stop.contains(t))
        .toList();
    final out = <String>[];
    for (final t in toks) {
      if (!out.contains(t)) out.add(t);
      if (out.length >= 2) break;
    }
    return out.map(_cap).toList();
  }

  static const Set<String> _stop = {
    'the',
    'and',
    'with',
    'from',
    'into',
    'over',
    'under',
    'this',
    'that',
    'your',
    'their',
    'ours',
    'mine',
    'ourselves',
    'yourselves',
    'about',
    'after',
    'again',
    'once',
    'very',
    'more',
    'most',
    'some',
    'such',
    'own',
    'same',
    'just',
    'like',
    'have',
    'has',
    'had',
    'will',
    'would',
    'could',
    'should',
    'can',
    'shall',
    'than',
    'then',
    'there',
    'here',
    'when',
    'what',
    'where',
    'which',
    'while',
    'who',
    'whom',
    'whose',
    'why',
    'how',
    'onto',
    'unto',
    'amid',
    'amidst',
    'among',
    'amongst',
    'between',
    'within',
    'without',
    'around'
  };

  Map<String, num> computeStats(SlotId slot, int tier, Rarity rarity,
      {required bool classBonus, String? playerClass, String? classAffinity}) {
    double baseAtk = 0, baseDef = 0;
    if (slot == SlotId.weapon) {
      baseAtk = 10;
    } else {
      baseDef = 6;
      // distribute: chest+2 others +1 baseline already small in this stub; keep simple: chest gets +2
      if (slot == SlotId.chest) baseDef += 2;
    }
    final tierMul = 1 + 0.12 * (tier - 1);
    const rarMul = {
      Rarity.common: 1.00,
      Rarity.uncommon: 1.05,
      Rarity.rare: 1.12,
      Rarity.epic: 1.20,
      Rarity.legendary: 1.30,
    };
    final rm = rarMul[rarity] ?? 1.0;
    var atk = baseAtk * tierMul * rm;
    var def = baseDef * tierMul * rm;
    final matches = classBonus ||
        (classAffinity != null &&
            playerClass != null &&
            classAffinity == playerClass);
    if (matches) {
      if (slot == SlotId.weapon) {
        atk *= 1.10;
      } else {
        def *= 1.10;
      }
    }
    return {
      if (atk > 0) 'atk': atk.round(),
      if (def > 0) 'def': def.round(),
    };
  }

  Map<String, num> _buildStats({
    required SlotId slot,
    required int tier,
    required Rarity rarity,
    required bool classBonus,
    String? playerClass,
    String? classAffinity,
    required ElementType element,
  }) {
    final out = <String, num>{};

    if (slot == SlotId.weapon) {
      // Base ATK similar to previous computeStats weapon scaling
      double baseAtk = 10;
      final tierMul = 1 + 0.12 * (tier - 1);
      const rarMul = {
        Rarity.common: 1.00,
        Rarity.uncommon: 1.05,
        Rarity.rare: 1.12,
        Rarity.epic: 1.20,
        Rarity.legendary: 1.30,
      };
      final rm = rarMul[rarity] ?? 1.0;
      var atk = baseAtk * tierMul * rm;
      final matches = classBonus ||
          (classAffinity != null &&
              playerClass != null &&
              classAffinity == playerClass);
      if (matches) atk *= 1.10;
      out['atk'] = atk.round();
    } else {
      // Armor: base DEF roll from rules per tier/slot
      var def = CraftingRulesService().rollBaseDef(tier: tier, slot: slot);
      final matches = classBonus ||
          (classAffinity != null &&
              playerClass != null &&
              classAffinity == playerClass);
      if (matches) def = (def * 1.10).round();
      out['def'] = def;
    }

    // Elemental enchantments (applies to both armor and weapons, rules-driven)
    final mods = CraftingRulesService().rollEnchantments(
      isWeapon: slot == SlotId.weapon,
      tier: tier,
      rarity: rarity,
      element: element,
    );
    out.addAll(mods);

    return out;
  }

  List<String> _dedupeTitles(List<String> t, {required int maxKeep}) {
    final seen = <String>{};
    final out = <String>[];
    for (final s in t) {
      if (s.isEmpty) continue;
      if (seen.add(s)) out.add(s);
    }
    if (out.length > maxKeep) return out.sublist(0, maxKeep);
    return out;
  }

  // removed _salientWord (replaced by _twoWordsFromTitles)
  String _cap(String s) =>
      s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));
  String _capWords(String s) => s.split(' ').map(_cap).join(' ');

  String _adjFor(ElementType e) {
    switch (e) {
      case ElementType.fire:
        return 'Searing';
      case ElementType.water:
        return 'Tidal';
      case ElementType.air:
        return 'Gale';
      case ElementType.nature:
        return 'Verdant';
      case ElementType.metal:
        return 'Tempered';
      case ElementType.light:
        return 'Radiant';
      case ElementType.shadow:
        return 'Umbral';
    }
  }

  String _nounFor(ElementType e) {
    switch (e) {
      case ElementType.fire:
        return 'Ember';
      case ElementType.water:
        return 'Brine';
      case ElementType.air:
        return 'Zephyr';
      case ElementType.nature:
        return 'Briar';
      case ElementType.metal:
        return 'Aegis';
      case ElementType.light:
        return 'Dawn';
      case ElementType.shadow:
        return 'Gloom';
    }
  }

  String _epithetFor(ElementType e) {
    switch (e) {
      case ElementType.fire:
        return 'Fury';
      case ElementType.water:
        return 'Tide';
      case ElementType.air:
        return 'Grace';
      case ElementType.nature:
        return 'Bloom';
      case ElementType.metal:
        return 'Aegis';
      case ElementType.light:
        return 'Dawn';
      case ElementType.shadow:
        return 'Gloom';
    }
  }
}
