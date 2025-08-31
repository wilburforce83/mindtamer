// FILE: lib/features/journal/hooks/journal_events.dart
import 'dart:async';
import '../model/journal_entry.dart';
import 'monster_seed.dart';

class JournalEvents {
  static final _controller = StreamController<({JournalEntry entry, MonsterSeed? seed})>.broadcast();

  static void emitSaved(JournalEntry entry, {MonsterSeed? seed}) {
    _controller.add((entry: entry, seed: seed));
  }

  static Stream<({JournalEntry entry, MonsterSeed? seed})> get stream => _controller.stream;
}

