import '../hive/boxes.dart';
import '../models/player_profile.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
abstract class IProfileRepository {
  PlayerProfile? getActive();
  Future<PlayerProfile> create(String classKey);
  Future<void> save(PlayerProfile profile);
}
class ProfileRepository implements IProfileRepository {
  final Box<PlayerProfile> _box = profileBox();
  final _uuid = const Uuid();
  @override PlayerProfile? getActive() => _box.values.isEmpty ? null : _box.values.first;
  @override Future<PlayerProfile> create(String classKey) async { final p = PlayerProfile(id: _uuid.v4(), classKey: classKey); await _box.put(p.id, p); return p; }
  @override Future<void> save(PlayerProfile profile) async { await _box.put(profile.id, profile); }
}
