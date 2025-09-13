import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive/boxes.dart';
import '../data/models/journal_entry.dart';
import '../data/models/med_log.dart';
import '../features/mood/models/mood_entry.dart';

/// Applies passive healing and pre-battle buffs based on user activities.
/// - Heal 25% max HP per mood snapshot
/// - Heal 25% max HP per journal entry
/// - Heal 10% max HP per med taken (on-time or not)
/// - If meds taken on-time, queue a small spirit buff
/// - For mood snapshots, queue small buffs opposite the sentiment (defense for high stress/low mood, regen for low energy, atk for low focus)
class HealthRewardsService {
  static bool _started = false;
  static final List<StreamSubscription> _subs = [];
  static Timer? _hpTimer;

  static Future<void> start() async {
    if (_started) return;
    _started = true;
    // Ensure boxes are open
    try {
      if (!Hive.isBoxOpen('mood_entries')) {
        await Hive.openBox<MoodEntry>('mood_entries');
      }
    } catch (_) {}
    // Backfill since last processed
    await _backfill();
    // Apply idle regeneration immediately, then periodically
    await _applyIdleRegen();
    _hpTimer?.cancel();
    _hpTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _applyIdleRegen();
    });

    // Watch new entries live
    try {
      _subs.add(Hive.box<MoodEntry>('mood_entries').watch().listen((e) {
        if (!e.deleted) {
          final v = e.value;
          _onMoodAdded(v is MoodEntry ? v : null);
        }
      }));
    } catch (_) {}
    try {
      _subs.add(journalBox().watch().listen((e) {
        if (!e.deleted) {
          final v = e.value;
          _onJournalAdded(v is JournalEntry ? v : null);
        }
      }));
    } catch (_) {}
    try {
      _subs.add(medLogBox().watch().listen((e) {
        if (!e.deleted) {
          final v = e.value;
          _onMedLogAdded(v is MedLog ? v : null);
        }
      }));
    } catch (_) {}
  }

  static Future<void> stop() async {
    for (final s in _subs) {
      try { await s.cancel(); } catch (_) {}
    }
    _subs.clear();
    _started = false;
    try { _hpTimer?.cancel(); } catch (_) {}
    _hpTimer = null;
  }

  static Future<void> _backfill() async {
    final meta = playerMetaBox();
    DateTime lastMood = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime lastJournal = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime lastMed = DateTime.fromMillisecondsSinceEpoch(0);
    try { final s = meta.get('lastProcessedMoodAt')?.toString(); if (s != null && s.isNotEmpty) lastMood = DateTime.tryParse(s) ?? lastMood; } catch (_) {}
    try { final s = meta.get('lastProcessedJournalAt')?.toString(); if (s != null && s.isNotEmpty) lastJournal = DateTime.tryParse(s) ?? lastJournal; } catch (_) {}
    try { final s = meta.get('lastProcessedMedAt')?.toString(); if (s != null && s.isNotEmpty) lastMed = DateTime.tryParse(s) ?? lastMed; } catch (_) {}

    try {
      final box = Hive.box<MoodEntry>('mood_entries');
      for (final e in box.values.where((e) => e.timestamp.isAfter(lastMood))) {
        await _onMoodAdded(e);
      }
      await meta.put('lastProcessedMoodAt', DateTime.now().toIso8601String());
    } catch (_) {}
    try {
      for (final e in journalBox().values.cast<JournalEntry>().where((e) => e.date.isAfter(lastJournal))) {
        await _onJournalAdded(e);
      }
      await meta.put('lastProcessedJournalAt', DateTime.now().toIso8601String());
    } catch (_) {}
    try {
      for (final e in medLogBox().values.cast<MedLog>().where((e) => e.date.isAfter(lastMed))) {
        await _onMedLogAdded(e);
      }
      await meta.put('lastProcessedMedAt', DateTime.now().toIso8601String());
    } catch (_) {}
  }

  static Future<void> _onMoodAdded(MoodEntry? entry) async {
    if (entry == null) return;
    await _healPercent(25);
    // Opposite-of-sentiment mapping
    final stress = entry.values['stress'] ?? 0;
    final mood = entry.values['mood'] ?? 0;
    final energy = entry.values['energy'] ?? 0;
    final focus = entry.values['focus'] ?? 0;
    final buffs = <Map<String, dynamic>>[];
    if (stress >= 60 || mood <= 40) {
      buffs.add({'key': 'def+', 'magnitude': 1, 'duration': 2});
    }
    if (energy <= 40) {
      buffs.add({'key': 'regen', 'magnitude': 2, 'duration': 2});
    }
    if (focus <= 40) {
      buffs.add({'key': 'atk+', 'magnitude': 1, 'duration': 2});
    }
    if (buffs.isNotEmpty) _queueBuffs(buffs);
    try { await playerMetaBox().put('lastProcessedMoodAt', entry.timestamp.toIso8601String()); } catch (_) {}
  }

  static Future<void> _onJournalAdded(JournalEntry? entry) async {
    if (entry == null) return;
    await _healPercent(25);
    try { await playerMetaBox().put('lastProcessedJournalAt', entry.date.toIso8601String()); } catch (_) {}
  }

  static Future<void> _onMedLogAdded(MedLog? log) async {
    if (log == null) return;
    if (log.taken) {
      await _healPercent(10);
      if (_isOnTime(log)) {
        _queueBuffs([
          {'key': 'spirit+', 'magnitude': 1, 'duration': 2},
        ]);
      }
    }
    try { await playerMetaBox().put('lastProcessedMedAt', (log.loggedAt ?? log.date).toIso8601String()); } catch (_) {}
  }

  static bool _isOnTime(MedLog log) {
    try {
      final plan = medPlanBox().get(log.planId);
      final times = (plan?.scheduleTimes ?? const <String>[]);
      final sched = times.contains(log.time) ? log.time : (times.isNotEmpty ? times.first : null);
      if (sched == null) return false;
      final parts = sched.split(':');
      final sh = int.parse(parts[0]);
      final sm = int.parse(parts[1]);
      final scheduled = DateTime(log.date.year, log.date.month, log.date.day, sh, sm);
      final actual = log.loggedAt ?? DateTime.now();
      final diff = actual.difference(scheduled).inMinutes.abs();
      return diff <= 15;
    } catch (_) { return false; }
  }

  static Future<void> _healPercent(int percent) async {
    final meta = playerMetaBox();
    int hp = 0;
    try { hp = (meta.get('hp') as int?) ?? 0; } catch (_) {}
    final maxHp = _computeMaxHp();
    final heal = (maxHp * percent / 100).round().clamp(1, maxHp);
    final newHp = (hp + heal).clamp(0, maxHp);
    await meta.put('hp', newHp);
  }

  static void _queueBuffs(List<Map<String, dynamic>> buffs) {
    final meta = playerMetaBox();
    final existing = ((meta.get('pendingBuffs') as List?) ?? const <dynamic>[]).map((e) => Map<String, dynamic>.from(e)).toList();
    existing.addAll(buffs);
    meta.put('pendingBuffs', existing);
  }

  static int _computeMaxHp() {
    // Match battle init baseline
    const baseHp = 60;
    String classKey = 'Sage';
    int level = 1;
    try {
      final vals = profileBox().values;
      if (vals.isNotEmpty) { classKey = vals.first.classKey; level = vals.first.level; }
    } catch (_) {}
    int mod = 0;
    switch (classKey) {
      case 'Warden': mod = 8; break;
      case 'Sentinel': mod = 5; break;
      case 'Empath': mod = 5; break;
      default: mod = 0; break;
    }
    final hpLv = ((level - 1).clamp(0, 999)) * 3;
    return baseHp + mod + hpLv;
  }

  /// Regenerate HP linearly back to full over 6 hours of real time when idle.
  static Future<void> _applyIdleRegen() async {
    final meta = playerMetaBox();
    final now = DateTime.now();
    DateTime last;
    try {
      final s = meta.get('hpLastTickAt')?.toString();
      last = (s != null && s.isNotEmpty) ? (DateTime.tryParse(s) ?? now) : now;
    } catch (_) { last = now; }

    int hp = 0;
    try { hp = (meta.get('hp') as int?) ?? 0; } catch (_) {}
    final maxHp = _computeMaxHp();
    if (hp >= maxHp) {
      await meta.put('hpLastTickAt', now.toIso8601String());
      return;
    }

    final elapsedSec = now.difference(last).inSeconds;
    if (elapsedSec <= 0) {
      await meta.put('hpLastTickAt', now.toIso8601String());
      return;
    }
    // Gain full max HP over 6 hours (21600 seconds)
    final double ratePerSec = maxHp / 21600.0;
    final int gain = (elapsedSec * ratePerSec).floor();
    if (gain <= 0) {
      await meta.put('hpLastTickAt', now.toIso8601String());
      return;
    }
    final newHp = (hp + gain).clamp(0, maxHp);
    await meta.put('hp', newHp);
    await meta.put('hpLastTickAt', now.toIso8601String());
  }
}
