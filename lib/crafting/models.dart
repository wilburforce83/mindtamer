enum ElementType { fire, water, air, nature, metal, light, shadow }

enum Rarity { common, uncommon, rare, epic, legendary }

enum SlotId { head, chest, hands, legs, feet, weapon }

class ItemMemorySource {
  final String key;
  final String kind; // echo | legacy | future source kinds
  final int? entryId;
  final String? journalTitle;
  final DateTime? journalDate;
  final String? echoId;
  final String? echoTitle;
  final DateTime? echoCreatedAt;
  final String? battleId;
  final String? speciesId;
  final ElementType? element;
  final Rarity? rarity;

  const ItemMemorySource({
    required this.key,
    required this.kind,
    this.entryId,
    this.journalTitle,
    this.journalDate,
    this.echoId,
    this.echoTitle,
    this.echoCreatedAt,
    this.battleId,
    this.speciesId,
    this.element,
    this.rarity,
  });
}

class ItemLineageStep {
  final String key;
  final String kind; // forge | upgrade | fusion | legacy
  final String summary;
  final DateTime at;

  const ItemLineageStep({
    required this.key,
    required this.kind,
    required this.summary,
    required this.at,
  });
}

class Echo {
  final String id;
  final ElementType element;
  final Rarity rarity;
  final DateTime createdAt;
  final List<String> journalTitles;
  final int? entryId; // for pulling journal seed metadata
  const Echo({
    required this.id,
    required this.element,
    required this.rarity,
    required this.createdAt,
    required this.journalTitles,
    this.entryId,
  });
}

class ItemDef {
  final String key;
  final String iconPath;
  final SlotId slot;
  final String? classAffinity;
  final String?
      equipSlot; // optional override for repo slot name (e.g., 'neck', 'ring')
  const ItemDef(
      {required this.key,
      required this.iconPath,
      required this.slot,
      this.classAffinity,
      this.equipSlot});
}

class CraftedItem {
  final String id;
  final ItemDef def;
  final int tier; // 1..13
  final Rarity rarity;
  final ElementType element;
  final String displayName;
  final List<String> dnaJournalTitles;
  final List<ItemMemorySource> memorySources;
  final List<ItemLineageStep> lineageSteps;
  final int upgradeStepsInTier; // 0..3
  final Map<String, num> stats; // ATK/DEF/HP/SPD
  final String? classAffinity;
  const CraftedItem({
    required this.id,
    required this.def,
    required this.tier,
    required this.rarity,
    required this.element,
    required this.displayName,
    required this.dnaJournalTitles,
    this.memorySources = const <ItemMemorySource>[],
    this.lineageSteps = const <ItemLineageStep>[],
    required this.upgradeStepsInTier,
    required this.stats,
    this.classAffinity,
  });

  CraftedItem copyWith({
    ItemDef? def,
    int? tier,
    Rarity? rarity,
    ElementType? element,
    String? displayName,
    List<String>? dnaJournalTitles,
    List<ItemMemorySource>? memorySources,
    List<ItemLineageStep>? lineageSteps,
    int? upgradeStepsInTier,
    Map<String, num>? stats,
  }) =>
      CraftedItem(
        id: id,
        def: def ?? this.def,
        tier: tier ?? this.tier,
        rarity: rarity ?? this.rarity,
        element: element ?? this.element,
        displayName: displayName ?? this.displayName,
        dnaJournalTitles: dnaJournalTitles ?? this.dnaJournalTitles,
        memorySources: memorySources ?? this.memorySources,
        lineageSteps: lineageSteps ?? this.lineageSteps,
        upgradeStepsInTier: upgradeStepsInTier ?? this.upgradeStepsInTier,
        stats: stats ?? this.stats,
        classAffinity: classAffinity,
      );
}
