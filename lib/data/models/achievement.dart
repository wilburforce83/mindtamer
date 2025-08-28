import 'package:hive/hive.dart';
part 'achievement.manual.dart';

@HiveType(typeId: 6)
class Achievement {
  @HiveField(0) String id;
  @HiveField(1) String key;
  @HiveField(2) DateTime earnedAt;
  Achievement({required this.id, required this.key, required this.earnedAt});
}
