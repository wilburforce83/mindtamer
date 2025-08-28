import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/journal_repository.dart';
import '../data/repositories/mood_repository.dart';
import '../data/repositories/medication_repository.dart';
import '../data/repositories/export_repository.dart';
import '../data/repositories/profile_repository.dart';

final journalRepoProvider = Provider<IJournalRepository>((ref) => JournalRepository());
final moodRepoProvider = Provider<IMoodRepository>((ref) => MoodRepository());
final medRepoProvider = Provider<IMedicationRepository>((ref) => MedicationRepository());
final exportRepoProvider = Provider<ExportRepository>((ref) => ExportRepository());
final profileRepoProvider = Provider<IProfileRepository>((ref) => ProfileRepository());
