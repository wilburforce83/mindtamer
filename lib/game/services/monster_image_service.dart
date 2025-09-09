import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

import '../../data/hive/boxes.dart';

/// Provides a stable mapping from generated monster names to a 64x64 asset path.
/// - One name maps to exactly one image path (persisted in Hive).
/// - Many names may map to the same image path.
/// - Selection prefers assets that match the monster's element and type.
class MonsterImageService {
  // Supported roots for monster art. Will scan all of these.
  static const List<String> _prefixes = [
    'assets/monsters/',
    'assets/images/monsters/',
    'assets/images/monsters/64x64/',
  ];

  List<String>? _allMonsterAssets; // cached manifest entries under known prefixes

  Future<List<String>> _loadMonsterAssetList() async {
    if (_allMonsterAssets != null) return _allMonsterAssets!;
    dynamic decoded;
    try {
      final text = await rootBundle.loadString('AssetManifest.json');
      decoded = json.decode(text);
    } catch (_) {
      decoded = null; // Some build modes may not include the JSON file; fall back later.
    }

    final out = <String>[];
    bool matchesPrefix(String k) => _prefixes.any((p) => k.startsWith(p));

    if (decoded is Map) {
      for (final key in decoded.keys) {
        final k = key.toString();
        if (matchesPrefix(k) && (k.endsWith('.png') || k.endsWith('.webp'))) {
          out.add(k);
        }
      }
    } else if (decoded is List) {
      for (final v in decoded) {
        final k = v.toString();
        if (matchesPrefix(k) && (k.endsWith('.png') || k.endsWith('.webp'))) {
          out.add(k);
        }
      }
    }
    // Fallback: try static index if manifest provided none
    if (out.isEmpty) {
      try {
        final idx = await rootBundle.loadString('assets/images/monsters/index.json');
        final list = List<String>.from(json.decode(idx));
        out.addAll(list.where((k) => k.endsWith('.png') || k.endsWith('.webp')));
      } catch (_) {}
    }
    out.sort();
    _allMonsterAssets = out;
    return out;
  }

  /// Returns the asset path for a monster display name, creating it if needed.
  /// Element and type help pick a good bucket on first assignment.
  Future<String?> resolveImagePath({
    required String displayName,
    required String element,
    required String type,
    bool debug = false,
  }) async {
    final Box box = monsterImageMapBox();
    final existing = box.get(displayName);
    final elem = element.toLowerCase();
    final typ = type.toLowerCase();
    final fam = _familyFromType(typ);
    if (existing is String && existing.isNotEmpty) {
      final pathOk = _pathMatches(existing, elem, fam, typ);
      if (pathOk) return existing;
      // If persisted mapping no longer matches new rules, allow remap.
    }

    final assets = await _loadMonsterAssetList();
    if (debug) {
      // ignore: avoid_print
      print('[MonsterImageService] assets under prefixes: ${assets.length}');
    }
    // If manifest/index returns nothing, continue to probe known filenames below.

    final typeTokens = _typeCandidates(typ);

    // Strategy: prefer paths that include both element and type strings (case-insensitive),
    // then fall back to element-only, then any.
    bool hasElem(String p) {
      final lp = p.toLowerCase();
      return lp.contains('/$elem/') || lp.contains('_$elem') || lp.contains('${elem}_') || lp.contains('/$elem-') || lp.contains('$elem/');
    }
    bool hasType(String p) {
      final lp = p.toLowerCase();
      // Strong family match if we parsed one from type
      if (fam != null) {
        if (lp.contains('/$fam/') || lp.contains('_$fam') || lp.contains('${fam}_') || lp.contains('/$fam-') || lp.contains('$fam/')) {
          return true;
        }
      }
      for (final t in typeTokens) {
        if (lp.contains('/$t/') || lp.contains('_$t') || lp.contains('${t}_') || lp.contains('/$t-') || lp.contains('$t/')) {
          return true;
        }
      }
      return false;
    }

    final both = assets.where((p) => hasElem(p) && hasType(p)).toList();
    final elemOnly = assets.where((p) => !both.contains(p) && hasElem(p)).toList();
    final any = assets.where((p) => !both.contains(p) && !elemOnly.contains(p)).toList();
    if (debug) {
      // ignore: avoid_print
      print('[MonsterImageService] name="$displayName" type="$type" element="$element" fam=${fam ?? 'n/a'} candidates both=${both.length} elemOnly=${elemOnly.length} any=${any.length}');
    }

    // Family+element filter if both is empty but we can still identify the family from type
    List<String> famElem = const [];
    if (both.isEmpty && fam != null) {
      famElem = elemOnly.where((p) => _pathHasToken(p, fam)).toList();
    }
    List<String> bucket =
        both.isNotEmpty ? both : (famElem.isNotEmpty ? famElem : (elemOnly.isNotEmpty ? elemOnly : any));
    // Prefer a variant (melee/magic) based on family + element when available.
    final pref = _preferredVariant(displayName, type, element);
    if (pref != null) {
      final subset = bucket.where((p) => p.toLowerCase().contains('_${pref}_')).toList();
      if (subset.isNotEmpty) bucket = subset;
    }
    if (bucket.isEmpty) {
      // Fallback: probe a few well-known families directly (no manifest entries available?)
      final probe = await _probeCommonFamilies(elem, typeTokens);
      if (probe != null) {
        await box.put(displayName, probe);
        if (debug) {
          // ignore: avoid_print
          print('[MonsterImageService] probe matched $probe');
        }
        return probe;
      }
      return null;
    }

    // Deterministic pick based on displayName hash.
    final idx = _stableIndex(displayName, bucket.length);
    final chosen = bucket[idx];
    if (debug) {
      // ignore: avoid_print
      print('[MonsterImageService] chosen[$idx/${bucket.length}] $chosen (prefVariant=${pref ?? 'none'})');
    }
    await box.put(displayName, chosen);
    return chosen;
  }

  /// Computes a deterministic index in [0, mod).
  int _stableIndex(String s, int mod) {
    if (mod <= 1) return 0;
    int hash = 0;
    for (final code in s.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash % mod;
  }

  /// Derive coarse type tokens from lexicon type names for filename matching.
  List<String> _typeCandidates(String typ) {
    final t = typ.toLowerCase();
    final out = <String>{t};
    void add(String s) { if (s.isNotEmpty) out.add(s); }

    if (t.contains('gremlin')) { add('gremlin'); add('goblin'); }
    if (t.contains('goblin')) { add('goblin'); }
    if (t.contains('imp')) { add('imp'); }
    if (t.contains('wisp')) { add('wisp'); }
    if (t.contains('wight')) { add('wight'); add('shade'); add('gargoyle'); }
    if (t.contains('shade') || t.contains('dus') || t.contains('gloom') || t.contains('veil')) { add('shade'); }
    if (t.contains('pix')) { add('wisp'); add('shade'); }
    if (t.contains('moss') || t.contains('bloom') || t.contains('thorn') || t.contains('sprig') ) { add('spriggan'); add('myconid'); }
    if (t.contains('eddie') || t.contains('tidel') || t.contains('brine')) { add('serpent'); add('wisp'); }
    if (t.contains('gear') || t.contains('copper') || t.contains('tin') || t.contains('clank')) { add('construct'); add('golem'); }
    if (t.contains('coal') || t.contains('soot') || t.contains('ash')) { add('gargoyle'); add('golem'); }
    if (t.contains('draft') || t.contains('gust') || t.contains('flitter')) { add('harpy'); add('wisp'); }

    // Also include our known family names as a general fallback
    const families = [
      'harpy','gargoyle','drake','golem','serpent','slime','shade','spriggan','myconid','imp','beast','construct','goblin','wisp','insectoid'
    ];
    out.addAll(families);
    return out.toList();
  }

  /// If manifest is unavailable, try a handful of common filename patterns and
  /// return the first one that loads successfully.
  Future<String?> _probeCommonFamilies(String elem, List<String> typeTokens) async {
    const families = [
      'harpy','gargoyle','drake','golem','serpent','slime','shade','spriggan','myconid','imp','beast','construct','goblin','wisp','insectoid'
    ];
    final variants = ['melee','magic'];
    // Try candidates where family appears in typeTokens first
    final preferred = [
      for (final f in families)
        if (typeTokens.any((t) => f == t)) f
    ];
    final others = [for (final f in families) if (!preferred.contains(f)) f];
    final order = [...preferred, ...others];
    for (final fam in order) {
      for (final kind in variants) {
        final p = 'assets/images/monsters/${fam}_${kind}_$elem.png';
        try {
          await rootBundle.load(p);
          return p;
        } catch (_) {}
      }
    }
    return null;
  }

  /// Heuristic preferred variant for image choice.
  String? _preferredVariant(String displayName, String type, String element) {
    final t = type.toLowerCase();
    // Family bias
    final fam = _familyFromType(t) ?? t.split(RegExp(r"\s+")).last;
    const magicFav = {'wisp','shade','harpy'};
    const meleeFav = {'golem','beast','gargoyle','serpent','drake','construct'};
    String? bias;
    if (magicFav.contains(fam)) bias = 'magic';
    if (meleeFav.contains(fam)) bias = 'melee';

    // Modifier bias from display name's first word
    final mod = _modifierFromName(displayName);
    final modBias = _variantFromModifier(mod, fam, element);

    // Element hint
    final elem = element.toLowerCase();
    String? elemBias;
    if ({'light','shadow','air'}.contains(elem)) elemBias = 'magic';
    if ({'metal','nature'}.contains(elem)) elemBias = 'melee';

    // Combine preferences with priority: modifier > family > element > deterministic
    final chosen = modBias ?? bias ?? elemBias ?? ((_stableIndex(type, 2) == 0) ? 'melee' : 'magic');
    return chosen;
  }

  String _modifierFromName(String name) {
    final parts = name.trim().toLowerCase().split(RegExp(r"\s+"));
    return parts.isNotEmpty ? parts.first : '';
  }

  String? _variantFromModifier(String mod, String? family, String element) {
    if (mod.isEmpty) return null;
    final m = mod;
    // Word buckets — extend as desired
    const magicWords = {
      'veil','halo','gleam','ray','prism','echo','wisp','shade','dusk','gloom','night','umbral','aura','rune','glyph','sigil','mist','ripple','tide','spore','spirit','soul','whisper','whirl','gust','zephyr','haze','pulse','surge'
    };
    const meleeWords = {
      'thorn','briar','root','leaf','iron','steel','gear','aegis','stone','rock','boulder','monolith','claw','fang','bite','strike','smash','hammer','pounce','blade','spear','talon','scale','lash','ember','cinder','forge','rust','horn'
    };
    if (magicWords.contains(m)) return 'magic';
    if (meleeWords.contains(m)) return 'melee';

    // Fallback: sub-string cues
    if (m.contains('veil') || m.contains('halo') || m.contains('rune') || m.contains('glyph') || m.contains('mist') || m.contains('wisp')) return 'magic';
    if (m.contains('thorn') || m.contains('briar') || m.contains('iron') || m.contains('gear') || m.contains('stone') || m.contains('claw') || m.contains('fang') || m.contains('blade')) return 'melee';

    // Family hints: wisps/shades tend to magic, golems/beasts/serpents to melee
    if (family != null) {
      if ({'wisp','shade','harpy'}.contains(family)) return 'magic';
      if ({'golem','beast','gargoyle','serpent','drake','construct'}.contains(family)) return 'melee';
    }

    // Element hint
    final e = element.toLowerCase();
    if ({'light','shadow','air'}.contains(e)) return 'magic';
    if ({'metal','nature'}.contains(e)) return 'melee';
    return null;
  }

  String? _familyFromType(String type) {
    final t = type.toLowerCase();
    const families = [
      'slime','wisp','shade','imp','goblin','beast','drake','serpent','insectoid','myconid','spriggan','golem','gargoyle','harpy','undead','construct'
    ];
    for (final f in families) {
      final pattern = r'(?:^|\s)' + RegExp.escape(f) + r'(?:\s|_|-|/|$)';
      final re = RegExp(pattern);
      if (re.hasMatch(t)) return f;
    }
    if (t.contains('gremlin')) return 'goblin';
    if (t.contains('wight')) return 'gargoyle';
    return null;
  }

  bool _pathHasToken(String path, String token) {
    final lp = path.toLowerCase();
    final t = token.toLowerCase();
    return lp.contains('/$t/') || lp.contains('_$t') || lp.contains('${t}_') || lp.contains('/$t-') || lp.contains('$t/');
  }

  bool _pathMatches(String path, String elem, String? fam, String typ) {
    final lp = path.toLowerCase();
    final elemOk = lp.contains('_$elem') || lp.contains('${elem}_') || lp.contains('/$elem/') || lp.contains('/$elem-');
    if (!elemOk) return false;
    if (fam != null) {
      if (lp.contains('_$fam') || lp.contains('${fam}_') || lp.contains('/$fam/')) return true;
    }
    // fallback to token search
    final toks = _typeCandidates(typ);
    for (final t in toks) {
      if (lp.contains('_$t') || lp.contains('${t}_') || lp.contains('/$t/')) return true;
    }
    return false;
  }
}
