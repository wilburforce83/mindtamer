import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/journal_entry.dart';
import '../../data/repositories/journal_repository.dart';
import '../providers.dart';
final journalListProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>((ref) => JournalNotifier(ref.read(journalRepoProvider)));
class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  final IJournalRepository _repo;
  JournalNotifier(this._repo) : super(_repo.all());
  Future<void> add(String text, List<String> tags, Sentiment sentiment) async { await _repo.add(text, tags, sentiment); state = _repo.all(); }
}
