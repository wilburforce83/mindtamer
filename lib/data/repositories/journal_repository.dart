import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../hive/boxes.dart';
import '../models/journal_entry.dart';
abstract class IJournalRepository {
  Future<JournalEntry> add(String text, List<String> tags, Sentiment sentiment, {DateTime? date});
  List<JournalEntry> all();
}
class JournalRepository implements IJournalRepository {
  final Box<JournalEntry> _box = journalBox();
  final _uuid = const Uuid();
  @override Future<JournalEntry> add(String text, List<String> tags, Sentiment sentiment, {DateTime? date}) async {
    final entry = JournalEntry(id: _uuid.v4(), date: date ?? DateTime.now(), text: text, tags: tags, sentiment: sentiment, linkedEnemies: tags);
    await _box.put(entry.id, entry); return entry;
  }
  @override List<JournalEntry> all() => _box.values.toList()..sort((a,b)=>b.date.compareTo(a.date));
}
