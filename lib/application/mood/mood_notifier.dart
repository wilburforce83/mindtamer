import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mood_log.dart';
import '../../data/repositories/mood_repository.dart';
import '../providers.dart';

final moodProvider = StateNotifierProvider<MoodNotifier, MoodLog?>((ref) {
  final repo = ref.read(moodRepoProvider);
  final today = repo.getByDate(DateTime.now());
  return MoodNotifier(repo, today);
});

class MoodNotifier extends StateNotifier<MoodLog?> {
  final IMoodRepository _repo;
  MoodNotifier(this._repo, MoodLog? initial) : super(initial);
  Future<void> save(MoodLog log) async {
    state = await _repo.upsertToday(log);
  }

  void lockToday() {
    if (state == null) return;
    state = MoodLog(
      id: state!.id,
      date: state!.date,
      battery: state!.battery,
      stress: state!.stress,
      focus: state!.focus,
      mood: state!.mood,
      sleep: state!.sleep,
      social: state!.social,
      custom1: state!.custom1,
      custom2: state!.custom2,
      locked: true,
    );
    _repo.upsertToday(state!);
  }
}
