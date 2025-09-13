import '../../data/hive/boxes.dart';

abstract class SpriteSlotsRepo {
  Future<Map<String, String?>> getAll();
  Future<void> set(String slot, String? instanceId);
}

class SpriteSlotsRepoImpl implements SpriteSlotsRepo {
  static const _key = 'sprite_slots';
  static const _slots = ['sprite1', 'sprite2'];

  @override
  Future<Map<String, String?>> getAll() async {
    try {
      final box = equipmentBox();
      final raw = (box.get(_key) as Map?)?.map((k, v) => MapEntry(k.toString(), v?.toString())) ?? <String, String?>{};
      return { for (final s in _slots) s: raw[s] };
    } catch (_) {
      return { for (final s in _slots) s: null };
    }
  }

  @override
  Future<void> set(String slot, String? instanceId) async {
    try {
      final box = equipmentBox();
      final raw = (box.get(_key) as Map?)?.map((k, v) => MapEntry(k.toString(), v?.toString())) ?? <String, String?>{};
      // Prevent equipping the same sprite in both slots: remove from the other slot first
      if (instanceId != null && instanceId.isNotEmpty) {
        for (final s in _slots) {
          if (s != slot && raw[s] == instanceId) {
            raw.remove(s);
          }
        }
        raw[slot] = instanceId;
      } else {
        raw.remove(slot);
      }
      await box.put(_key, raw);
    } catch (_) {
      // ignore in environments where Hive box isn't open (tests)
    }
  }
}
