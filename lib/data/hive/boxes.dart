import 'package:hive_flutter/hive_flutter.dart';
import '../models/journal_entry.dart';
import '../models/mood_log.dart';
import '../models/med_plan.dart';
import '../models/med_log.dart';
import '../models/achievement.dart';
import '../models/player_profile.dart';
import '../models/settings.dart';
import '../../game/models/journal_seed_meta.dart';
import '../../game/models/seed_species.dart';
import '../../game/models/encounter_ticket.dart';
import '../../game/models/battle.dart';
import '../../game/models/monster_codex.dart';
import '../../game/models/resonant_echo.dart';
import '../../game/models/seed_instance.dart';
import '../../game/models/summons_inventory.dart';

class BoxNames {
  static const journal = 'journal';
  static const moods = 'moods';
  static const medPlans = 'med_plans';
  static const medLogs = 'med_logs';
  static const achievements = 'achievements';
  static const profiles = 'profiles';
  static const settings = 'settings';
  static const equipment = 'equipment';
  static const journalSeedMeta = 'journal_seed_meta';
  static const seedSpecies = 'seed_species';
  static const encounterTickets = 'encounter_tickets';
  static const battles = 'battles';
  static const monsterCodex = 'monster_codex';
  static const resonantEchoes = 'resonant_echoes';
  static const seedInstances = 'seed_instances';
  static const summonsInventory = 'summons_inventory';
  static const playerMeta = 'player_meta'; // dynamic key-value for setup/name/etc.
}

Future<void> openAllBoxes() async {
  await Hive.openBox<JournalEntry>(BoxNames.journal);
  await Hive.openBox<MoodLog>(BoxNames.moods);
  await Hive.openBox<MedPlan>(BoxNames.medPlans);
  await Hive.openBox<MedLog>(BoxNames.medLogs);
  await Hive.openBox<Achievement>(BoxNames.achievements);
  await Hive.openBox<PlayerProfile>(BoxNames.profiles);
  await Hive.openBox<Settings>(BoxNames.settings);
  await Hive.openBox(BoxNames.equipment); // dynamic box for equipment slots
  await Hive.openBox<JournalSeedMeta>(BoxNames.journalSeedMeta);
  await Hive.openBox<SeedSpecies>(BoxNames.seedSpecies);
  await Hive.openBox<EncounterTicket>(BoxNames.encounterTickets);
  await Hive.openBox<Battle>(BoxNames.battles);
  await Hive.openBox<MonsterCodex>(BoxNames.monsterCodex);
  await Hive.openBox<ResonantEcho>(BoxNames.resonantEchoes);
  await Hive.openBox<SeedInstance>(BoxNames.seedInstances);
  await Hive.openBox<SummonsInventoryItem>(BoxNames.summonsInventory);
  await Hive.openBox(BoxNames.playerMeta);
}

Box<JournalEntry> journalBox() => Hive.box<JournalEntry>(BoxNames.journal);
Box<MoodLog> moodBox() => Hive.box<MoodLog>(BoxNames.moods);
Box<MedPlan> medPlanBox() => Hive.box<MedPlan>(BoxNames.medPlans);
Box<MedLog> medLogBox() => Hive.box<MedLog>(BoxNames.medLogs);
Box<Achievement> achievementBox() => Hive.box<Achievement>(BoxNames.achievements);
Box<PlayerProfile> profileBox() => Hive.box<PlayerProfile>(BoxNames.profiles);
Box<Settings> settingsBox() => Hive.box<Settings>(BoxNames.settings);
Box equipmentBox() => Hive.box(BoxNames.equipment);
Box<JournalSeedMeta> journalSeedMetaBox() => Hive.box<JournalSeedMeta>(BoxNames.journalSeedMeta);
Box<SeedSpecies> seedSpeciesBox() => Hive.box<SeedSpecies>(BoxNames.seedSpecies);
Box<EncounterTicket> encounterTicketBox() => Hive.box<EncounterTicket>(BoxNames.encounterTickets);
Box<Battle> battleBox() => Hive.box<Battle>(BoxNames.battles);
Box<MonsterCodex> monsterCodexBox() => Hive.box<MonsterCodex>(BoxNames.monsterCodex);
Box<ResonantEcho> resonantEchoBox() => Hive.box<ResonantEcho>(BoxNames.resonantEchoes);
Box<SeedInstance> seedInstanceBox() => Hive.box<SeedInstance>(BoxNames.seedInstances);
Box<SummonsInventoryItem> summonsInventoryBox() => Hive.box<SummonsInventoryItem>(BoxNames.summonsInventory);
Box playerMetaBox() => Hive.box(BoxNames.playerMeta);
