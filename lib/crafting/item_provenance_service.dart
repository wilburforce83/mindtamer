import '../data/hive/boxes.dart';
import '../features/journal/data/journal_repository.dart';
import '../features/journal/model/journal_entry.dart';
import '../game/models/resonant_echo.dart';
import 'models.dart';

class ItemProvenanceService {
  static Future<ItemMemorySource> sourceFromEcho(Echo echo) async {
    final stored = _storedEcho(echo.id);
    final entryId = _normalizedEntryId(stored?.entryId ?? echo.entryId);
    JournalEntry? journal;
    if (entryId != null) {
      try {
        journal = await JournalRepository().getById(entryId);
      } catch (_) {
        journal = null;
      }
    }

    final echoTitle = _clean(stored?.title) ??
        _firstNonEmpty(echo.journalTitles) ??
        'Resonant Echo';
    return ItemMemorySource(
      key: _sourceKey(
        echoId: stored?.echoId ?? echo.id,
        entryId: entryId,
        echoTitle: echoTitle,
      ),
      kind: 'echo',
      entryId: entryId,
      journalTitle: _clean(journal?.title),
      journalDate: journal?.createdAtUtc,
      echoId: stored?.echoId ?? echo.id,
      echoTitle: echoTitle,
      echoCreatedAt: stored?.createdAt ?? echo.createdAt,
      battleId: _clean(stored?.battleId),
      speciesId: _clean(stored?.speciesId),
      element: echo.element,
      rarity: echo.rarity,
    );
  }

  static Future<List<ItemMemorySource>> sourcesFromEchoes(
      Iterable<Echo> echoes) async {
    final out = <ItemMemorySource>[];
    for (final echo in echoes) {
      out.add(await sourceFromEcho(echo));
    }
    return mergeSources(out);
  }

  static List<ItemMemorySource> mergeSources(
    Iterable<ItemMemorySource> sources, {
    int maxKeep = 120,
  }) {
    final merged = <String, ItemMemorySource>{};
    for (final source in sources) {
      if (source.key.isEmpty) continue;
      merged[source.key] = source;
    }
    final list = merged.values.toList()
      ..sort((a, b) => _sortDateOf(b).compareTo(_sortDateOf(a)));
    if (list.length > maxKeep) {
      return list.take(maxKeep).toList(growable: false);
    }
    return list;
  }

  static List<ItemLineageStep> mergeLineage(
    Iterable<ItemLineageStep> steps, {
    int maxKeep = 80,
  }) {
    final merged = <String, ItemLineageStep>{};
    for (final step in steps) {
      if (step.key.isEmpty) continue;
      merged[step.key] = step;
    }
    final list = merged.values.toList()..sort((a, b) => b.at.compareTo(a.at));
    if (list.length > maxKeep) {
      return list.take(maxKeep).toList(growable: false);
    }
    return list;
  }

  static ItemLineageStep buildLineageStep({
    required String kind,
    required String summary,
    DateTime? at,
    String? key,
  }) {
    final when = at ?? DateTime.now().toUtc();
    return ItemLineageStep(
      key: key ?? '$kind:${when.toIso8601String()}:$summary',
      kind: kind,
      summary: summary,
      at: when,
    );
  }

  static List<ItemMemorySource> legacySourcesFromTitles(List<String> titles) {
    final out = <ItemMemorySource>[];
    for (final raw in titles) {
      final title = raw.trim();
      if (title.isEmpty) continue;
      out.add(ItemMemorySource(
        key: 'legacy:$title',
        kind: 'legacy',
        echoTitle: title,
      ));
    }
    return mergeSources(out);
  }

  static String sourceHeadline(ItemMemorySource source) {
    final journalTitle = _clean(source.journalTitle);
    final echoTitle = _clean(source.echoTitle);
    if (journalTitle != null &&
        echoTitle != null &&
        echoTitle != journalTitle) {
      return '$journalTitle -> $echoTitle';
    }
    return journalTitle ?? echoTitle ?? 'Unknown Memory';
  }

  static DateTime? sourceDisplayDate(ItemMemorySource source) {
    return source.journalDate ?? source.echoCreatedAt;
  }

  static String labelForEchoSource(ItemMemorySource source) {
    return _clean(source.echoTitle) ??
        _clean(source.journalTitle) ??
        'Resonant Echo';
  }

  static ResonantEcho? _storedEcho(String echoId) {
    try {
      final box = resonantEchoBox();
      final found = box.get(echoId);
      if (found is ResonantEcho) return found;
    } catch (_) {}
    return null;
  }

  static int? _normalizedEntryId(int? entryId) {
    if (entryId == null || entryId <= 0) return null;
    return entryId;
  }

  static String _sourceKey({
    required String echoId,
    required int? entryId,
    required String echoTitle,
  }) {
    if (entryId != null) return 'echo:$echoId:entry:$entryId';
    return 'echo:$echoId:${echoTitle.toLowerCase()}';
  }

  static String? _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      final clean = _clean(value);
      if (clean != null) return clean;
    }
    return null;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static DateTime _sortDateOf(ItemMemorySource source) {
    return sourceDisplayDate(source) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
