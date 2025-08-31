import 'package:flutter/material.dart';
import '../../data/models/med_plan.dart';
import '../../data/models/med_log.dart';
import '../../data/models/settings.dart';

class MedStats {
  final DateTime? nextTime;
  final List<MedPlan> nextMeds;
  final double onTimeRate; // 0..1
  final Map<String, int> daysLeftPerPlan;
  const MedStats({this.nextTime, this.nextMeds = const [], this.onTimeRate = 0, this.daysLeftPerPlan = const {}});
}

class MedService {
  const MedService();

  // Parse "HH:mm" to a TimeOfDay
  TimeOfDay parseTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  DateTime nextOccurrence(TimeOfDay t, DateTime now) {
    final dtToday = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return dtToday.isAfter(now) ? dtToday : dtToday.add(const Duration(days: 1));
  }

  /// Returns next time across plans and the plans due at that time.
  (DateTime?, List<MedPlan>) nextAcross(List<MedPlan> plans, DateTime now) {
    DateTime? minTime;
    for (final p in plans.where((p) => p.active)) {
      for (final s in p.scheduleTimes) {
        final n = nextOccurrence(parseTime(s), now);
        if (minTime == null || n.isBefore(minTime)) minTime = n;
      }
    }
    if (minTime == null) return (null, const []);
    final due = plans.where((p) => p.active && p.scheduleTimes.any((s) => nextOccurrence(parseTime(s), now) == minTime)).toList();
    return (minTime, due);
  }

  /// On-time rate over last [days] days.
  double onTimeRate(List<MedLog> logs, Settings settings, {int days = 30}) {
    if (logs.isEmpty) return 0;
    const maxWindow = 120; // 2h absolute cap for counting on-time
    final since = DateTime.now().subtract(Duration(days: days));
    final recent = logs.where((l) => l.date.isAfter(since)).toList();
    if (recent.isEmpty) return 0;
    int onTime = 0;
    for (final l in recent) {
      if (!l.taken) continue;
      final tod = parseTime(l.time);
      final sched = DateTime(l.date.year, l.date.month, l.date.day, tod.hour, tod.minute);
      final logged = l.loggedAt ?? sched;
      final diff = (logged.difference(sched)).inMinutes.abs();
      if (diff <= settings.pillOnTimeToleranceMinutes && diff <= maxWindow) onTime++;
    }
    final totalTaken = recent.where((l) => l.taken).length;
    if (totalTaken == 0) return 0;
    return onTime / totalTaken;
  }

  /// Estimated days left based on remaining stock and daily doses.
  Map<String, int> estimateDaysLeft(List<MedPlan> plans) {
    final byId = <String, int>{};
    for (final p in plans) {
      final dosesPerDay = p.scheduleTimes.length;
      final upd = (p.unitsPerDose == 0 ? 1 : p.unitsPerDose);
      final unitsPerDay = dosesPerDay * upd;
      if (unitsPerDay == 0) {
        byId[p.id] = 0; continue;
      }
      byId[p.id] = (p.remainingStock / unitsPerDay).floor();
    }
    return byId;
  }

  /// Compute adherence streak (days) where all scheduled meds for the day were taken on time.
  int adherenceStreakDays(List<MedPlan> plans, List<MedLog> logs, Settings settings, {int lookbackDays = 365}) {
    final byDayPlanTime = <DateTime, Map<String, Set<String>>>{}; // day -> planId -> times taken on-time
    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

    // Index logs by day and plan with on-time check
    const maxWindow2 = 120;
    for (final l in logs.where((l)=> l.taken)) {
      final d = day(l.date);
      final tod = parseTime(l.time);
      final sched = DateTime(l.date.year, l.date.month, l.date.day, tod.hour, tod.minute);
      final logged = l.loggedAt ?? sched;
      final diff = (logged.difference(sched)).inMinutes.abs();
      if (diff <= settings.pillOnTimeToleranceMinutes && diff <= maxWindow2) {
        byDayPlanTime.putIfAbsent(d, ()=>{}).putIfAbsent(l.planId, ()=>{}).add(l.time);
      }
    }

    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < lookbackDays; i++) {
      final d = day(now.subtract(Duration(days: i)));
      // For today, only count the day if all due times up to now are taken on time.
      final isToday = i == 0;
      bool allOk = true;
      for (final p in plans.where((p)=>p.active)) {
        final scheduled = p.scheduleTimes;
        if (scheduled.isEmpty) continue;
        final takenSet = byDayPlanTime[d]?[p.id] ?? const <String>{};
        for (final t in scheduled) {
          if (isToday) {
            final tod = parseTime(t);
            final sched = DateTime(d.year, d.month, d.day, tod.hour, tod.minute);
            if (sched.isAfter(now)) continue; // not due yet today
          }
          if (!takenSet.contains(t)) { allOk = false; break; }
        }
        if (!allOk) break;
      }
      if (allOk) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
