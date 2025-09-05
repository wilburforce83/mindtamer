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
      final raw = (box.get(_key) as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? <String, dynamic>{};
      if (instanceId == null || instanceId.isEmpty) {
        raw.remove(slot);
      } else {
        raw[slot] = instanceId;
      }
      await box.put(_key, raw);
    } catch (_) {
      // ignore in environments where Hive box isn't open (tests)
    }
  }
}

