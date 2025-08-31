import 'package:hive/hive.dart';
part 'med_log.manual.dart';

@HiveType(typeId: 5)
class MedLog {
  @HiveField(0) String id;
  @HiveField(1) DateTime date;
  @HiveField(2) String planId;
  @HiveField(3) bool taken;
  @HiveField(4) String time;
  // Timestamp when the dose was logged as taken (or skipped); defaults to [date] at [time] if unavailable.
  @HiveField(5) DateTime? loggedAt;
  MedLog({required this.id, required this.date, required this.planId, required this.taken, required this.time, this.loggedAt});
}
