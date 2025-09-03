import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/med_plan.dart';
import '../../data/repositories/medication_repository.dart';
import '../providers.dart';
import 'med_service.dart';
import '../../core/notifications.dart';
import '../../data/models/med_log.dart';
import '../../data/models/settings.dart';
import '../../data/hive/boxes.dart';
final medPlansProvider = StateNotifierProvider<MedPlansNotifier, List<MedPlan>>(
  (ref) => MedPlansNotifier(ref.read(medRepoProvider), ref),
);
final medLogsTickProvider = StateProvider<int>((ref) => 0);
final medLogsProvider = Provider<List<MedLog>>((ref) {
  ref.watch(medLogsTickProvider);
  return ref.read(medRepoProvider).logs();
});
final medSettingsProvider = Provider<Settings>((ref)=> settingsBox().values.isNotEmpty ? settingsBox().values.first : Settings(id: 'default'));
final medServiceProvider = Provider((ref)=> const MedService());

final nextMedInfoProvider = Provider<({DateTime? time, List<MedPlan> meds})>((ref){
  final svc = ref.watch(medServiceProvider);
  final plans = ref.watch(medPlansProvider);
  final (t, meds) = svc.nextAcross(plans, DateTime.now());
  return (time: t, meds: meds);
});

final onTimeRateProvider = Provider<double>((ref){
  final svc = ref.watch(medServiceProvider);
  final logs = ref.watch(medLogsProvider);
  final settings = ref.watch(medSettingsProvider);
  return svc.onTimeRate(logs, settings);
});

final daysLeftPerPlanProvider = Provider<Map<String,int>>((ref){
  final svc = ref.watch(medServiceProvider);
  final plans = ref.watch(medPlansProvider);
  return svc.estimateDaysLeft(plans);
});
final streakProvider = Provider<int>((ref){
  final svc = ref.watch(medServiceProvider);
  final plans = ref.watch(medPlansProvider);
  final logs = ref.watch(medLogsProvider);
  final settings = ref.watch(medSettingsProvider);
  return svc.adherenceStreakDays(plans, logs, settings);
});
class MedPlansNotifier extends StateNotifier<List<MedPlan>> {
  final IMedicationRepository _repo;
  final Ref _ref;
  MedPlansNotifier(this._repo, this._ref) : super(_repo.plans());
  Future<MedPlan> addPlan(String name, String dose, List<String> times, {bool schedule = true}) async {
    final p = await _repo.addPlan(name, dose, times);
    if (schedule) {
      try { await _reschedule(); } catch (_) {}
      await _checkRefillAlerts();
    }
    state = _repo.plans();
    _ref.read(medLogsTickProvider.notifier).state++;
    return p;
  }
  Future<void> editPlan(MedPlan plan) async {
    await _repo.updatePlan(plan);
    try { await _reschedule(); } catch (_) {}
    await _checkRefillAlerts();
    state = _repo.plans();
    _ref.read(medLogsTickProvider.notifier).state++;
  }
  Future<void> delete(String planId) async {
    await _repo.deletePlan(planId);
    try { await _reschedule(); } catch (_) {}
    state = _repo.plans();
    _ref.read(medLogsTickProvider.notifier).state++;
  }
  Future<void> setIcon(String planId, String? iconPath) async {
    await _repo.setPlanIcon(planId, iconPath);
    state = _repo.plans();
  }
  Future<void> setStock(String planId, {int? starting, int? remaining}) async {
    await _repo.setPlanStock(planId, starting: starting, remaining: remaining);
    await _checkRefillAlerts();
    state = _repo.plans();
    _ref.read(medLogsTickProvider.notifier).state++;
  }
  Future<void> log(String planId, DateTime date, String time, bool taken, {DateTime? loggedAt}) async {
    await _repo.logIntake(planId, date, time, taken, loggedAt: loggedAt);
    await _checkRefillAlerts();
    state = _repo.plans();
    _ref.read(medLogsTickProvider.notifier).state++;
  }
  Future<void> _reschedule() async {
    final plans = _repo.plans().where((p)=>p.active).toList();
    final map = <String, List<String>>{}; // time -> med names
    for (final p in plans) {
      for (final t in p.scheduleTimes) {
        map.putIfAbsent(t, ()=>[]).add(p.name);
      }
    }
    await NotificationService.scheduleDailyConsolidatedReminders(map);
  }

  Future<void> _checkRefillAlerts() async {
    try {
      final plans = _repo.plans();
      final settings = settingsBox().values.isNotEmpty ? settingsBox().values.first : Settings(id: 'default');
      for (final p in plans) {
        final dosesPerDay = p.scheduleTimes.length;
        final upd = (p.unitsPerDose == 0 ? 1 : p.unitsPerDose);
        final unitsPerDay = (dosesPerDay * upd);
        if (unitsPerDay == 0) continue;
        final daysLeft = (p.remainingStock / unitsPerDay).floor();
        if (daysLeft <= settings.refillThresholdDays) {
          final id = 30000 + (p.id.hashCode & 0x7FFFFFFF);
          try {
            await NotificationService.showNow(id, 'Refill soon', '${p.name} ~$daysLeft days left');
          } catch (_) {
            // Ignore transient notification failures
          }
        }
      }
    } catch (_) {
      // Swallow errors to avoid blocking UI flows like dialog closing
    }
  }
}
