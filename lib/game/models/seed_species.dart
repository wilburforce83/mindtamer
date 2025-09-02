import 'package:hive/hive.dart';

part 'seed_species.manual.dart';

@HiveType(typeId: 10)
class SeedSpecies {
  @HiveField(0) String speciesId; // version:element:type:baseWord
  @HiveField(1) String version;
  @HiveField(2) String baseWord;
  @HiveField(3) String element;
  @HiveField(4) String type;
  @HiveField(5) String kind; // sprite | monster
  @HiveField(6) String rarity;
  @HiveField(7) List<String> secondaryExamples;
  @HiveField(8) List<String> colorHexExamples;
  @HiveField(9) List<String> attacksCanonical; // attack names
  @HiveField(10) DateTime firstSeenAt;
  @HiveField(11) int journalRefCount;
  @HiveField(12) List<String> tagsAggregate;
  SeedSpecies({
    required this.speciesId,
    required this.version,
    required this.baseWord,
    required this.element,
    required this.type,
    required this.kind,
    required this.rarity,
    required this.secondaryExamples,
    required this.colorHexExamples,
    required this.attacksCanonical,
    required this.firstSeenAt,
    required this.journalRefCount,
    required this.tagsAggregate,
  });
}

