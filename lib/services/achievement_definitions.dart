List<Map<String, dynamic>> buildAchievementDefinitions() {
  final defs = <Map<String, dynamic>>[];

  defs.addAll(_counterSeries(
    event: 'journal_saved',
    counterKey: 'journal_entries',
    category: 'Journal',
    iconFamily: 'journal',
    tags: const ['journal', 'practice'],
    milestones: const [
      (
        id: 'JOURNAL_1',
        threshold: 1,
        title: 'First Light',
        description: 'Write your first journal entry.',
        points: 5,
      ),
      (
        id: 'JOURNAL_5',
        threshold: 5,
        title: 'Finding Your Voice',
        description: 'Write 5 journal entries.',
        points: 10,
      ),
      (
        id: 'JOURNAL_10',
        threshold: 10,
        title: 'Daily Ink',
        description: 'Write 10 journal entries.',
        points: 15,
      ),
      (
        id: 'JOURNAL_25',
        threshold: 25,
        title: 'Steady Reflection',
        description: 'Write 25 journal entries.',
        points: 20,
      ),
      (
        id: 'JOURNAL_50',
        threshold: 50,
        title: 'Open Book',
        description: 'Write 50 journal entries.',
        points: 30,
      ),
      (
        id: 'JOURNAL_100',
        threshold: 100,
        title: 'Archive of Self',
        description: 'Write 100 journal entries.',
        points: 40,
      ),
    ],
  ));

  defs.addAll(_uniqueSeries(
    event: 'journal_saved',
    uniqueKey: 'journal_tags',
    category: 'Journal',
    iconFamily: 'journal',
    tags: const ['journal', 'tags'],
    milestones: const [
      (
        id: 'JOURNAL_TAGS_5',
        threshold: 5,
        title: 'Wider Lens',
        description: 'Use 5 unique journal tags.',
        points: 10,
      ),
      (
        id: 'JOURNAL_TAGS_15',
        threshold: 15,
        title: 'Mapmaker',
        description: 'Use 15 unique journal tags.',
        points: 20,
      ),
    ],
  ));

  defs.add(_feat(
    id: 'JOURNAL_DEEP_DIVE',
    title: 'Deep Dive',
    description: 'Write a substantial journal entry with at least 80 words.',
    category: 'Journal',
    iconFamily: 'journal',
    points: 10,
    event: 'journal_saved',
    condition: "event=='journal_saved' && word_count>=80",
    tags: const ['journal', 'writing'],
  ));

  defs.addAll(_counterSeries(
    event: 'mood_recorded',
    counterKey: 'mood_records',
    category: 'Mood',
    iconFamily: 'mood',
    tags: const ['mood', 'tracking'],
    milestones: const [
      (
        id: 'MOOD_1',
        threshold: 1,
        title: 'Check-In',
        description: 'Record your first mood snapshot.',
        points: 5,
      ),
      (
        id: 'MOOD_5',
        threshold: 5,
        title: 'Pulse Reading',
        description: 'Record 5 mood snapshots.',
        points: 10,
      ),
      (
        id: 'MOOD_20',
        threshold: 20,
        title: 'Pattern Watcher',
        description: 'Record 20 mood snapshots.',
        points: 15,
      ),
      (
        id: 'MOOD_50',
        threshold: 50,
        title: 'Weather Report',
        description: 'Record 50 mood snapshots.',
        points: 25,
      ),
      (
        id: 'MOOD_100',
        threshold: 100,
        title: 'Inner Forecast',
        description: 'Record 100 mood snapshots.',
        points: 35,
      ),
    ],
  ));

  defs.addAll(_uniqueSeries(
    event: 'mood_recorded',
    uniqueKey: 'mood_days',
    category: 'Mood',
    iconFamily: 'mood',
    tags: const ['mood', 'consistency'],
    milestones: const [
      (
        id: 'MOOD_DAYS_7',
        threshold: 7,
        title: 'Week in View',
        description: 'Record mood on 7 different days.',
        points: 10,
      ),
      (
        id: 'MOOD_DAYS_30',
        threshold: 30,
        title: 'Long View',
        description: 'Record mood on 30 different days.',
        points: 20,
      ),
    ],
  ));

  defs.add(_feat(
    id: 'MOOD_TRIPLE_DAY',
    title: 'Three Point Check',
    description: 'Record 3 mood snapshots in one day.',
    category: 'Mood',
    iconFamily: 'mood',
    points: 10,
    event: 'mood_recorded',
    condition: "event=='mood_recorded' && snapshots_today>=3",
    tags: const ['mood', 'day'],
  ));

  defs.addAll(_counterSeries(
    event: 'med_plan_created',
    counterKey: 'med_plans',
    category: 'Medication',
    iconFamily: 'med',
    tags: const ['medication', 'planning'],
    milestones: const [
      (
        id: 'MED_PLAN_1',
        threshold: 1,
        title: 'Plan in Place',
        description: 'Create your first medication plan.',
        points: 5,
      ),
      (
        id: 'MED_PLAN_3',
        threshold: 3,
        title: 'Routine Builder',
        description: 'Create 3 medication plans.',
        points: 10,
      ),
      (
        id: 'MED_PLAN_5',
        threshold: 5,
        title: 'Regimen Keeper',
        description: 'Create 5 medication plans.',
        points: 20,
      ),
    ],
  ));

  defs.addAll(_counterSeries(
    event: 'med_logged',
    counterKey: 'med_taken',
    category: 'Medication',
    iconFamily: 'med',
    tags: const ['medication', 'adherence'],
    milestones: const [
      (
        id: 'MED_TAKEN_1',
        threshold: 1,
        title: 'Dose Logged',
        description: 'Log your first taken medication dose.',
        points: 5,
      ),
      (
        id: 'MED_TAKEN_10',
        threshold: 10,
        title: 'Steady Dose',
        description: 'Log 10 taken medication doses.',
        points: 10,
      ),
      (
        id: 'MED_TAKEN_50',
        threshold: 50,
        title: 'On Schedule',
        description: 'Log 50 taken medication doses.',
        points: 20,
      ),
      (
        id: 'MED_TAKEN_100',
        threshold: 100,
        title: 'Rhythm Keeper',
        description: 'Log 100 taken medication doses.',
        points: 30,
      ),
    ],
  ));

  defs.addAll(_uniqueSeries(
    event: 'med_logged',
    uniqueKey: 'med_days',
    category: 'Medication',
    iconFamily: 'med',
    tags: const ['medication', 'consistency'],
    milestones: const [
      (
        id: 'MED_DAYS_7',
        threshold: 7,
        title: 'Week of Care',
        description: 'Log medication on 7 different days.',
        points: 10,
      ),
      (
        id: 'MED_DAYS_30',
        threshold: 30,
        title: 'Month of Care',
        description: 'Log medication on 30 different days.',
        points: 20,
      ),
    ],
  ));

  defs.add(_feat(
    id: 'MED_MULTI_TIME_PLAN',
    title: 'Clockwork',
    description: 'Create a medication plan with 3 or more daily reminder times.',
    category: 'Medication',
    iconFamily: 'med',
    points: 10,
    event: 'med_plan_created',
    condition: "event=='med_plan_created' && schedule_count>=3",
    tags: const ['medication', 'planning'],
  ));

  defs.addAll(_counterSeries(
    event: 'battle_end',
    counterKey: 'battles_total',
    category: 'Combat',
    iconFamily: 'battle',
    tags: const ['battle', 'combat'],
    milestones: const [
      (
        id: 'BATTLE_TOTAL_1',
        threshold: 1,
        title: 'First Clash',
        description: 'Finish your first battle.',
        points: 5,
      ),
      (
        id: 'BATTLE_TOTAL_10',
        threshold: 10,
        title: 'Field Tested',
        description: 'Finish 10 battles.',
        points: 10,
      ),
      (
        id: 'BATTLE_TOTAL_50',
        threshold: 50,
        title: 'Battle Worn',
        description: 'Finish 50 battles.',
        points: 20,
      ),
      (
        id: 'BATTLE_TOTAL_100',
        threshold: 100,
        title: 'Seasoned Fighter',
        description: 'Finish 100 battles.',
        points: 30,
      ),
    ],
  ));

  defs.addAll(_counterSeries(
    event: 'battle_end',
    counterKey: 'battles_won',
    category: 'Combat',
    iconFamily: 'battle',
    tags: const ['battle', 'victory'],
    milestones: const [
      (
        id: 'BATTLE_WON_1',
        threshold: 1,
        title: 'Victory Claimed',
        description: 'Win your first battle.',
        points: 5,
      ),
      (
        id: 'BATTLE_WON_10',
        threshold: 10,
        title: 'Monster Tamer',
        description: 'Win 10 battles.',
        points: 10,
      ),
      (
        id: 'BATTLE_WON_50',
        threshold: 50,
        title: 'Relentless',
        description: 'Win 50 battles.',
        points: 20,
      ),
      (
        id: 'BATTLE_WON_100',
        threshold: 100,
        title: 'Arena Legend',
        description: 'Win 100 battles.',
        points: 30,
      ),
    ],
  ));

  defs.addAll(_counterSeries(
    event: 'battle_end',
    counterKey: 'boss_defeats',
    category: 'Combat',
    iconFamily: 'battle',
    tags: const ['battle', 'boss'],
    milestones: const [
      (
        id: 'BOSS_DEFEATS_1',
        threshold: 1,
        title: 'Big Game',
        description: 'Defeat your first boss.',
        points: 10,
      ),
      (
        id: 'BOSS_DEFEATS_5',
        threshold: 5,
        title: 'Nemesis',
        description: 'Defeat 5 bosses.',
        points: 20,
      ),
      (
        id: 'BOSS_DEFEATS_10',
        threshold: 10,
        title: 'Crown Breaker',
        description: 'Defeat 10 bosses.',
        points: 30,
      ),
    ],
  ));

  defs.addAll([
    _feat(
      id: 'BATTLE_NO_ITEMS',
      title: 'Pocket Protector',
      description: 'Win a battle without using any items.',
      category: 'Combat',
      iconFamily: 'battle',
      points: 10,
      event: 'battle_end',
      condition:
          "event=='battle_end' && victory==true && items_used_total==0",
      tags: const ['battle', 'feat'],
    ),
    _feat(
      id: 'BATTLE_SPEEDRUN',
      title: 'Make It Quick',
      description: 'Win a battle in 3 turns or fewer.',
      category: 'Combat',
      iconFamily: 'battle',
      points: 10,
      event: 'battle_end',
      condition: "event=='battle_end' && victory==true && turns<=3",
      tags: const ['battle', 'feat'],
    ),
    _feat(
      id: 'BATTLE_CLUTCH',
      title: 'Hanging By A Thread',
      description: 'Win with 5% HP or less.',
      category: 'Combat',
      iconFamily: 'battle',
      points: 15,
      event: 'battle_end',
      condition: "event=='battle_end' && victory==true && hp_pct<=5",
      tags: const ['battle', 'feat'],
    ),
    _feat(
      id: 'BATTLE_FLAWLESS',
      title: 'Unscathed',
      description: 'Win a battle without taking damage.',
      category: 'Combat',
      iconFamily: 'battle',
      points: 15,
      event: 'battle_end',
      condition:
          "event=='battle_end' && victory==true && damage_taken==0",
      tags: const ['battle', 'feat'],
    ),
  ]);

  defs.addAll(_counterSeries(
    event: 'craft',
    counterKey: 'craft_total',
    category: 'Crafting',
    iconFamily: 'craft',
    tags: const ['crafting', 'forge'],
    milestones: const [
      (
        id: 'CRAFT_TOTAL_1',
        threshold: 1,
        title: 'Spark at the Anvil',
        description: 'Forge your first crafted item.',
        points: 5,
      ),
      (
        id: 'CRAFT_TOTAL_5',
        threshold: 5,
        title: 'Forge Habit',
        description: 'Complete 5 crafting actions.',
        points: 10,
      ),
      (
        id: 'CRAFT_TOTAL_20',
        threshold: 20,
        title: 'Master of Fragments',
        description: 'Complete 20 crafting actions.',
        points: 20,
      ),
    ],
  ));

  defs.addAll([
    _counterAchievement(
      id: 'CRAFT_FROM_ECHOES_1',
      title: 'Born of Echoes',
      description: 'Forge a new item from two echoes.',
      category: 'Crafting',
      iconFamily: 'craft',
      points: 10,
      event: 'craft',
      counterKey: 'craft_from_echoes',
      threshold: 1,
      tags: const ['crafting', 'echo'],
    ),
    _counterAchievement(
      id: 'CRAFT_UPGRADE_1',
      title: 'Refined Edge',
      description: 'Upgrade an item using an echo.',
      category: 'Crafting',
      iconFamily: 'craft',
      points: 10,
      event: 'craft',
      counterKey: 'craft_upgrades',
      threshold: 1,
      tags: const ['crafting', 'upgrade'],
    ),
    _counterAchievement(
      id: 'CRAFT_FUSION_1',
      title: 'Welded Together',
      description: 'Fuse two crafted items together.',
      category: 'Crafting',
      iconFamily: 'craft',
      points: 10,
      event: 'craft',
      counterKey: 'craft_fusions',
      threshold: 1,
      tags: const ['crafting', 'fusion'],
    ),
    _counterAchievement(
      id: 'CRAFT_RARE_1',
      title: 'Quality Control',
      description: 'Craft your first rare-or-better item.',
      category: 'Crafting',
      iconFamily: 'craft',
      points: 15,
      event: 'craft',
      counterKey: 'craft_rare_or_better',
      threshold: 1,
      tags: const ['crafting', 'rarity'],
    ),
    _counterAchievement(
      id: 'CRAFT_RARE_10',
      title: 'Treasure Smith',
      description: 'Craft 10 rare-or-better items.',
      category: 'Crafting',
      iconFamily: 'craft',
      points: 25,
      event: 'craft',
      counterKey: 'craft_rare_or_better',
      threshold: 10,
      tags: const ['crafting', 'rarity'],
    ),
  ]);

  defs.addAll(_counterSeries(
    event: 'item_used',
    counterKey: 'item_uses',
    category: 'Items',
    iconFamily: 'items',
    tags: const ['items', 'utility'],
    milestones: const [
      (
        id: 'ITEM_USE_1',
        threshold: 1,
        title: 'Packed and Ready',
        description: 'Use your first item.',
        points: 5,
      ),
      (
        id: 'ITEM_USE_10',
        threshold: 10,
        title: 'Always Prepared',
        description: 'Use 10 items.',
        points: 10,
      ),
      (
        id: 'ITEM_USE_50',
        threshold: 50,
        title: 'Utility Belt',
        description: 'Use 50 items.',
        points: 20,
      ),
    ],
  ));

  defs.addAll([
    _counterAchievement(
      id: 'HEALING_ITEM_USE_10',
      title: 'Patch Kit',
      description: 'Use 10 healing items.',
      category: 'Items',
      iconFamily: 'items',
      points: 10,
      event: 'item_used',
      counterKey: 'healing_item_uses',
      threshold: 10,
      tags: const ['items', 'healing'],
    ),
    _counterAchievement(
      id: 'ITEM_COLLECT_25',
      title: 'Pocketful',
      description: 'Collect 25 items.',
      category: 'Items',
      iconFamily: 'items',
      points: 10,
      event: 'item_collected',
      counterKey: 'items_collected',
      threshold: 25,
      tags: const ['items', 'collection'],
    ),
    _counterAchievement(
      id: 'ITEM_COLLECT_100',
      title: 'Stockroom',
      description: 'Collect 100 items.',
      category: 'Items',
      iconFamily: 'items',
      points: 20,
      event: 'item_collected',
      counterKey: 'items_collected',
      threshold: 100,
      tags: const ['items', 'collection'],
    ),
  ]);

  defs.addAll(_counterSeries(
    event: 'echo_collected',
    counterKey: 'echoes_collected',
    category: 'Echoes',
    iconFamily: 'echo',
    tags: const ['echo', 'collection'],
    milestones: const [
      (
        id: 'ECHO_1',
        threshold: 1,
        title: 'Resonance Found',
        description: 'Collect your first resonant echo.',
        points: 5,
      ),
      (
        id: 'ECHO_10',
        threshold: 10,
        title: 'Echo Gatherer',
        description: 'Collect 10 resonant echoes.',
        points: 10,
      ),
      (
        id: 'ECHO_25',
        threshold: 25,
        title: 'Echo Archivist',
        description: 'Collect 25 resonant echoes.',
        points: 20,
      ),
      (
        id: 'ECHO_50',
        threshold: 50,
        title: 'Resonant Vault',
        description: 'Collect 50 resonant echoes.',
        points: 30,
      ),
    ],
  ));

  defs.addAll(_uniqueSeries(
    event: 'echo_collected',
    uniqueKey: 'echo_elements',
    category: 'Echoes',
    iconFamily: 'echo',
    tags: const ['echo', 'elements'],
    milestones: const [
      (
        id: 'ECHO_ELEMENTS_3',
        threshold: 3,
        title: 'Balanced Spectrum',
        description: 'Collect echoes from 3 unique elements.',
        points: 10,
      ),
      (
        id: 'ECHO_ELEMENTS_7',
        threshold: 7,
        title: 'Full Spectrum',
        description: 'Collect echoes from all 7 elements.',
        points: 20,
      ),
    ],
  ));

  defs.addAll(_counterSeries(
    event: 'summon_created',
    counterKey: 'summons_created',
    category: 'Sprites',
    iconFamily: 'sprite',
    tags: const ['sprite', 'summon'],
    milestones: const [
      (
        id: 'SUMMON_1',
        threshold: 1,
        title: 'Kindled Sprite',
        description: 'Create your first summoning sprite.',
        points: 5,
      ),
      (
        id: 'SUMMON_5',
        threshold: 5,
        title: 'Spirit Gardener',
        description: 'Create 5 summoning sprites.',
        points: 15,
      ),
    ],
  ));

  defs.addAll(_counterSeries(
    event: 'sprite_equipped',
    counterKey: 'sprite_equips',
    category: 'Sprites',
    iconFamily: 'sprite',
    tags: const ['sprite', 'equip'],
    milestones: const [
      (
        id: 'SPRITE_EQUIP_1',
        threshold: 1,
        title: 'Companion Bound',
        description: 'Equip your first sprite.',
        points: 5,
      ),
      (
        id: 'SPRITE_EQUIP_10',
        threshold: 10,
        title: 'Constellation Caller',
        description: 'Equip sprites 10 times.',
        points: 15,
      ),
    ],
  ));

  defs.addAll(_counterSeries(
    event: 'equip',
    counterKey: 'equip_actions',
    category: 'Equipment',
    iconFamily: 'gear',
    tags: const ['equipment', 'gear'],
    milestones: const [
      (
        id: 'EQUIP_1',
        threshold: 1,
        title: 'Getting Dressed',
        description: 'Equip your first crafted item.',
        points: 5,
      ),
    ],
  ));

  defs.addAll([
    _uniqueAchievement(
      id: 'ALL_SLOTS_ONCE',
      title: 'Well Dressed',
      description: 'Equip something in every armour slot at least once.',
      category: 'Equipment',
      iconFamily: 'gear',
      points: 15,
      event: 'equip',
      uniqueKey: 'equipped_slots',
      threshold: 6,
      tags: const ['equipment', 'set'],
    ),
    _uniqueAchievement(
      id: 'ACCESSORY_COLLECTOR_5',
      title: 'Trinket Tinkerer',
      description: 'Equip 5 unique accessories.',
      category: 'Equipment',
      iconFamily: 'gear',
      points: 10,
      event: 'equip',
      uniqueKey: 'accessories_equipped',
      threshold: 5,
      tags: const ['equipment', 'accessory'],
    ),
    _uniqueAchievement(
      id: 'ACCESSORY_COLLECTOR_10',
      title: 'Bauble Baron',
      description: 'Equip 10 unique accessories.',
      category: 'Equipment',
      iconFamily: 'gear',
      points: 20,
      event: 'equip',
      uniqueKey: 'accessories_equipped',
      threshold: 10,
      tags: const ['equipment', 'accessory'],
    ),
  ]);

  defs.addAll(_counterSeries(
    event: 'progression',
    counterKey: 'level_reached',
    category: 'Progress',
    iconFamily: 'progress',
    tags: const ['progression', 'level'],
    milestones: const [
      (
        id: 'LEVEL_2',
        threshold: 2,
        title: 'Level Up',
        description: 'Reach level 2.',
        points: 5,
      ),
      (
        id: 'LEVEL_5',
        threshold: 5,
        title: 'Coming Into Your Own',
        description: 'Reach level 5.',
        points: 15,
      ),
      (
        id: 'LEVEL_10',
        threshold: 10,
        title: 'Seasoned Soul',
        description: 'Reach level 10.',
        points: 30,
      ),
    ],
  ));

  return defs;
}

Map<String, dynamic> _counterAchievement({
  required String id,
  required String title,
  required String description,
  required String category,
  required String iconFamily,
  required int points,
  required String event,
  required String counterKey,
  required int threshold,
  required List<String> tags,
}) {
  return {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'points': points,
    'secret': false,
    'repeatable': false,
    'tags': tags,
    'icon_family': iconFamily,
    'milestone': threshold,
    'progress_kind': 'counter',
    'progress_key': counterKey,
    'progress_target': threshold,
    'trigger': {
      'event': event,
      'counter_key': counterKey,
      'threshold': threshold,
      'condition': "event=='$event' && counter('$counterKey')>=$threshold",
    },
  };
}

Map<String, dynamic> _uniqueAchievement({
  required String id,
  required String title,
  required String description,
  required String category,
  required String iconFamily,
  required int points,
  required String event,
  required String uniqueKey,
  required int threshold,
  required List<String> tags,
}) {
  return {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'points': points,
    'secret': false,
    'repeatable': false,
    'tags': tags,
    'icon_family': iconFamily,
    'milestone': threshold,
    'progress_kind': 'unique',
    'progress_key': uniqueKey,
    'progress_target': threshold,
    'trigger': {
      'event': event,
      'condition': "event=='$event' && unique('$uniqueKey')>=$threshold",
    },
  };
}

Map<String, dynamic> _feat({
  required String id,
  required String title,
  required String description,
  required String category,
  required String iconFamily,
  required int points,
  required String event,
  required String condition,
  required List<String> tags,
}) {
  return {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'points': points,
    'secret': false,
    'repeatable': false,
    'tags': tags,
    'icon_family': iconFamily,
    'trigger': {
      'event': event,
      'condition': condition,
    },
  };
}

List<Map<String, dynamic>> _counterSeries({
  required String event,
  required String counterKey,
  required String category,
  required String iconFamily,
  required List<String> tags,
  required List<
          ({
            String id,
            int threshold,
            String title,
            String description,
            int points,
          })>
      milestones,
}) {
  return milestones
      .map((m) => _counterAchievement(
            id: m.id,
            title: m.title,
            description: m.description,
            category: category,
            iconFamily: iconFamily,
            points: m.points,
            event: event,
            counterKey: counterKey,
            threshold: m.threshold,
            tags: tags,
          ))
      .toList();
}

List<Map<String, dynamic>> _uniqueSeries({
  required String event,
  required String uniqueKey,
  required String category,
  required String iconFamily,
  required List<String> tags,
  required List<
          ({
            String id,
            int threshold,
            String title,
            String description,
            int points,
          })>
      milestones,
}) {
  return milestones
      .map((m) => _uniqueAchievement(
            id: m.id,
            title: m.title,
            description: m.description,
            category: category,
            iconFamily: iconFamily,
            points: m.points,
            event: event,
            uniqueKey: uniqueKey,
            threshold: m.threshold,
            tags: tags,
          ))
      .toList();
}
