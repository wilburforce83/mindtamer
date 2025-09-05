import 'package:hive/hive.dart';

part 'journal_seed_meta.manual.dart';

@HiveType(typeId: 9)
class JournalSeedMeta {
  @HiveField(0) int entryId; // Isar Id
  @HiveField(1) String seedHash;
  @HiveField(2) String seedVersion;
  @HiveField(3) Map<String, dynamic> seedSnapshot;
  @HiveField(4) String seedRouting; // sprite | monster | none
  // Optional UX helpers
  @HiveField(5) String? title;
  @HiveField(6) String? primaryTag;
  JournalSeedMeta({
    required this.entryId,
    required this.seedHash,
    required this.seedVersion,
    required this.seedSnapshot,
    required this.seedRouting,
    this.title,
    this.primaryTag,
  });
}
