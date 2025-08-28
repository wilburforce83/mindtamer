import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../hive/boxes.dart';
import '../models/med_plan.dart';
import '../models/med_log.dart';
abstract class IMedicationRepository {
  Future<MedPlan> addPlan(String name, String dose, List<String> times);
  List<MedPlan> plans();
  Future<void> logIntake(String planId, DateTime date, String time, bool taken);
  List<MedLog> logs();
}
class MedicationRepository implements IMedicationRepository {
  final _uuid = const Uuid();
  final Box<MedPlan> _plans = medPlanBox();
  final Box<MedLog> _logs = medLogBox();
  @override Future<MedPlan> addPlan(String name, String dose, List<String> times) async {
    final p = MedPlan(id: _uuid.v4(), name: name, dose: dose, scheduleTimes: times, active: true);
    await _plans.put(p.id, p); return p;
  }
  @override List<MedPlan> plans() => _plans.values.toList();
  @override Future<void> logIntake(String planId, DateTime date, String time, bool taken) async {
    final l = MedLog(id: _uuid.v4(), date: date, planId: planId, taken: taken, time: time); await _logs.put(l.id, l);
  }
  @override List<MedLog> logs() => _logs.values.toList();
}
