import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../hive/boxes.dart';
class ExportRepository {
  Future<File> exportAll() async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/exports'); if (!await outDir.exists()) await outDir.create(recursive: true);
    final journal = journalBox().values.toList();
    final moods = moodBox().values.toList();
    final plans = medPlanBox().values.toList();
    final medlogs = medLogBox().values.toList();
    final journalCsv = const ListToCsvConverter().convert([
      ['id','date','text','tags','sentiment','linkedEnemies'],
      ...journal.map((e)=>[e.id,e.date.toIso8601String(),e.text,e.tags.join('|'),e.sentiment.name,e.linkedEnemies.join('|')])
    ]);
    final moodsCsv = const ListToCsvConverter().convert([
      ['id','date','battery','stress','focus','mood','sleep','social','custom1','custom2','locked'],
      ...moods.map((m)=>[m.id,m.date.toIso8601String(),m.battery,m.stress,m.focus,m.mood,m.sleep,m.social,m.custom1??'',m.custom2??'',m.locked])
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
