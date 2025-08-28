import 'package:hive/hive.dart';
part 'med_plan.manual.dart';

@HiveType(typeId: 4)
class MedPlan {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String dose;
  @HiveField(3) List<String> scheduleTimes;
  @HiveField(4) bool active;
  MedPlan({required this.id, required this.name, required this.dose, required this.scheduleTimes, required this.active});
}
