// FILE: lib/features/journal/model/journal_entry.dart
import 'package:isar/isar.dart';
import 'sentiment.dart';

part 'journal_entry.g.dart';

const kJournalSchemaVersion = 1;

@Collection()
class JournalEntry {
  Id id = Isar.autoIncrement;

  // Created once, immutable after create
  @Index(type: IndexType.value, unique: false, caseSensitive: false)
  late DateTime createdAtUtc;

  // yyyy-MM-dd from device local time
  @Index(type: IndexType.hash, unique: false, caseSensitive: true)
  late String localDate;

  @Index(type: IndexType.value, unique: false, caseSensitive: false)
  late String title; // 1-80

  String? body; // <= ~10k

  // Up to 8, normalized lower_snake_case
  List<String> tags = [];

  @enumerated
  @Index()
  late Sentiment sentiment;

  // for future migrations
  int schemaVersion = kJournalSchemaVersion;
}

