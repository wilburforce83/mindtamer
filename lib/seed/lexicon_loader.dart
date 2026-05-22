// FILE: lib/seed/lexicon_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LexiconBundle {
  final String version;
  final Map<String, dynamic> basewords; // word -> entry
  final Map<String, List<String>> secondarySeeds; // sentiment -> words
  final List<ElementRule> elementRules; // regex rules
  final Map<String, String> fallbackElementBySentiment; // sentiment -> element
  final Map<String, Map<String, List<String>>>
      monsterTypes; // element -> sentiment -> types
  final Map<String, List<String>> spriteTypes; // element -> types
  final NamingLexicon naming;
  final Map<String, List<num>> sentimentHue; // sentiment -> [min, max]
  final Map<String, List<num>> elementHueOverrides; // element -> [min, max]
  final List<num> saturationRange;
  final List<num> lightnessRange;
  final Map<String, List<Map<String, dynamic>>>
      attacks; // element -> attack templates

  LexiconBundle({
    required this.version,
    required this.basewords,
    required this.secondarySeeds,
    required this.elementRules,
    required this.fallbackElementBySentiment,
    required this.monsterTypes,
    required this.spriteTypes,
    required this.naming,
    required this.sentimentHue,
    required this.elementHueOverrides,
    required this.saturationRange,
    required this.lightnessRange,
    required this.attacks,
  });
}

class ElementRule {
  final RegExp pattern;
  final String element;
  ElementRule(this.pattern, this.element);
}

class NamingLexicon {
  final Map<String, List<String>> monsterModifiers;
  final Map<String, List<String>> spriteDescriptors;
  final List<MonsterFamilyProfile> monsterFamilies;

  NamingLexicon({
    required this.monsterModifiers,
    required this.spriteDescriptors,
    required this.monsterFamilies,
  });
}

class MonsterFamilyProfile {
  final String key;
  final String label;
  final List<String> keywords;
  final List<String> themes;
  final Map<String, double> elementWeights;
  final List<String> modifiers;

  MonsterFamilyProfile({
    required this.key,
    required this.label,
    required this.keywords,
    required this.themes,
    required this.elementWeights,
    required this.modifiers,
  });
}

class LexiconLoader {
  static LexiconBundle? _cache;

  static Future<LexiconBundle> load() async {
    if (_cache != null) return _cache!;
    const basePath = 'assets/lexicon/v1/';

    // Load index to get version and file list
    final indexStr = await rootBundle.loadString('${basePath}index.json');
    final indexJson = jsonDecode(indexStr) as Map<String, dynamic>;
    final version = (indexJson['version'] ?? '').toString();

    // Merge basewords a..z
    final Map<String, dynamic> basewords = {};
    for (var c in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
      final fname = 'basewords-$c.json';
      try {
        final s = await rootBundle.loadString('$basePath$fname');
        final m = jsonDecode(s) as Map<String, dynamic>;
        basewords.addAll(m.map((k, v) => MapEntry(k.toString(), v)));
      } catch (_) {
        // Some letters may be empty; skip silently.
      }
    }

    // Secondary seeds
    final secondarySeedsJson = jsonDecode(
      await rootBundle.loadString('${basePath}secondary-seeds.json'),
    ) as Map<String, dynamic>;
    final secondarySeeds = secondarySeedsJson.map((k, v) => MapEntry(
          k.toString(),
          (v as List).map((e) => e.toString()).toList(),
        ));

    // Elements rules + sentiment fallbacks
    final elementsRaw = jsonDecode(
      await rootBundle.loadString('${basePath}elements.json'),
    ) as Map<String, dynamic>;
    final List<ElementRule> rules = [];
    for (final m in (elementsRaw['maps'] as List)) {
      final mm = m as Map<String, dynamic>;
      rules.add(ElementRule(
          RegExp(mm['match'].toString()), mm['element'].toString()));
    }
    final fallbackElementBySentiment =
        (elementsRaw['fallbackBySentiment'] as Map)
            .map((k, v) => MapEntry(k.toString(), v.toString()));

    // Types
    final typesRaw = jsonDecode(
      await rootBundle.loadString('${basePath}types.json'),
    ) as Map<String, dynamic>;
    final monsterTypes = (typesRaw['monsterTypes'] as Map<String, dynamic>).map(
      (el, sMap) => MapEntry(
        el,
        (sMap as Map<String, dynamic>).map((sent, list) => MapEntry(
              sent,
              (list as List).map((e) => e.toString()).toList(),
            )),
      ),
    );
    final spriteTypes = (typesRaw['spriteTypes'] as Map<String, dynamic>).map(
        (el, list) =>
            MapEntry(el, (list as List).map((e) => e.toString()).toList()));

    // Naming grammar
    final namingRaw = jsonDecode(
      await rootBundle.loadString('${basePath}naming.json'),
    ) as Map<String, dynamic>;
    final monsterModifiers =
        (namingRaw['monsterModifiers'] as Map<String, dynamic>)
            .map((el, list) => MapEntry(
                  el.toString(),
                  (list as List).map((e) => e.toString()).toList(),
                ));
    final spriteDescriptors =
        (namingRaw['spriteDescriptors'] as Map<String, dynamic>).map(
      (el, list) => MapEntry(
        el.toString(),
        (list as List).map((e) => e.toString()).toList(),
      ),
    );
    final monsterFamilies = (namingRaw['monsterFamilies'] as List).map((raw) {
      final entry = raw as Map<String, dynamic>;
      return MonsterFamilyProfile(
        key: (entry['key'] ?? '').toString(),
        label: (entry['label'] ?? '').toString(),
        keywords: ((entry['keywords'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        themes: ((entry['themes'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        elementWeights: ((entry['elementWeights'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
        modifiers: ((entry['modifiers'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
    }).toList();
    final naming = NamingLexicon(
      monsterModifiers: monsterModifiers,
      spriteDescriptors: spriteDescriptors,
      monsterFamilies: monsterFamilies,
    );

    // Color palettes
    final palettesRaw = jsonDecode(
      await rootBundle.loadString('${basePath}color-palettes.json'),
    ) as Map<String, dynamic>;
    final sentimentHue = (palettesRaw['sentimentHue'] as Map).map((k, v) =>
        MapEntry(k.toString(), (v as List).map((e) => (e as num)).toList()));
    final elementHueOverrides = (palettesRaw['elementHueOverrides'] as Map).map(
        (k, v) => MapEntry(
            k.toString(), (v as List).map((e) => (e as num)).toList()));
    final saturationRange = (palettesRaw['saturationRange'] as List)
        .map((e) => (e as num))
        .toList();
    final lightnessRange =
        (palettesRaw['lightnessRange'] as List).map((e) => (e as num)).toList();

    // Attacks
    final attacksRaw = jsonDecode(
      await rootBundle.loadString('${basePath}attacks.json'),
    ) as Map<String, dynamic>;
    final attacks = attacksRaw.map((el, list) => MapEntry(
          el.toString(),
          (list as List).map((e) => (e as Map<String, dynamic>)).toList(),
        ));

    _cache = LexiconBundle(
      version: version,
      basewords: basewords,
      secondarySeeds: secondarySeeds,
      elementRules: rules,
      fallbackElementBySentiment: fallbackElementBySentiment,
      monsterTypes: monsterTypes,
      spriteTypes: spriteTypes,
      naming: naming,
      sentimentHue: sentimentHue,
      elementHueOverrides: elementHueOverrides,
      saturationRange: saturationRange,
      lightnessRange: lightnessRange,
      attacks: attacks,
    );
    return _cache!;
  }
}
