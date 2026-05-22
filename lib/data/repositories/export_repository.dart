import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../hive/boxes.dart';
import '../../features/journal/data/journal_repository.dart';
import '../../features/mood/data/mood_repository.dart' as mood_v2;

class ExportRepository {
  Future<File> exportAll() async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/exports'); if (!await outDir.exists()) await outDir.create(recursive: true);
    final journal = await JournalRepository().searchOnce();
    final moods = mood_v2.MoodRepository.all();
    final plans = medPlanBox().values.toList();
    final medlogs = medLogBox().values.toList();
    final journalCsv = const ListToCsvConverter().convert([
      ['id','createdAtUtc','localDate','title','body','tags','sentiment','schemaVersion'],
      ...journal.map((e)=>[
        e.id,
        e.createdAtUtc.toIso8601String(),
        e.localDate,
        e.title,
        e.body ?? '',
        e.tags.join('|'),
        e.sentiment.name,
        e.schemaVersion,
      ])
    ]);
    final moodsCsv = const ListToCsvConverter().convert([
      ['timestamp','energy','stress','focus','mood','sleepQuality','socialConnection'],
      ...moods.map((m)=>[
        m.timestamp.toIso8601String(),
        m.values['energy'] ?? '',
        m.values['stress'] ?? '',
        m.values['focus'] ?? '',
        m.values['mood'] ?? '',
        m.values['sleepQuality'] ?? '',
        m.values['socialConnection'] ?? '',
      ])
    ]);
    final plansCsv = const ListToCsvConverter().convert([
      ['id','name','dose','times','active'],
      ...plans.map((p)=>[p.id,p.name,p.dose,p.scheduleTimes.join('|'),p.active])
    ]);
    final logsCsv = const ListToCsvConverter().convert([
      ['id','date','planId','taken','time'],
      ...medlogs.map((l)=>[l.id,l.date.toIso8601String(),l.planId,l.taken,l.time])
    ]);
    final meta = jsonEncode({'schemaVersion':1,'generatedAt':DateTime.now().toIso8601String()});
    final zipPath = '${outDir.path}/mind_tamer_export_${DateTime.now().millisecondsSinceEpoch}.zip';
    final encoder = ZipFileEncoder()..create(zipPath);
    encoder.addArchiveFile(ArchiveFile('journal.csv', journalCsv.length, utf8.encode(journalCsv)));
    encoder.addArchiveFile(ArchiveFile('moods.csv', moodsCsv.length, utf8.encode(moodsCsv)));
    encoder.addArchiveFile(ArchiveFile('med_plan.csv', plansCsv.length, utf8.encode(plansCsv)));
    encoder.addArchiveFile(ArchiveFile('med_logs.csv', logsCsv.length, utf8.encode(logsCsv)));
    encoder.addArchiveFile(ArchiveFile('metadata.json', meta.length, utf8.encode(meta)));
    encoder.close();
    return File(zipPath);
  }
}
