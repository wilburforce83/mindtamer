// FILE: lib/features/journal/export/journal_export_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/journal_repository.dart';
import '../model/journal_entry.dart';

class JournalExportService {
  final repo = JournalRepository();

  Future<File> export({List<JournalEntry>? entries, bool openShare = true}) async {
    entries ??= await repo.searchOnce();

    // Build CSV
    final rows = <List<dynamic>>[
      ['id', 'createdAtUtc', 'localDate', 'title', 'body', 'sentiment', 'tags|pipe_separated', 'schemaVersion'],
      ...entries.map((e) => [
            e.id,
            e.createdAtUtc.toIso8601String(),
            e.localDate,
            e.title,
            e.body ?? '',
            e.sentiment.name,
            e.tags.join('|'),
            e.schemaVersion,
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);

    // Metadata json
    final metadata = jsonEncode({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
    });

    // Prepare temp dir
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final exportDir = Directory('${dir.path}/exports');
    if (!exportDir.existsSync()) exportDir.createSync(recursive: true);
    final zipPath = '${exportDir.path}/mindtamer_journal_$ts.zip';

    // Build ZIP
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addArchiveFile(ArchiveFile('journal_entries.csv', utf8.encode(csv).length, utf8.encode(csv)));
    encoder.addArchiveFile(ArchiveFile('metadata.json', utf8.encode(metadata).length, utf8.encode(metadata)));
    encoder.close();

    final file = File(zipPath);
    if (openShare) {
      await Share.shareXFiles([XFile(file.path)], subject: 'MindTamer journal export');
    }
    return file;
  }
}

