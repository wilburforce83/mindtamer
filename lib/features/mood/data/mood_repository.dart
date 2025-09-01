import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood_entry.dart';

class MoodRepository {
  static const _boxName = 'mood_entries';
  static bool _inited = false;

  static Future<void> ensureInitialized() async {
    if (_inited) return;
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(MoodMetricAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(MoodEntryAdapter());
    if (!Hive.isBoxOpen(_boxName)) {
      // Do not double-init; assume app-wide Hive.initFlutter already ran.
      try {
        await Hive.openBox<MoodEntry>(_boxName);
      } catch (_) {
        await Hive.initFlutter();
        await Hive.openBox<MoodEntry>(_boxName);
      }
    }
    _inited = true;
  }

  static Box<MoodEntry> get _box => Hive.box<MoodEntry>(_boxName);

  static Future<void> addSnapshot(Map<MoodMetric, int> values) async {
    final map = {for (var e in values.entries) e.key.name: e.value};
    await _box.add(MoodEntry(timestamp: DateTime.now(), values: map));
  }

  static List<MoodEntry> all() => _box.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  static List<MoodEntry> inRange(DateTime from, DateTime to) =>
      all().where((e) => !e.timestamp.isBefore(from) && !e.timestamp.isAfter(to)).toList();

  static Map<String, double> averageOf(Iterable<MoodEntry> entries) {
    final acc = <String, int>{};
    int n = 0;
    for (final e in entries) {
      n++;
      e.values.forEach((k, v) => acc.update(k, (p) => p + v, ifAbsent: () => v));
    }
    if (n == 0) return {};
    return {for (final kv in acc.entries) kv.key: kv.value / n};
  }

  static Map<String, double> dailyAverage(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
    return averageOf(inRange(from, to));
  }

  static Map<String, double> trailingAvg(int days) {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days));
    return averageOf(inRange(from, to));
  }

  static List<Map<String, dynamic>> movingAverageSeries(String metric, {int days = 90, int window = 7}) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final daily = <DateTime, List<int>>{};
    for (final e in inRange(start, now)) {
      final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      (daily[d] ??= []).add(e.values[metric] ?? 0);
    }
    final orderedDays = List.generate(days, (i) => start.add(Duration(days: i)));
    final dailyAvg = <double>[];
    for (final d in orderedDays) {
      final xs = daily[d];
      dailyAvg.add(xs == null || xs.isEmpty ? double.nan : xs.reduce((a, b) => a + b) / xs.length);
    }
    final out = <Map<String, dynamic>>[];
    for (int i = 0; i < orderedDays.length; i++) {
      final lo = (i - window + 1).clamp(0, i);
      final slice = dailyAvg.sublist(lo, i + 1).where((v) => !v.isNaN).toList();
      final mv = slice.isEmpty ? double.nan : slice.reduce((a, b) => a + b) / slice.length;
      out.add({'t': orderedDays[i], 'y': mv});
    }
    return out;
  }

  static Map<String, Map<String, double>> timeOfDayBreakdown({int days = 30}) {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days));
    final buckets = {
      'morning': <String, List<int>>{},
      'afternoon': <String, List<int>>{},
      'evening': <String, List<int>>{},
      'night': <String, List<int>>{},
    };
    for (final e in inRange(from, to)) {
      final b = MoodEntry.bucketOf(e.timestamp);
      final map = buckets[b]!;
      e.values.forEach((k, v) => (map[k] ??= <int>[]).add(v));
    }
    double avg(List<int> xs) => xs.isEmpty ? double.nan : xs.reduce((a, b) => a + b) / xs.length;
    return {
      for (final b in buckets.entries) b.key: {for (final kv in b.value.entries) kv.key: avg(kv.value)}
    };
  }
}
