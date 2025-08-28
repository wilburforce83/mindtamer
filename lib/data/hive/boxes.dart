import 'package:hive_flutter/hive_flutter.dart';
import '../models/journal_entry.dart';
import '../models/mood_log.dart';
import '../models/med_plan.dart';
import '../models/med_log.dart';
import '../models/achievement.dart';
import '../models/player_profile.dart';
import '../models/settings.dart';

class BoxNames {
  static const journal = 'journal';
  static const moods = 'moods';
  static const medPlans = 'med_plans';
  static const medLogs = 'med_logs';
  static const achievements = 'achievements';
  static const profiles = 'profiles';
  static const settings = 'settings';
}

Future<void> openAllBoxes() async {
  await Hive.openBox<JournalEntry>(BoxNames.journal);
  await Hive.openBox<MoodLog>(BoxNames.moods);
  await Hive.openBox<MedPlan>(BoxNames.medPlans);
  await Hive.openBox<MedLog>(BoxNames.medLogs);
  await Hive.openBox<Achievement>(BoxNames.achievements);
  await Hive.openBox<PlayerProfile>(BoxNames.profiles);
  await Hive.openBox<Settings>(BoxNames.settings);
}

Box<JournalEntry> journalBox() => Hive.box<JournalEntry>(BoxNames.journal);
Box<MoodLog> moodBox() => Hive.box<MoodLog>(BoxNames.moods);
Box<MedPlan> medPlanBox() => Hive.box<MedPlan>(BoxNames.medPlans);
Box<MedLog> medLogBox() => Hive.box<MedLog>(BoxNames.medLogs);
Box<Achievement> achievementBox() => Hive.box<Achievement>(BoxNames.achievements);
Box<PlayerProfile> profileBox() => Hive.box<PlayerProfile>(BoxNames.profiles);
Box<Settings> settingsBox() => Hive.box<Settings>(BoxNames.settings);
