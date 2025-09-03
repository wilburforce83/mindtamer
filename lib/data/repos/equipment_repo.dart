import '../../data/hive/boxes.dart';

class EquippedItem {
  final String id;
  final String name;
  final String rarity; // common|uncommon|rare|epic
  final String? element;
  EquippedItem({required this.id, required this.name, required this.rarity, this.element});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'rarity': rarity,
        'element': element,
      };
  static EquippedItem fromMap(Map m) => EquippedItem(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        rarity: (m['rarity'] ?? 'common').toString(),
        element: m['element']?.toString(),
      );
}

abstract class EquipmentRepo {
  Future<Map<String, EquippedItem?>> getAllSlots();
  Future<void> setItem(String slot, EquippedItem? item);
}

class EquipmentRepoImpl implements EquipmentRepo {
  static const _boxKey = 'slots';
  static const _allSlots = [
    'head','chest','hands','legs','feet','neck','ringLeft','ringRight','weapon'
  ];

  @override
  Future<Map<String, EquippedItem?>> getAllSlots() async {
    try {
      final box = equipmentBox();
      final raw = box.get(_boxKey) as Map? ?? {};
      final out = <String, EquippedItem?>{};
      for (final s in _allSlots) {
        final v = raw[s];
        if (v is Map) {
          out[s] = EquippedItem.fromMap(Map<String, dynamic>.from(v));
        } else {
          out[s] = null;
        }
      }
      return out;
    } catch (_) {
      return { for (final s in _allSlots) s: null };
    }
  }

  @override
  Future<void> setItem(String slot, EquippedItem? item) async {
    try {
      final box = equipmentBox();
      final raw = (box.get(_boxKey) as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? <String, dynamic>{};
      if (item == null) {
        raw.remove(slot);
      } else {
        raw[slot] = item.toMap();
      }
      await box.put(_boxKey, raw);
    } catch (_) {
      // ignore in environments where Hive box isn't open (tests)
    }
  }
}
