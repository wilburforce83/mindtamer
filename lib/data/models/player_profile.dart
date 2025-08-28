import 'package:hive/hive.dart';
part 'player_profile.manual.dart';

@HiveType(typeId: 7)
class PlayerProfile {
  @HiveField(0) String id;
  @HiveField(1) String classKey;
  @HiveField(2) int level;
  @HiveField(3) int xp;
  @HiveField(4) List<String> unlockedSkills;
  @HiveField(5) List<String> cosmetics;
  @HiveField(6) List<String> titles;
  PlayerProfile({required this.id, required this.classKey, this.level=1, this.xp=0, List<String>? unlockedSkills, List<String>? cosmetics, List<String>? titles})
    : unlockedSkills = unlockedSkills ?? [], cosmetics = cosmetics ?? [], titles = titles ?? [];
}
