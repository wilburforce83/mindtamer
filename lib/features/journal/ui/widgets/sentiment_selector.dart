// FILE: lib/features/journal/ui/widgets/sentiment_selector.dart
import 'package:flutter/material.dart';
import '../../../journal/model/sentiment.dart' as jm;

class SentimentSelector extends StatelessWidget {
  final jm.Sentiment value;
  final ValueChanged<jm.Sentiment> onChanged;
  const SentimentSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = jm.Sentiment.values;
    return Wrap(
      spacing: 8,
      children: [
        for (final s in items)
          ChoiceChip(
            label: Text(s.name),
            selected: value == s,
            onSelected: (_) => onChanged(s),
          ),
      ],
    );
  }
}
