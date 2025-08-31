// FILE: lib/features/journal/hooks/monster_seed.dart
import '../model/sentiment.dart';

class MonsterSeed {
  final int entryId;
  final String dayKey; // yyyy-MM-dd
  final List<String> tags; // normalized
  final Sentiment sentiment;
  final String echoTitle; // clamped
  final int rngSeed; // lower 64 bits of sha256
  final int rarityRoll; // 0..99
  final int themeCode; // 0..9

  const MonsterSeed({
    required this.entryId,
    required this.dayKey,
    required this.tags,
    required this.sentiment,
    required this.echoTitle,
    required this.rngSeed,
    required this.rarityRoll,
    required this.themeCode,
  });
}

