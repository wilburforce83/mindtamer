import 'package:hive/hive.dart';
part 'med_plan.manual.dart';

@HiveType(typeId: 4)
class MedPlan {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String dose;
  @HiveField(3) List<String> scheduleTimes;
  @HiveField(4) bool active;
  // Optional sprite path for the med icon. If null, use code-only icon.
  @HiveField(5) String? iconPath;
  // How many units are consumed per intake (e.g., 1 pill).
  @HiveField(6) int unitsPerDose = 1;
  // Stock tracking
  @HiveField(7) int startingStock = 0;
  @HiveField(8) int remainingStock = 0;
  MedPlan({required this.id, required this.name, required this.dose, required this.scheduleTimes, required this.active});
}
