// GENERATED: manual adapters for Hive
part of 'mood_entry.dart';

class MoodMetricAdapter extends TypeAdapter<MoodMetric> {
  @override
  final int typeId = 11;

  @override
  MoodMetric read(BinaryReader reader) {
    final index = reader.readByte();
    switch (index) {
      case 0:
        return MoodMetric.energy;
      case 1:
        return MoodMetric.stress;
      case 2:
        return MoodMetric.focus;
      case 3:
        return MoodMetric.mood;
      case 4:
        return MoodMetric.sleepQuality;
      case 5:
        return MoodMetric.socialConnection;
      default:
        return MoodMetric.mood;
    }
  }

  @override
  void write(BinaryWriter writer, MoodMetric obj) {
    final index = {
      MoodMetric.energy: 0,
      MoodMetric.stress: 1,
      MoodMetric.focus: 2,
      MoodMetric.mood: 3,
      MoodMetric.sleepQuality: 4,
      MoodMetric.socialConnection: 5,
    }[obj]!;
    writer.writeByte(index);
  }
}

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 12;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    // Backward-compatible decoding: timestamp may have been stored as String or int.
    final rawTs = fields[0];
    DateTime ts;
    if (rawTs is DateTime) {
      ts = rawTs;
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else if (rawTs is int) {
      // Interpret as millisecondsSinceEpoch
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs, isUtc: false);
    } else {
      ts = DateTime.now();
    }

    final rawMap = fields[1];
    final Map<String, int> values = {};
    if (rawMap is Map) {
      rawMap.forEach((k, v) {
        final key = k.toString();
        int val;
        if (v is int) {
          val = v;
        } else if (v is double) {
          val = v.round();
        } else {
          val = int.tryParse(v.toString()) ?? 0;
        }
        values[key] = val;
      });
    }
    return MoodEntry(
      timestamp: ts,
      values: values,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.values);
  }
}
