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
    'a','an','the','and','or','but','if','then','else','when','at','by','for','from','in','into','on','onto','of','to','up','with','as','is','it','its','be','been','are','was','were','so','that','this','these','those','i','you','he','she','they','we','me','my','your','our','their','them','his','her','us','do','did','does','doing','not','no','yes','can','could','should','would','will','just','about','over','under','again','once','out','off','than','too','very','more','most','some','such','own','same','s','t','y','m','re','ll','d'
  };

  SeedResult generate(SeedRequest req, LexiconBundle bundle) {
    final normTitle = _normalize(req.title);
    final normBody = _normalize(req.body);
    final normTags = req.tags.map((e) => _normalize(e)).where((e) => e.isNotEmpty).toList();
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
    int seed = (seedBytes[0] << 24) | (seedBytes[1] << 16) | (seedBytes[2] << 8) | (seedBytes[3]);
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
    final baseEntry = bundle.basewords[baseWord] as Map<String, dynamic>?;
    final related = ((baseEntry?['related'] as List?)?.map((e) => e.toString()).toList() ?? ['Echo','Gleam','Trace']);
    final relatedWord = related.isEmpty ? 'Echo' : related[rng.nextInt(related.length)];
    final secondaryWord = _pickSecondary(req.sentiment, rng, bundle);
    final displayName = _composeName(kind, relatedWord, secondaryWord, type, rng);

    // Step 8: Color
    final colorHex = _pickColorHex(element, req.sentiment, rng, bundle);

    // Step 9: Stats
    final stats = _rollStats(kind, req.sentiment, rng);

    // Step 10: Attacks
    final attacks = _pickAttacks(element, rng, bundle);

    // Rarity from base entry or default
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

  static String _pickBaseWord(List<String> tokensTitle, List<String> tokensBody, Map<String, dynamic> basewords) {
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
    final baseElems = (baseEntry?['elements'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    final haystack = ('$title $body ${tags.join(' ')}').trim();
    final matchedElems = <String>{};
    for (final rule in bundle.elementRules) {
      if (rule.pattern.hasMatch(haystack)) {
        matchedElems.add(rule.element);
      }
    }
    final fallbackElem = bundle.fallbackElementBySentiment[sentiment] ?? 'shadow';

    final groups = <_ElementGroup>[];
    if (baseElems.isNotEmpty) groups.add(_ElementGroup(weight: 0.6, items: baseElems.toList()));
    if (matchedElems.isNotEmpty) groups.add(_ElementGroup(weight: 0.3, items: matchedElems.toList()));
    groups.add(_ElementGroup(weight: 0.1, items: [fallbackElem]));

    final totalWeight = groups.fold<double>(0, (a, b) => a + b.weight);
    double roll = rng.nextDouble() * totalWeight;
    for (final g in groups) {
      if (roll < g.weight) {
        final idx = rng.nextInt(g.items.length);
        return g.items[idx];
      }
      roll -= g.weight;
    }
    return fallbackElem; // safety
  }

  static String _pickKind(String baseWord, String sentiment, List<String> tags, _XorShift32 rng, LexiconBundle bundle) {
    final baseEntry = bundle.basewords[baseWord] as Map<String, dynamic>?;
    final baseSprite = (baseEntry?['weights']?['sprite'] ?? 0.5).toDouble();
    final rarity = (baseEntry?['rarity']?.toString() ?? 'common');
    final themes = (baseEntry?['themes'] as List?)?.map((e)=>e.toString()).toList() ?? const <String>[];

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
        final healingTags = {'wellbeing','sleep','habits','social','heal','healing','rest','recovery','resilience'};
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

  static String _pickType(String kind, String element, String sentiment, _XorShift32 rng, LexiconBundle bundle) {
    if (kind == 'sprite') {
      final list = bundle.spriteTypes[element] ?? const <String>[];
      if (list.isNotEmpty) return list[rng.nextInt(list.length)];
      // Fallbacks across any element
      final any = bundle.spriteTypes.values.expand((e) => e).toList();
      return any.isNotEmpty ? any[rng.nextInt(any.length)] : 'Wisp';
    } else {
      final perSent = bundle.monsterTypes[element] ?? const <String, List<String>>{};
      List<String> cand = perSent[sentiment] ?? perSent['neutral'] ?? const <String>[];
      if (cand.isEmpty) {
        cand = perSent.values.expand((e) => e).toList();
      }
      return cand.isNotEmpty ? cand[rng.nextInt(cand.length)] : 'Gremlin';
    }
  }

  static String _pickSecondary(String sentiment, _XorShift32 rng, LexiconBundle bundle) {
    String bucket = sentiment;
    if (rng.nextDouble() < 0.15) bucket = 'neutral';
    final list = bundle.secondarySeeds[bucket] ?? bundle.secondarySeeds['neutral'] ?? const <String>[];
    if (list.isEmpty) return 'Echo';
    return list[rng.nextInt(list.length)];
  }

  static String _composeName(String kind, String related, String secondary, String type, _XorShift32 rng) {
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    final rel = cap(related);
    final sec = cap(secondary);
    if (kind == 'sprite') {
      String name;
      if (rng.nextBool()) {
        name = '$sec $rel';
      } else {
        name = '$rel $type';
      }
      return _dedupeAdjacentWords(name);
    } else {
      final suffix = _inferSuffix(type);
      final merged = _mergeWithOverlap(rel, suffix);
      return merged;
    }
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

  static String _inferSuffix(String type) {
    final t = type.toLowerCase();
    const suffixes = ['gremlin', 'sprite', 'wight', 'wisp', 'orb', 'pix', 'imp'];
    for (final s in suffixes) {
      if (t.endsWith(s)) return s;
    }
    // Fallback to last word/lower
    final m = RegExp(r"[a-z]+$").firstMatch(t);
    return m?.group(0) ?? 'wisp';
  }

  static String _mergeWithOverlap(String a, String b) {
    final la = a.toLowerCase();
    final lb = b.toLowerCase();
    // Find maximum k where a ends with b.substring(0,k)
    int k = math.min(la.length, lb.length);
    for (; k > 0; k--) {
      if (la.endsWith(lb.substring(0, k))) {
        final merged = a + b.substring(k);
        return merged[0].toUpperCase() + merged.substring(1);
      }
    }
    final merged = a + b;
    return merged[0].toUpperCase() + merged.substring(1);
  }

  static String _pickColorHex(String element, String sentiment, _XorShift32 rng, LexiconBundle bundle) {
    List<num>? hueRange = bundle.elementHueOverrides[element];
    hueRange ??= bundle.sentimentHue[sentiment];
    hueRange ??= const [200, 260];
    final h = hueRange[0] + rng.nextDouble() * (hueRange[1] - hueRange[0]);
    final s = bundle.saturationRange[0] + rng.nextDouble() * (bundle.saturationRange[1] - bundle.saturationRange[0]);
    final l = bundle.lightnessRange[0] + rng.nextDouble() * (bundle.lightnessRange[1] - bundle.lightnessRange[0]);
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
    if (0 <= hh && hh < 1) { r1 = c; g1 = x; }
    else if (1 <= hh && hh < 2) { r1 = x; g1 = c; }
    else if (2 <= hh && hh < 3) { g1 = c; b1 = x; }
    else if (3 <= hh && hh < 4) { g1 = x; b1 = c; }
    else if (4 <= hh && hh < 5) { r1 = x; b1 = c; }
    else if (5 <= hh && hh < 6) { r1 = c; b1 = x; }
    final m = l - c / 2;
    final r = ((r1 + m) * 255).round().clamp(0, 255);
    final g = ((g1 + m) * 255).round().clamp(0, 255);
    final b = ((b1 + m) * 255).round().clamp(0, 255);
    return [r, g, b];
  }

  static Map<String, int> _rollStats(String kind, String sentiment, _XorShift32 rng) {
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

  static List<Map<String, dynamic>> _pickAttacks(String element, _XorShift32 rng, LexiconBundle bundle) {
    final list = bundle.attacks[element] ?? const <Map<String, dynamic>>[];
    if (list.isEmpty) return const [];
    final rawCount = 1 + rng.nextInt(3); // 1..3
    final count = rawCount.clamp(1, list.length); // avoid duplicates when options are limited
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
        attacks: (m['attacks'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? const [],
        hash: (m['hash'] ?? '').toString(),
        version: (m['version'] ?? '').toString(),
      );
}

String speciesIdFrom(SeedResult s) => '${s.version}:${s.element}:${s.type}:${s.baseWord}';

class _ElementGroup {
  final double weight;
  final List<String> items;
  _ElementGroup({required this.weight, required this.items});
}

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
