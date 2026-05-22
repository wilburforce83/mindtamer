// FILE: lib/seed/seed_generator.dart
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import 'lexicon_loader.dart';

class SeedRequest {
  final String version;
  final String title;
  final String body;
  final List<String> tags;
  final String sentiment; // positive | neutral | mixed | negative

  const SeedRequest({
    required this.version,
    required this.title,
    required this.body,
    required this.tags,
    required this.sentiment,
  });
}

class SeedResult {
  final String kind; // sprite | monster
  final String displayName;
  final String baseWord;
  final String secondaryWord;
  final String element; // fire, water, metal, shadow, nature, light, air
  final String type; // from types.json
  final String colorHex;
  final String rarity; // common|uncommon|rare|epic
  final Map<String, int> stats; // hp/atk/spd/spirit
  final List<Map<String, dynamic>> attacks;
  final String hash;
  final String version; // lexicon version used

  const SeedResult({
    required this.kind,
    required this.displayName,
    required this.baseWord,
    required this.secondaryWord,
    required this.element,
    required this.type,
    required this.colorHex,
    required this.rarity,
    required this.stats,
    required this.attacks,
    required this.hash,
    required this.version,
  });
}

class SeedGenerator {
  static final Set<String> _stopwords = {
    'a',
    'an',
    'the',
    'and',
    'or',
    'but',
    'if',
    'then',
    'else',
    'when',
    'at',
    'by',
    'for',
    'from',
    'in',
    'into',
    'on',
    'onto',
    'of',
    'to',
    'up',
    'with',
    'as',
    'is',
    'it',
    'its',
    'be',
    'been',
    'are',
    'was',
    'were',
    'so',
    'that',
    'this',
    'these',
    'those',
    'i',
    'you',
    'he',
    'she',
    'they',
    'we',
    'me',
    'my',
    'your',
    'our',
    'their',
    'them',
    'his',
    'her',
    'us',
    'do',
    'did',
    'does',
    'doing',
    'not',
    'no',
    'yes',
    'can',
    'could',
    'should',
    'would',
    'will',
    'just',
    'about',
    'over',
    'under',
    'again',
    'once',
    'out',
    'off',
    'than',
    'too',
    'very',
    'more',
    'most',
    'some',
    'such',
    'own',
    'same',
    's',
    't',
    'y',
    'm',
    're',
    'll',
    'd'
  };
  static const List<String> _allElements = [
    'fire',
    'water',
    'metal',
    'shadow',
    'nature',
    'light',
    'air',
  ];
  static final Map<String, Map<String, int>> _elementCountCache = {};

  SeedResult generate(SeedRequest req, LexiconBundle bundle) {
    final normTitle = _normalize(req.title);
    final normBody = _normalize(req.body);
    final normTags =
        req.tags.map((e) => _normalize(e)).where((e) => e.isNotEmpty).toList();
    normTags.sort();
    final tokensTitle = _tokens(normTitle);
    final tokensBody = _tokens(normBody);

    // Step 2: Base word selection
    final baseWord = _pickBaseWord(tokensTitle, tokensBody, bundle.basewords);

    // Canonical string (without baseWord) for hash
    final canonical = _canonicalize(
      version: req.version,
      title: normTitle,
      body: normBody,
      tags: normTags,
      sentiment: req.sentiment,
    );
    final hashBytes = sha256.convert(utf8.encode(canonical)).bytes;
    final hashHex = _toHex(hashBytes);

    // Seed PRNG from canonical + baseWord (first 4 bytes)
    final seedBytes = sha256.convert(utf8.encode('$canonical|$baseWord')).bytes;
    int seed = (seedBytes[0] << 24) |
        (seedBytes[1] << 16) |
        (seedBytes[2] << 8) |
        (seedBytes[3]);
    if (seed == 0) seed = 1;
    final rng = _XorShift32(seed);

    // Step 4: Element selection
    final element = _pickElementWithSentiment(
      baseWord: baseWord,
      title: normTitle,
      body: normBody,
      tags: normTags,
      sentiment: req.sentiment,
      rng: rng,
      bundle: bundle,
    );

    // Step 5: Kind selection
    final kind = _pickKind(baseWord, req.sentiment, normTags, rng, bundle);

    // Step 6: Type selection
    final type = _pickType(kind, element, req.sentiment, rng, bundle);

    // Step 7: Name
    final secondaryWord =
        _pickDescriptor(kind, element, req.sentiment, type, rng, bundle);
    final displayName = _composeName(secondaryWord, type);

    // Step 8: Color
    final colorHex = _pickColorHex(element, req.sentiment, rng, bundle);

    // Step 9: Stats
    final stats = _rollStats(kind, req.sentiment, rng);

    // Step 10: Attacks
    final attacks = _pickAttacks(element, rng, bundle);

    // Rarity from base entry or default
    final baseEntry = bundle.basewords[baseWord] as Map<String, dynamic>?;
    final rarity = (baseEntry?['rarity']?.toString() ?? 'common');

    return SeedResult(
      kind: kind,
      displayName: displayName,
      baseWord: baseWord,
      secondaryWord: secondaryWord,
      element: element,
      type: type,
      colorHex: colorHex,
      rarity: rarity,
      stats: stats,
      attacks: attacks,
      hash: hashHex,
      version: bundle.version,
    );
  }

  static String _normalize(String input) {
    final lower = input.toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r"[^a-z0-9\s]"), ' ');
    final collapsed = cleaned.replaceAll(RegExp(r"\s+"), ' ').trim();
    return collapsed;
  }

  static List<String> _tokens(String normalized) {
    if (normalized.isEmpty) return const [];
    final raw = normalized.split(' ');
    final toks = <String>[];
    for (final t in raw) {
      if (t.isEmpty) continue;
      if (_stopwords.contains(t)) continue;
      toks.add(t);
    }
    return toks;
  }

  static String _pickBaseWord(List<String> tokensTitle, List<String> tokensBody,
      Map<String, dynamic> basewords) {
    for (final t in tokensTitle) {
      if (basewords.containsKey(t)) return t;
    }
    for (final t in tokensBody) {
      if (basewords.containsKey(t)) return t;
    }
    // Fallback
    return 'insight';
  }

  static String _canonicalize({
    required String version,
    required String title,
    required String body,
    required List<String> tags,
    required String sentiment,
  }) {
    return [version, title, body, tags.join(','), sentiment].join('|');
  }

  // (removed unused _pickElement without sentiment)

  // Overload with sentiment
  static String _pickElementWithSentiment({
    required String baseWord,
    required String title,
    required String body,
    required List<String> tags,
    required String sentiment,
    required _XorShift32 rng,
    required LexiconBundle bundle,
  }) {
    final baseEntry = bundle.basewords[baseWord] as Map<String, dynamic>?;
    final baseElems =
        (baseEntry?['elements'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final themes =
        (baseEntry?['themes'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];

    final haystack = ('$title $body ${tags.join(' ')}').trim();
    final matchedElems = <String>{};
    for (final rule in bundle.elementRules) {
      if (rule.pattern.hasMatch(haystack)) {
        matchedElems.add(rule.element);
      }
    }
    final scores = {
      for (final element in _allElements) element: 0.0,
    };
    final prevalence = _elementCounts(bundle);
    final sentimentWeights = _sentimentElementWeights(sentiment);
    for (final entry in sentimentWeights.entries) {
      scores[entry.key] = (scores[entry.key] ?? 0.0) + entry.value;
    }

    final fallbackElem = bundle.fallbackElementBySentiment[sentiment] ??
        _fallbackElementForSentiment(sentiment);
    scores[fallbackElem] = (scores[fallbackElem] ?? 0.0) + 0.14;

    for (final element in matchedElems) {
      scores[element] = (scores[element] ?? 0.0) + 0.9;
    }

    final generalTheme = themes.isEmpty || themes.contains('general');
    final baseWeight =
        matchedElems.isNotEmpty ? 0.28 : (generalTheme ? 0.18 : 0.32);
    for (final element in baseElems.toSet()) {
      final factor = _elementBalanceFactor(element, prevalence);
      scores[element] = (scores[element] ?? 0.0) + (baseWeight * factor);
    }

    if (generalTheme && matchedElems.isEmpty && baseElems.contains('shadow')) {
      scores['nature'] = (scores['nature'] ?? 0.0) + 0.08;
      scores['light'] = (scores['light'] ?? 0.0) + 0.07;
      scores['air'] = (scores['air'] ?? 0.0) + 0.05;
    }

    return _pickWeightedElement(scores, rng, fallbackElem);
  }

  static String _pickKind(String baseWord, String sentiment, List<String> tags,
      _XorShift32 rng, LexiconBundle bundle) {
    final baseEntry = bundle.basewords[baseWord] as Map<String, dynamic>?;
    final baseSprite = (baseEntry?['weights']?['sprite'] ?? 0.5).toDouble();
    final rarity = (baseEntry?['rarity']?.toString() ?? 'common');
    final themes =
        (baseEntry?['themes'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];

    double pSprite;
    switch (sentiment) {
      case 'positive':
        // 80–90% sprite, small monster chance
        pSprite = 0.80 + rng.nextDouble() * 0.10;
        // Nudge slightly toward base word preference
        pSprite += (baseSprite - 0.5) * 0.1;
        break;
      case 'neutral':
        // ~50/50, weighted by rarity and a little by base weight
        pSprite = 0.50 + (baseSprite - 0.5) * 0.3;
        final rarityAdj = switch (rarity) {
          'common' => 0.05,
          'uncommon' => 0.0,
          'rare' => -0.05,
          'epic' => -0.10,
          _ => 0.0,
        };
        pSprite += rarityAdj;
        break;
      case 'mixed':
        // ~30% sprite, ~70% monster
        pSprite = 0.30 + (baseSprite - 0.5) * 0.05; // tiny nudge only
        break;
      case 'negative':
        // 90–100% monster. Allow up to 10% sprites if tags/themes suggest healing.
        final healingTags = {
          'wellbeing',
          'sleep',
          'habits',
          'social',
          'heal',
          'healing',
          'rest',
          'recovery',
          'resilience'
        };
        final hasHealingTag = tags.any((t) => healingTags.contains(t));
        final hasHealingTheme = themes.any((t) => healingTags.contains(t));
        pSprite = hasHealingTag || hasHealingTheme ? 0.10 : 0.02;
        break;
      default:
        pSprite = 0.50;
    }
    pSprite = pSprite.clamp(0.0, 1.0);
    final r = rng.nextDouble();
    return r < pSprite ? 'sprite' : 'monster';
  }

  static String _pickType(String kind, String element, String sentiment,
      _XorShift32 rng, LexiconBundle bundle) {
    if (kind == 'sprite') {
      final list = bundle.spriteTypes[element] ?? const <String>[];
      if (list.isNotEmpty) return list[rng.nextInt(list.length)];
      // Fallbacks across any element
      final any = bundle.spriteTypes.values.expand((e) => e).toList();
      return any.isNotEmpty ? any[rng.nextInt(any.length)] : 'Wisp';
    } else {
      final perSent =
          bundle.monsterTypes[element] ?? const <String, List<String>>{};
      List<String> cand =
          perSent[sentiment] ?? perSent['neutral'] ?? const <String>[];
      if (cand.isEmpty) {
        cand = perSent.values.expand((e) => e).toList();
      }
      if (cand.isNotEmpty) {
        return cand[rng.nextInt(cand.length)];
      }
      final fallback = bundle.naming.monsterFamilies;
      return fallback.isNotEmpty
          ? fallback[rng.nextInt(fallback.length)].label
          : 'Goblin';
    }
  }

  static String _pickDescriptor(
    String kind,
    String element,
    String sentiment,
    String type,
    _XorShift32 rng,
    LexiconBundle bundle,
  ) {
    if (kind == 'monster') {
      final pool = <String>[
        ...(bundle.naming.monsterModifiers[element] ?? const <String>[]),
      ];
      final family = _familyProfileForType(type, bundle);
      if (family != null) {
        pool.addAll(family.modifiers);
      }
      final deduped = pool.toSet().toList(growable: false);
      if (deduped.isNotEmpty) {
        return deduped[rng.nextInt(deduped.length)];
      }
    } else {
      final pool = bundle.naming.spriteDescriptors[element] ?? const <String>[];
      if (pool.isNotEmpty) {
        return pool[rng.nextInt(pool.length)];
      }
    }
    String bucket = sentiment;
    if (rng.nextDouble() < 0.15) bucket = 'neutral';
    final list = bundle.secondarySeeds[bucket] ??
        bundle.secondarySeeds['neutral'] ??
        const <String>[];
    if (list.isEmpty) return kind == 'monster' ? 'Echoing' : 'Echo';
    return list[rng.nextInt(list.length)];
  }

  static String _composeName(String descriptor, String type) {
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    return _dedupeAdjacentWords('${cap(descriptor)} ${cap(type)}');
  }

  static String _dedupeAdjacentWords(String s) {
    final parts = s.split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return s.trim();
    final out = <String>[];
    String? last;
    for (final p in parts) {
      final pl = p.toLowerCase();
      if (last == null || pl != last) {
        out.add(p);
        last = pl;
      }
    }
    return out.join(' ');
  }

  static Map<String, int> _elementCounts(LexiconBundle bundle) {
    return _elementCountCache.putIfAbsent(bundle.version, () {
      final counts = {
        for (final element in _allElements) element: 0,
      };
      for (final value in bundle.basewords.values) {
        final entry = value as Map<String, dynamic>;
        final elems = ((entry['elements'] as List?) ?? const [])
            .map((e) => e.toString())
            .toSet();
        for (final element in elems) {
          if (counts.containsKey(element)) {
            counts[element] = counts[element]! + 1;
          }
        }
      }
      return counts;
    });
  }

  static Map<String, double> _sentimentElementWeights(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return const {
          'light': 0.28,
          'nature': 0.24,
          'air': 0.20,
          'water': 0.18,
          'metal': 0.06,
          'fire': 0.03,
          'shadow': 0.01,
        };
      case 'negative':
        return const {
          'shadow': 0.16,
          'metal': 0.22,
          'fire': 0.18,
          'water': 0.12,
          'air': 0.12,
          'nature': 0.10,
          'light': 0.10,
        };
      case 'mixed':
        return const {
          'air': 0.20,
          'water': 0.18,
          'nature': 0.18,
          'light': 0.16,
          'metal': 0.12,
          'fire': 0.10,
          'shadow': 0.06,
        };
      case 'neutral':
      default:
        return const {
          'nature': 0.24,
          'light': 0.18,
          'water': 0.18,
          'air': 0.16,
          'metal': 0.10,
          'shadow': 0.08,
          'fire': 0.06,
        };
    }
  }

  static String _fallbackElementForSentiment(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return 'light';
      case 'negative':
        return 'shadow';
      case 'mixed':
        return 'air';
      case 'neutral':
      default:
        return 'nature';
    }
  }

  static double _elementBalanceFactor(
    String element,
    Map<String, int> counts,
  ) {
    final nonZero = counts.values.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return 1.0;
    final total = nonZero.fold<int>(0, (sum, v) => sum + v);
    final average = total / nonZero.length;
    final count = (counts[element] ?? 0).clamp(1, 1 << 30);
    final factor = average / count;
    return factor.clamp(0.55, 1.35).toDouble();
  }

  static String _pickWeightedElement(
    Map<String, double> scores,
    _XorShift32 rng,
    String fallback,
  ) {
    final total = scores.values.fold<double>(0.0, (sum, v) => sum + v);
    if (total <= 0) return fallback;
    double roll = rng.nextDouble() * total;
    for (final element in _allElements) {
      final score = scores[element] ?? 0.0;
      if (roll <= score) {
        return element;
      }
      roll -= score;
    }
    return fallback;
  }

  static MonsterFamilyProfile? _familyProfileForType(
    String type,
    LexiconBundle bundle,
  ) {
    final normalized = type.toLowerCase();
    for (final family in bundle.naming.monsterFamilies) {
      if (family.key == normalized ||
          family.label.toLowerCase() == normalized) {
        return family;
      }
    }
    return null;
  }

  static String _pickColorHex(
      String element, String sentiment, _XorShift32 rng, LexiconBundle bundle) {
    List<num>? hueRange = bundle.elementHueOverrides[element];
    hueRange ??= bundle.sentimentHue[sentiment];
    hueRange ??= const [200, 260];
    final h = hueRange[0] + rng.nextDouble() * (hueRange[1] - hueRange[0]);
    final s = bundle.saturationRange[0] +
        rng.nextDouble() *
            (bundle.saturationRange[1] - bundle.saturationRange[0]);
    final l = bundle.lightnessRange[0] +
        rng.nextDouble() *
            (bundle.lightnessRange[1] - bundle.lightnessRange[0]);
    final rgb = _hslToRgb(h.toDouble(), s.toDouble(), l.toDouble());
    return '#'
            '${rgb[0].toRadixString(16).padLeft(2, '0')}'
            '${rgb[1].toRadixString(16).padLeft(2, '0')}'
            '${rgb[2].toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  static List<int> _hslToRgb(double h, double s, double l) {
    h = h % 360.0;
    final c = (1 - (2 * l - 1).abs()) * s;
    final hh = h / 60.0;
    final x = c * (1 - ((hh % 2) - 1).abs());
    double r1 = 0, g1 = 0, b1 = 0;
    if (0 <= hh && hh < 1) {
      r1 = c;
      g1 = x;
    } else if (1 <= hh && hh < 2) {
      r1 = x;
      g1 = c;
    } else if (2 <= hh && hh < 3) {
      g1 = c;
      b1 = x;
    } else if (3 <= hh && hh < 4) {
      g1 = x;
      b1 = c;
    } else if (4 <= hh && hh < 5) {
      r1 = x;
      b1 = c;
    } else if (5 <= hh && hh < 6) {
      r1 = c;
      b1 = x;
    }
    final m = l - c / 2;
    final r = ((r1 + m) * 255).round().clamp(0, 255);
    final g = ((g1 + m) * 255).round().clamp(0, 255);
    final b = ((b1 + m) * 255).round().clamp(0, 255);
    return [r, g, b];
  }

  static Map<String, int> _rollStats(
      String kind, String sentiment, _XorShift32 rng) {
    final base = switch (sentiment) {
      'positive' => 40,
      'neutral' => 35,
      'mixed' => 38,
      'negative' => 42,
      _ => 35,
    };
    int hp = base + _range(rng, -4, 6);
    int atk = base + _range(rng, -5, 8);
    int spd = base + _range(rng, -4, 6);
    int spirit = base + _range(rng, -4, 6);
    if (kind == 'monster') {
      atk = (atk * 1.15).round();
      hp += 5;
    } else {
      spd = (spd * 1.15).round();
      spirit = (spirit * 1.15).round();
    }
    return {
      'hp': math.max(1, hp),
      'atk': math.max(1, atk),
      'spd': math.max(1, spd),
      'spirit': math.max(1, spirit),
    };
  }

  static int _range(_XorShift32 rng, int min, int max) {
    // inclusive range
    return min + rng.nextInt(max - min + 1);
  }

  static List<Map<String, dynamic>> _pickAttacks(
      String element, _XorShift32 rng, LexiconBundle bundle) {
    final list = bundle.attacks[element] ?? const <Map<String, dynamic>>[];
    if (list.isEmpty) return const [];
    final rawCount = 1 + rng.nextInt(3); // 1..3
    final count = rawCount.clamp(
        1, list.length); // avoid duplicates when options are limited
    final usedIdx = <int>{};
    final out = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      int idx = rng.nextInt(list.length);
      while (usedIdx.contains(idx)) {
        idx = rng.nextInt(list.length);
      }
      usedIdx.add(idx);
      final base = Map<String, dynamic>.from(list[idx]);
      base['power'] = 8 + rng.nextInt(10); // 8..17
      base['cooldown'] = 1 + rng.nextInt(3); // 1..3
      out.add(base);
    }
    return out;
  }

  static String _toHex(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}

extension SeedResultSerialize on SeedResult {
  Map<String, dynamic> toMap() => {
        'kind': kind,
        'displayName': displayName,
        'baseWord': baseWord,
        'secondaryWord': secondaryWord,
        'element': element,
        'type': type,
        'colorHex': colorHex,
        'rarity': rarity,
        'stats': stats,
        'attacks': attacks,
        'hash': hash,
        'version': version,
      };

  static SeedResult fromMap(Map<String, dynamic> m) => SeedResult(
        kind: (m['kind'] ?? '').toString(),
        displayName: (m['displayName'] ?? '').toString(),
        baseWord: (m['baseWord'] ?? '').toString(),
        secondaryWord: (m['secondaryWord'] ?? '').toString(),
        element: (m['element'] ?? '').toString(),
        type: (m['type'] ?? '').toString(),
        colorHex: (m['colorHex'] ?? '').toString(),
        rarity: (m['rarity'] ?? '').toString(),
        stats: Map<String, int>.from(m['stats'] ?? const <String, int>{}),
        attacks: (m['attacks'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
        hash: (m['hash'] ?? '').toString(),
        version: (m['version'] ?? '').toString(),
      );
}

String speciesIdFrom(SeedResult s) =>
    '${s.version}:${s.element}:${s.type}:${s.baseWord}';

class _XorShift32 {
  int _x;
  _XorShift32(int seed) : _x = seed & 0xFFFFFFFF;

  int next() {
    int x = _x;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= (x >> 17);
    x ^= (x << 5) & 0xFFFFFFFF;
    _x = x & 0xFFFFFFFF;
    return _x;
  }

  double nextDouble() {
    final v = next() & 0xFFFFFFFF;
    return (v.toDouble()) / 0x100000000; // [0,1)
  }

  int nextInt(int max) {
    if (max <= 1) return 0;
    return (next() % max).abs();
  }

  bool nextBool() => nextInt(2) == 0;
}

// no-op
