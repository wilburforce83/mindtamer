import 'package:hive/hive.dart';
import '../hive/boxes.dart';
import '../models/mood_log.dart';
abstract class IMoodRepository {
  Future<MoodLog> upsertToday(MoodLog log);
  MoodLog? getByDate(DateTime date);
  List<MoodLog> recent(int days);
}
class MoodRepository implements IMoodRepository {
  final Box<MoodLog> _box = moodBox();
  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
  @override Future<MoodLog> upsertToday(MoodLog log) async { await _box.put(_dateKey(log.date), log); return log; }
  @override MoodLog? getByDate(DateTime date) => _box.get(_dateKey(date));
  @override List<MoodLog> recent(int days) {
    final now = DateTime.now(); final from = now.subtract(Duration(days: days));
    return _box.values.where((m)=>m.date.isAfter(from)).toList()..sort((a,b)=>a.date.compareTo(b.date));
  }
}
