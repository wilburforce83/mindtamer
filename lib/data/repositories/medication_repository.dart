import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../hive/boxes.dart';
import '../models/med_plan.dart';
import '../models/med_log.dart';
abstract class IMedicationRepository {
  Future<MedPlan> addPlan(String name, String dose, List<String> times);
  List<MedPlan> plans();
  Future<void> logIntake(String planId, DateTime date, String time, bool taken, {DateTime? loggedAt});
  List<MedLog> logs();
  Future<void> updatePlan(MedPlan plan);
  Future<void> setPlanIcon(String planId, String? iconPath);
  Future<void> setPlanStock(String planId, {int? starting, int? remaining});
  Future<void> deletePlan(String planId);
}
class MedicationRepository implements IMedicationRepository {
  final _uuid = const Uuid();
  final Box<MedPlan> _plans = medPlanBox();
  final Box<MedLog> _logs = medLogBox();
  @override Future<MedPlan> addPlan(String name, String dose, List<String> times) async {
    final p = MedPlan(
      id: _uuid.v4(),
      name: name,
      dose: dose,
      scheduleTimes: times,
      active: true,
    )
      ..iconPath = null
      ..unitsPerDose = 1
      ..startingStock = 0
      ..remainingStock = 0;
    await _plans.put(p.id, p); return p;
  }
  @override List<MedPlan> plans() => _plans.values.toList();
  @override Future<void> logIntake(String planId, DateTime date, String time, bool taken, {DateTime? loggedAt}) async {
    final l = MedLog(id: _uuid.v4(), date: date, planId: planId, taken: taken, time: time, loggedAt: loggedAt ?? DateTime.now());
    await _logs.put(l.id, l);
    if (taken) {
      final p = _plans.get(planId);
      if (p != null) {
        p.remainingStock = (p.remainingStock - p.unitsPerDose).clamp(0, 2147483647);
        await _plans.put(planId, p);
      }
    }
  }
  @override List<MedLog> logs() => _logs.values.toList();
  @override Future<void> updatePlan(MedPlan plan) async { await _plans.put(plan.id, plan); }
  @override Future<void> setPlanIcon(String planId, String? iconPath) async {
    final p = _plans.get(planId); if (p!=null){ p.iconPath = iconPath; await _plans.put(planId, p); }
  }
  @override Future<void> setPlanStock(String planId, {int? starting, int? remaining}) async {
    final p = _plans.get(planId); if (p!=null){ if(starting!=null) p.startingStock=starting; if(remaining!=null) p.remainingStock=remaining; await _plans.put(planId, p); }
  }
  @override Future<void> deletePlan(String planId) async {
    // Remove plan and related logs
    await _plans.delete(planId);
    final toDelete = _logs.values.where((l)=> l.planId == planId).map((l)=> l.id).toList();
    await _logs.deleteAll(toDelete);
  }
}
