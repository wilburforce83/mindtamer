// FILE: lib/features/journal/state/journal_editor_controller.dart
import 'package:flutter/foundation.dart';
import '../data/journal_repository.dart';
import '../model/journal_entry.dart';
import '../model/sentiment.dart' as jm;

class JournalEditorController extends ChangeNotifier {
  final repo = JournalRepository();

  String title = '';
  String body = '';
  jm.Sentiment sentiment = jm.Sentiment.neutral;
  final List<String> tags = [];
  JournalEntry? existing;

  bool get isValid => title.trim().isNotEmpty && tags.isNotEmpty && title.trim().length <= 80 && tags.length <= 8;

  void setTitle(String v) { title = v; notifyListeners(); }
  void setBody(String v) { body = v; }
  void setSentiment(jm.Sentiment v) { sentiment = v; notifyListeners(); }
  void toggleTag(String t) {
    if (tags.contains(t)) {
      tags.remove(t);
    } else {
      tags.add(t);
    }
    notifyListeners();
  }

  Future<JournalEntry> create() async {
    final entry = await repo.create(title: title.trim(), body: body.trim().isEmpty ? null : body.trim(), tags: tags, sentiment: sentiment);
    return entry;
  }

  void setFrom(JournalEntry e) {
    existing = e;
    title = e.title;
    body = e.body ?? '';
    sentiment = e.sentiment;
    tags
      ..clear()
      ..addAll(e.tags);
    notifyListeners();
  }

  Future<JournalEntry> save() async {
    if (existing == null) return create();
    final e = existing!;
    e
      ..title = title.trim()
      ..body = body.trim().isEmpty ? null : body.trim()
      ..sentiment = sentiment
      ..tags = List.of(tags);
    await repo.update(e);
    return e;
  }
}
