import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

class AssetIndexService {
  static final AssetIndexService _instance = AssetIndexService._();
  factory AssetIndexService() => _instance;
  AssetIndexService._();

  List<ItemDef> weaponDefs = const [];
  Map<SlotId, List<ItemDef>> armorDefs = { for (var s in SlotId.values) s: const <ItemDef>[] };
  Map<String, List<ItemDef>> accessoryDefs = const {'neck': [], 'ring': []};
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      final jsonStr = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(jsonStr);
      final weapons = <ItemDef>[];
      final armor = { for (var s in SlotId.values) s: <ItemDef>[] };
      final accessories = {'neck': <ItemDef>[], 'ring': <ItemDef>[]};
      for (final path in manifest.keys) {
        if (!path.startsWith('assets/images/')) continue;
        if (!path.endsWith('_32.png')) continue;
        if (path.startsWith('assets/images/weapons/')) {
          final parts = path.split('/');
          final classAffinity = parts.length >= 4 ? parts[3] : null; // weapons/<class>/<file>
          final key = parts.last.replaceAll('_32.png','');
          weapons.add(ItemDef(key: key, iconPath: path, slot: SlotId.weapon, classAffinity: classAffinity));
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
            case 'head': slot = SlotId.head; break;
            case 'chest': slot = SlotId.chest; break;
            case 'hands': slot = SlotId.hands; break;
            case 'legs': slot = SlotId.legs; break;
            case 'feet': slot = SlotId.feet; break;
            default: slot = SlotId.chest; break;
          }
          final key = base; // keep full key for naming
          final classAffinity = parts.length >= 4 ? parts[3] : null; // armor/<class>/...
          armor[slot]!.add(ItemDef(key: key, iconPath: path, slot: slot, classAffinity: classAffinity));
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
            final def = ItemDef(key: key, iconPath: path, slot: slot, classAffinity: null, equipSlot: equip);
            accessories[equip]!.add(def);
          }
        }
      }
      weaponDefs = weapons;
      armorDefs = armor;
      accessoryDefs = accessories;
    } catch (_) {
      weaponDefs = const [];
      armorDefs = { for (var s in SlotId.values) s: const <ItemDef>[] };
      accessoryDefs = const {'neck': [], 'ring': []};
    }
  }
}
