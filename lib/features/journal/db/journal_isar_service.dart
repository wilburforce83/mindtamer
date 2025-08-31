// FILE: lib/features/journal/db/journal_isar_service.dart
// After editing Isar models, run:
// flutter pub run build_runner build --delete-conflicting-outputs

import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../model/journal_entry.dart';
import '../model/user_tag.dart';

class JournalIsarService {
  static Isar? _isar;
  static Future<Isar>? _opening;

  static Future<Isar> instance() async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    if (_opening != null) return _opening!;
    _opening = _open();
    _isar = await _opening!;
    _opening = null;
    return _isar!;
  }

  static Future<Isar> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [JournalEntrySchema, UserTagSchema],
      directory: dir.path,
      name: 'journal_isar',
    );
  }
}
