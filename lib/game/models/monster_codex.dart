import 'package:hive/hive.dart';

part 'monster_codex.manual.dart';

@HiveType(typeId: 13)
class MonsterCodex {
  @HiveField(0) String speciesId;
  @HiveField(1) DateTime discoveredAt;
  @HiveField(2) int defeatedCount;
  @HiveField(3) String? notes;
  @HiveField(4) String? displayName; // optional human-friendly name used for image mapping
  MonsterCodex({
    required this.speciesId,
    required this.discoveredAt,
    this.defeatedCount = 0,
    this.notes,
    this.displayName,
  });
}
