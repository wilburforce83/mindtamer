// FILE: lib/features/journal/state/journal_controller.dart
import 'package:flutter/foundation.dart';
import '../data/journal_repository.dart';
import '../model/journal_entry.dart';
import '../model/sentiment.dart' as jm;

class JournalFilters {
  DateTime? from;
  DateTime? to;
  List<String> tags = [];
  jm.Sentiment? sentiment;
  String textQuery = '';
}

class JournalController extends ChangeNotifier {
  final repo = JournalRepository();
  final filters = JournalFilters();

  void setRange(Duration? d) {
    if (d == null) {
      filters.from = null;
      filters.to = null;
    } else {
      filters.to = DateTime.now();
      filters.from = DateTime.now().subtract(d);
    }
    notifyListeners();
  }

  void setSentiment(jm.Sentiment? s) {
    filters.sentiment = s;
    notifyListeners();
  }

  void toggleTag(String t) {
    if (filters.tags.contains(t)) {
      filters.tags.remove(t);
    } else {
      filters.tags.add(t);
    }
    notifyListeners();
  }

  void setText(String q) {
    filters.textQuery = q;
    notifyListeners();
  }

  Stream<List<JournalEntry>> stream() {
    return repo.watchAll(
      from: filters.from,
      to: filters.to,
      tags: filters.tags.isEmpty ? null : filters.tags,
      sentiment: filters.sentiment,
      textQuery: filters.textQuery.isEmpty ? null : filters.textQuery,
    );
  }
}

