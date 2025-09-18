import 'package:hive/hive.dart';
import '../data/hive/boxes.dart';
import 'models.dart';

class CraftedInventoryService {
  static const _boxKey = 'crafted_items';
  static Box _box() => Hive.box(BoxNames.equipment); // reuse equipment box for now

  static List<CraftedItem> all() {
    try {
      final list = (_box().get(_boxKey) as List?)?.cast<Map>() ?? const <Map>[];
      return list.map((m) => _fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) { return const <CraftedItem>[]; }
  }

  static List<CraftedItem> bySlot(SlotId slot) => all().where((e) => e.def.slot == slot).toList();

  static void upsert(CraftedItem item) {
    final list = all();
    final idx = list.indexWhere((e) => e.id == item.id);
    if (idx >= 0) { list[idx] = item; } else { list.add(item); }
    _box().put(_boxKey, list.map(_toMap).toList());
  }

  static CraftedItem? getById(String id) {
    for (final e in all()) {
      if (e.id == id) return e;
    }
    return null;
  }

  static Map<String, dynamic> _toMap(CraftedItem i) => {
    'id': i.id,
    'def': {
      'key': i.def.key,
      'icon': i.def.iconPath,
      'slot': i.def.slot.name,
      'aff': i.def.classAffinity,
      'equip': i.def.equipSlot,
    },
    'tier': i.tier,
    'rarity': i.rarity.name,
    'element': i.element.name,
    'name': i.displayName,
    'dna': i.dnaJournalTitles,
    'steps': i.upgradeStepsInTier,
    'stats': i.stats,
  };
  static CraftedItem _fromMap(Map<String, dynamic> m) {
    final slot = SlotId.values.firstWhere((s) => s.name == (m['def']?['slot'] ?? 'weapon'));
    var icon = (m['def']?['icon'] ?? '').toString();
    // Migrate old placeholder path to a bundled empty slot asset to avoid missing-asset crashes
    if (icon == 'assets/images/armor/chest/placeholder_32.png') {
      icon = 'assets/images/ui/slots/chest_empty_32.png';
    }
    var key = (m['def']?['key'] ?? 'item').toString();
    var aff = m['def']?['aff']?.toString();
    // If we still have a placeholder-like def for a chest item, replace with class chest art
    if ((key == 'placeholder' || icon.endsWith('/ui/slots/chest_empty_32.png')) && slot == SlotId.chest) {
      final cls = _playerClass();
      final base = _classBaseChest(cls);
      if (base != null) {
        icon = 'assets/images/armor/$cls/early/${base}_chest_32.png';
        key = '${base}_chest';
        aff = cls;
      }
    }
    final def = ItemDef(key: key, iconPath: icon, slot: slot, classAffinity: aff, equipSlot: m['def']?['equip']?.toString());
    final rarity = Rarity.values.firstWhere((r) => r.name == (m['rarity'] ?? 'common'));
    final element = ElementType.values.firstWhere((e) => e.name == (m['element'] ?? 'neutral'), orElse: () => ElementType.shadow);
    return CraftedItem(
      id: (m['id'] ?? '').toString(),
      def: def,
      tier: (m['tier'] ?? 1) as int,
      rarity: rarity,
      element: element,
      displayName: (m['name'] ?? '').toString(),
      dnaJournalTitles: (m['dna'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
      upgradeStepsInTier: (m['steps'] ?? 0) as int,
      stats: Map<String, num>.from(m['stats'] ?? const <String, num>{}),
      classAffinity: m['def']?['aff']?.toString(),
    );
  }

  static String _playerClass() {
    try {
      final v = profileBox().values;
      if (v.isNotEmpty) return v.first.classKey.toLowerCase();
    } catch (_) {}
    return 'sage';
  }

  static String? _classBaseChest(String cls) {
    switch (cls.toLowerCase()) {
      case 'alchemist': return 'alchemist_workbench';
      case 'artificer': return 'artificer_tinkers_rig';
      case 'empath': return 'empath_healers_habit';
      case 'oracle': return 'oracle_edict';
      case 'sage': return 'sage_arcanist_weave';
      case 'seer': return 'seer_veilseer';
      case 'sentinel': return 'sentinel_wallguard';
      case 'shadow': return 'shadow_duskstalk';
      case 'trickster': return 'trickster_streetshade';
      case 'warden': return 'warden_bulwark';
    }
    return null;
  }
  static void remove(String id) {
    final list = all();
    list.removeWhere((e) => e.id == id);
    _box().put(_boxKey, list.map(_toMap).toList());
  }
}
