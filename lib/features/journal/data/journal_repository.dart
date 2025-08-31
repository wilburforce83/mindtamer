// FILE: lib/features/journal/data/journal_repository.dart
import 'dart:async';
import 'package:isar/isar.dart';

import '../db/journal_isar_service.dart';
import '../model/journal_entry.dart';
import '../model/user_tag.dart';
import '../model/sentiment.dart' as jm;
import 'journal_tag_rules.dart';

class JournalRepository {
  Future<JournalEntry> create({
    required String title,
    String? body,
    required List<String> tags,
    required jm.Sentiment sentiment,
  }) async {
    final isar = await JournalIsarService.instance();
    final now = DateTime.now().toUtc();
    final local = DateTime.now();
    final localDate = _yyyyMmDd(local);
    final entry = JournalEntry()
      ..createdAtUtc = now
      ..localDate = localDate
      ..title = title
      ..body = body
      ..tags = JournalTagRules.normalizeMany(tags)
      ..sentiment = sentiment
      ..schemaVersion = kJournalSchemaVersion;
    await isar.writeTxn(() async {
      await isar.journalEntrys.put(entry);
    });
    return entry;
  }

  Future<void> update(JournalEntry entry) async {
    final isar = await JournalIsarService.instance();
    await isar.writeTxn(() async {
      await isar.journalEntrys.put(entry);
    });
  }

  Future<void> delete(Id id) async {
    final isar = await JournalIsarService.instance();
    await isar.writeTxn(() async {
      await isar.journalEntrys.delete(id);
    });
  }

  Future<JournalEntry?> getById(Id id) async {
    final isar = await JournalIsarService.instance();
    return isar.journalEntrys.get(id);
  }

  Stream<List<JournalEntry>> watchAll({
    DateTime? from,
    DateTime? to,
    List<String>? tags,
    jm.Sentiment? sentiment,
    String? textQuery,
  }) async* {
    final isar = await JournalIsarService.instance();
    yield* isar.journalEntrys.where().anyId().watch(fireImmediately: true).map((items) {
      final filtered = _applyFilters(items, from: from, to: to, tags: tags, sentiment: sentiment, textQuery: textQuery);
      filtered.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      return filtered;
    });
  }

  Future<List<JournalEntry>> searchOnce({
    DateTime? from,
    DateTime? to,
    List<String>? tags,
    jm.Sentiment? sentiment,
    String? textQuery,
  }) async {
    final isar = await JournalIsarService.instance();
    final all = await isar.journalEntrys.where().anyId().findAll();
    final filtered = _applyFilters(all, from: from, to: to, tags: tags, sentiment: sentiment, textQuery: textQuery);
    filtered.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return filtered;
  }

  List<JournalEntry> _applyFilters(
    List<JournalEntry> items, {
    DateTime? from,
    DateTime? to,
    List<String>? tags,
    jm.Sentiment? sentiment,
    String? textQuery,
  }) {
    Iterable<JournalEntry> it = items;
    if (from != null) it = it.where((e) => e.createdAtUtc.isAfter(from));
    if (to != null) it = it.where((e) => e.createdAtUtc.isBefore(to));
    if (sentiment != null) it = it.where((e) => e.sentiment == sentiment);
    if (tags != null && tags.isNotEmpty) it = it.where((e) => e.tags.any((t) => tags.contains(t)));
    if (textQuery != null && textQuery.isNotEmpty) {
      final ql = textQuery.toLowerCase();
      it = it.where((e) =>
            e.title.toLowerCase().contains(ql) ||
            (e.body?.toLowerCase().contains(ql) ?? false) ||
            e.tags.any((t) => t.toLowerCase().contains(ql)),
          );
    }
    return it.toList();
  }

  Future<int> countForDay(String localDate) async {
    final isar = await JournalIsarService.instance();
    return isar.journalEntrys.filter().localDateEqualTo(localDate).count();
  }

  Future<Map<String, int>> countsByDay(DateTime start, DateTime end) async {
    final isar = await JournalIsarService.instance();
    final results = await isar.journalEntrys
        .filter()
        .createdAtUtcBetween(start, end)
        .findAll();
    final map = <String, int>{};
    for (final e in results) {
      map[e.localDate] = (map[e.localDate] ?? 0) + 1;
    }
    return map;
  }

  // Custom tags management
  Future<List<String>> listCustomTags() async {
    final isar = await JournalIsarService.instance();
    final items = await isar.userTags.where().findAll();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items.map((e) => e.name).toList();
  }

  Future<bool> addCustomTag(String raw) async {
    final name = JournalTagRules.normalize(raw);
    if (name.isEmpty) return false;
    if (JournalTagRules.isCurated(name)) return false;

    final isar = await JournalIsarService.instance();
    final count = await isar.userTags.count();
    if (count >= JournalTagRules.maxCustomTagsGlobal) return false;
    final tag = UserTag()
      ..name = name
      ..createdAtUtc = DateTime.now().toUtc();
    try {
      await isar.writeTxn(() => isar.userTags.put(tag));
      return true;
    } catch (_) {
      return false; // likely duplicate
    }
  }

  Future<void> removeCustomTag(String name) async {
    final isar = await JournalIsarService.instance();
    final existing = await isar.userTags.filter().nameEqualTo(name).findFirst();
    if (existing != null) {
      await isar.writeTxn(() => isar.userTags.delete(existing.id));
    }
  }

  String _yyyyMmDd(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
