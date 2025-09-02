import 'package:hive/hive.dart';

part 'resonant_echo.manual.dart';

@HiveType(typeId: 14)
class ResonantEcho {
  @HiveField(0) String echoId;
  @HiveField(1) String battleId;
  @HiveField(2) int entryId;
  @HiveField(3) String speciesId;
  @HiveField(4) String seedHash;
  @HiveField(5) String title;
  @HiveField(6) String excerpt;
  @HiveField(7) String element;
  @HiveField(8) String colorHex;
  @HiveField(9) String rarity;
  @HiveField(10) DateTime createdAt;
  ResonantEcho({
    required this.echoId,
    required this.battleId,
    required this.entryId,
    required this.speciesId,
    required this.seedHash,
    required this.title,
    required this.excerpt,
    required this.element,
    required this.colorHex,
    required this.rarity,
    required this.createdAt,
  });
}

