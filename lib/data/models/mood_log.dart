import 'package:hive/hive.dart';
part 'mood_log.manual.dart';

@HiveType(typeId: 3)
class MoodLog {
  @HiveField(0) String id;
  @HiveField(1) DateTime date;
  @HiveField(2) int battery;
  @HiveField(3) int stress;
  @HiveField(4) int focus;
  @HiveField(5) int mood;
  @HiveField(6) int sleep;
  @HiveField(7) int social;
  @HiveField(8) int? custom1;
  @HiveField(9) int? custom2;
  @HiveField(10) bool locked;
  MoodLog({required this.id, required this.date, required this.battery, required this.stress, required this.focus, required this.mood, required this.sleep, required this.social, this.custom1, this.custom2, this.locked=false});
}
