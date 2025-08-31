// FILE: lib/features/journal/model/sentiment.dart
// Enum used by Isar via @enumerated on fields
enum Sentiment {
  positive,
  negative,
  mixed,
  neutral,
}

extension SentimentDisplay on Sentiment {
  String get label {
    switch (this) {
      case Sentiment.positive:
        return 'Positive';
      case Sentiment.negative:
        return 'Negative';
      case Sentiment.mixed:
        return 'Mixed';
      case Sentiment.neutral:
        return 'Neutral';
    }
  }
}
