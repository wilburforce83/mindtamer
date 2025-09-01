import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 11)
enum MoodMetric {
  @HiveField(0)
  energy,
  @HiveField(1)
  stress,
  @HiveField(2)
  focus,
  @HiveField(3)
  mood,
  @HiveField(4)
  sleepQuality,
  @HiveField(5)
  socialConnection,
}

@HiveType(typeId: 12)
class MoodEntry extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  /// Store values 0–100 by metric name to keep adapters simple/forward-compatible.
  @HiveField(1)
  Map<String, int> values;

  MoodEntry({
    required this.timestamp,
    required this.values,
  });

  static String bucketOf(DateTime t) {
    final h = t.hour;
    if (h >= 5 && h <= 11) return 'morning';
    if (h >= 12 && h <= 17) return 'afternoon';
    if (h >= 18 && h <= 22) return 'evening';
    return 'night';
  }

  int v(MoodMetric m) => values[m.name] ?? 0;
}

