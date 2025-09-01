import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'features/mood/data/mood_repository.dart';
import 'data/models/journal_entry.dart';
import 'data/models/mood_log.dart';
import 'data/models/med_plan.dart';
import 'data/models/med_log.dart';
import 'data/models/achievement.dart';
import 'data/models/player_profile.dart';
import 'data/models/settings.dart';
import 'data/hive/boxes.dart';
import 'core/pixel_assets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(MoodLogAdapter());
  Hive.registerAdapter(MedPlanAdapter());
  Hive.registerAdapter(MedLogAdapter());
  Hive.registerAdapter(AchievementAdapter());
  Hive.registerAdapter(PlayerProfileAdapter());
  Hive.registerAdapter(SettingsAdapter());
  Hive.registerAdapter(SentimentAdapter());

  await openAllBoxes();
  await PixelAssets.init();
  await MoodRepository.ensureInitialized();

  runApp(const ProviderScope(child: MindTamerApp()));
}
