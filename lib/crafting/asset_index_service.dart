import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'models.dart';

class AssetIndexService {
  static final AssetIndexService _instance = AssetIndexService._();
  factory AssetIndexService() => _instance;
  AssetIndexService._();

  List<ItemDef> weaponDefs = const [];
  Map<SlotId, List<ItemDef>> armorDefs = {
    for (var s in SlotId.values) s: const <ItemDef>[]
  };
  Map<String, List<ItemDef>> accessoryDefs = const {'neck': [], 'ring': []};
  bool _inited = false;

  Future<void> init() async {
    // If already initialized with non-empty pools, skip. Otherwise retry.
    if (_inited &&
        (weaponDefs.isNotEmpty ||
            accessoryDefs.values.any((l) => l.isNotEmpty) ||
            armorDefs.values.any((l) => l.isNotEmpty))) {
      return;
    }
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final weapons = <ItemDef>[];
      final armor = {for (var s in SlotId.values) s: <ItemDef>[]};
      final accessories = {'neck': <ItemDef>[], 'ring': <ItemDef>[]};
      for (final path in manifest.listAssets()) {
        if (!path.startsWith('assets/images/')) continue;
        if (!path.endsWith('_32.png')) continue;
        if (path.startsWith('assets/images/weapons/')) {
          final parts = path.split('/');
          final classAffinity =
              parts.length >= 4 ? parts[3] : null; // weapons/<class>/<file>
          final key = parts.last.replaceAll('_32.png', '');
          weapons.add(ItemDef(
              key: key,
              iconPath: path,
              slot: SlotId.weapon,
              classAffinity: classAffinity));
        } else if (path.startsWith('assets/images/armor/')) {
          // Support class-based folder structures, slot is encoded in filename suffix
          // e.g., assets/images/armor/artificer/early/artificer_tinkers_rig_hands_32.png
          final parts = path.split('/');
          final file = parts.last;
          final base = file.replaceAll('_32.png', '');
          // slot is the last token before _32
          final tokens = base.split('_');
          final last = tokens.isNotEmpty ? tokens.last : '';
          SlotId slot;
          switch (last) {
            case 'head':
              slot = SlotId.head;
              break;
            case 'chest':
              slot = SlotId.chest;
              break;
            case 'hands':
              slot = SlotId.hands;
              break;
            case 'legs':
              slot = SlotId.legs;
              break;
            case 'feet':
              slot = SlotId.feet;
              break;
            default:
              slot = SlotId.chest;
              break;
          }
          final key = base; // keep full key for naming
          final classAffinity =
              parts.length >= 4 ? parts[3] : null; // armor/<class>/...
          armor[slot]!.add(ItemDef(
              key: key,
              iconPath: path,
              slot: slot,
              classAffinity: classAffinity));
        } else if (path.startsWith('assets/images/accessories/')) {
          // accessories/necklaces/*.png or accessories/rings/*.png
          final parts = path.split('/');
          final typeDir = parts.length >= 4 ? parts[3] : '';
          final key = parts.last.replaceAll('_32.png', '');
          String? equip;
          if (typeDir == 'necklaces') equip = 'neck';
          if (typeDir == 'rings') equip = 'ring';
          if (equip != null) {
            // Use a neutral SlotId for weighting; hands for rings, head for neck
            final slot = (equip == 'ring') ? SlotId.hands : SlotId.head;
            final def = ItemDef(
                key: key,
                iconPath: path,
                slot: slot,
                classAffinity: null,
                equipSlot: equip);
            accessories[equip]!.add(def);
          }
        }
      }
      // Fallbacks if manifest parsing yields empty pools (e.g., during hot restart hiccups)
      if (weapons.isEmpty) {
        const classes = [
          'alchemist',
          'artificer',
          'empath',
          'oracle',
          'sage',
          'seer',
          'sentinel',
          'shadow',
          'trickster',
          'warden'
        ];
        const sampleByClass = {
          'alchemist': ['alchemic_blade_32.png', 'retort_staff_32.png'],
          'artificer': ['gear_mace_32.png', 'aether_rifle_32.png'],
          'empath': ['prayer_staff_32.png', 'rosary_flail_32.png'],
          'oracle': ['verdict_scepter_32.png', 'edict_tome_32.png'],
          'sage': ['sagewood_staff_32.png', 'crystal_wand_32.png'],
          'seer': ['diviner_s_rod_32.png', 'hex_tome_32.png'],
          'sentinel': ['bastion_gladius_32.png', 'flail_star_32.png'],
          'shadow': ['night_katars_32.png', 'crescent_scythe_32.png'],
          'trickster': ['flicker_dagger_32.png', 'twin_sai_32.png'],
          'warden': ['bulwark_longsword_32.png', 'tower_shield_32.png'],
        };
        for (final cls in classes) {
          final list = (sampleByClass[cls] ?? const <String>[]);
          for (final file in list) {
            final path = 'assets/images/weapons/$cls/$file';
            final key = file.replaceAll('_32.png', '');
            weapons.add(ItemDef(
                key: key,
                iconPath: path,
                slot: SlotId.weapon,
                classAffinity: cls));
          }
        }
      }

      if ((accessories['ring']?.isEmpty ?? true)) {
        const ringFiles = [
          'iron_band_32.png',
          'silver_leaf_32.png',
          'gear_ring_32.png',
          'ruby_heart_32.png'
        ];
        for (final file in ringFiles) {
          final path = 'assets/images/accessories/rings/$file';
          final key = file.replaceAll('_32.png', '');
          final def = ItemDef(
              key: key,
              iconPath: path,
              slot: SlotId.hands,
              classAffinity: null,
              equipSlot: 'ring');
          (accessories['ring'] ??= <ItemDef>[]).add(def);
        }
      }
      if ((accessories['neck']?.isEmpty ?? true)) {
        const neckFiles = [
          'gear_locket_32.png',
          'anchor_chain_32.png',
          'star_prism_32.png',
          'sunburst_medallion_32.png'
        ];
        for (final file in neckFiles) {
          final path = 'assets/images/accessories/necklaces/$file';
          final key = file.replaceAll('_32.png', '');
          final def = ItemDef(
              key: key,
              iconPath: path,
              slot: SlotId.head,
              classAffinity: null,
              equipSlot: 'neck');
          (accessories['neck'] ??= <ItemDef>[]).add(def);
        }
      }

      weaponDefs = weapons;
      armorDefs = armor;
      accessoryDefs = accessories;
      _inited = true;
    } catch (_) {
      weaponDefs = const [];
      armorDefs = {for (var s in SlotId.values) s: const <ItemDef>[]};
      accessoryDefs = const {'neck': [], 'ring': []};
      _inited = false; // allow retry on next call
    }
  }
}
