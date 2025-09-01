// FILE: lib/features/journal/data/journal_tag_rules.dart
class JournalTagRules {
  static const int maxTagsPerEntry = 8;
  static const int maxCustomTagsGlobal = 25;

  static const List<String> curated = [
    'sleep', 'work', 'family', 'anxiety', 'anger', 'social', 'diet', 'exercise', 'meds', 'therapy',
    'school', 'focus', 'money', 'pain', 'travel', 'deadlines', 'rumination', 'overwhelm', 'gratitude', 'achievement',
  ];

  static String normalize(String input) {
    final trimmed = input.trim().toLowerCase();
    final collapsed = trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final res = collapsed.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return res;
  }

  static List<String> normalizeMany(Iterable<String> input) {
    final set = <String>{};
    for (final t in input) {
      final n = normalize(t);
      if (n.isNotEmpty) set.add(n);
    }
    return set.toList();
  }

  static bool isCurated(String tag) => curated.contains(tag);
}
