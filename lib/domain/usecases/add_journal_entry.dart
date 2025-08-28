import '../../data/models/journal_entry.dart';
import '../../data/repositories/journal_repository.dart';
class AddJournalEntry {
  final IJournalRepository repo;
  AddJournalEntry(this.repo);
  Future<JournalEntry> call(String text, List<String> tags, Sentiment sentiment) => repo.add(text, tags, sentiment);
}
