import 'dart:math';
import 'package:uuid/uuid.dart';

import '../../data/hive/boxes.dart';
import '../../data/models/settings.dart';
import '../../seed/seed_generator.dart';
import '../../seed/lexicon_loader.dart';
import '../models/journal_seed_meta.dart';
import '../models/seed_species.dart';
import '../models/encounter_ticket.dart';
import '../models/battle.dart';
import '../models/monster_codex.dart';
import '../models/resonant_echo.dart';
import 'monster_image_service.dart';
import '../models/seed_instance.dart';
import '../models/summons_inventory.dart';
import '../../crafting/inventory_service.dart';
import '../../services/achievement_service.dart';

abstract class SeedRouter {
  Future<void> onJournalSaved({
    required int entryId,
    required SeedResult seed,
    required String title,
    required String body,
    required List<String> tags,
  });
}

abstract class EncounterService {
  Future<String> createTicket({required int entryId, required SeedResult seed, String? sourceTitle, DateTime? sourceDate});
  Future<void> consumeTicket(String ticketId);
}

abstract class BattleService {
  Future<String> start(String ticketId);
  Future<void> resolve({
    required String battleId,
    required String result, // win | loss | escape
    required int turnCount,
    required bool flawless,
  });
}

abstract class CodexService {
  Future<void> onVictory({
    required String speciesId,
    String? displayName,
  });
}

abstract class EchoService {
  Future<String?> maybeDropEcho({
    required String battleId,
    required int entryId,
    required SeedResult seed,
    required bool flawless,
  });
}

abstract class SummonService {
  Future<String> createSummonInstance({
    required String speciesId,
    required Map<String, dynamic> seedSnapshot,
    required String seedHash,
    required Map<String, int> stats,
    required List<Map<String, dynamic>> attacks,
  });
}

class SeedRouterImpl implements SeedRouter {
  final EncounterService encounterService;
  final SummonService summonService;
  SeedRouterImpl({required this.encounterService, required this.summonService});

  @override
  Future<void> onJournalSaved({
    required int entryId,
    required SeedResult seed,
    required String title,
    required String body,
    required List<String> tags,
  }) async {
    final jBox = journalSeedMetaBox();
    // idempotent per entryId
    if (jBox.containsKey(entryId)) return;

    final bundle = await LexiconLoader.load();

    // Create 3 monster encounters (variants 0..2)
    for (int i = 0; i < 3; i++) {
      final monsterSeed = _asMonsterFromContextVariant(
        seed,
        bundle,
        entryId: entryId,
        title: title,
        body: body,
        tags: tags,
        variant: i,
      );
      await _upsertSpecies(monsterSeed, tags);
      // Monster → ticket (always)
      await encounterService.createTicket(entryId: entryId, seed: monsterSeed, sourceTitle: title, sourceDate: DateTime.now().toUtc());
      // Pre-resolve mapping for image continuity
      try {
        await MonsterImageService().resolveImagePath(
          displayName: monsterSeed.displayName,
          element: monsterSeed.element,
          type: monsterSeed.type,
        );
      } catch (_) {}
      // Low-chance sprite drop alongside the monster encounter
      const dropRate = 0.15; // 15% baseline
      final rng = _rngFrom('sprite_drop_$i', entryId, seed.hash);
      if (rng.nextDouble() <= dropRate) {
        final spriteSeed = seed.kind == 'sprite' ? seed : _asSprite(seed, bundle);
        await _upsertSpecies(spriteSeed, tags);
        final snap = spriteSeed.toMap();
        snap['sourceTitle'] = title;
        snap['sourceDate'] = DateTime.now().toUtc().toIso8601String();
        await summonService.createSummonInstance(
          speciesId: speciesIdFrom(spriteSeed),
          seedSnapshot: snap,
          seedHash: spriteSeed.hash,
          stats: spriteSeed.stats,
          attacks: spriteSeed.attacks,
        );
      }
      // Store meta only once (prevents reprocessing), tie to first variant
      if (i == 0) {
        final monsterSnap = monsterSeed.toMap();
        monsterSnap['sourceTitle'] = title;
        monsterSnap['sourceDate'] = DateTime.now().toUtc().toIso8601String();
        await jBox.put(entryId, JournalSeedMeta(
          entryId: entryId,
          seedHash: monsterSeed.hash,
          seedVersion: monsterSeed.version,
          seedSnapshot: monsterSnap,
          seedRouting: 'monster',
          title: title,
        ));
      }
    }
  }

  Future<void> _upsertSpecies(SeedResult seed, List<String> tags) async {
    final sBox = seedSpeciesBox();
    final id = speciesIdFrom(seed);
    final existing = sBox.get(id);
    if (existing == null) {
      final attacks = seed.attacks.map((e) => (e['name'] ?? '').toString()).where((e) => e.isNotEmpty).toList();
      await sBox.put(id, SeedSpecies(
        speciesId: id,
        version: seed.version,
        baseWord: seed.baseWord,
        element: seed.element,
        type: seed.type,
        kind: seed.kind,
        rarity: seed.rarity,
        secondaryExamples: [seed.secondaryWord],
        colorHexExamples: [seed.colorHex],
        attacksCanonical: attacks,
        firstSeenAt: DateTime.now().toUtc(),
        journalRefCount: 1,
        tagsAggregate: tags.toSet().take(12).toList(),
      ));
    } else {
      final sec = List<String>.from(existing.secondaryExamples);
      if (!sec.contains(seed.secondaryWord) && sec.length < 5) sec.add(seed.secondaryWord);
      final colors = List<String>.from(existing.colorHexExamples);
      if (!colors.contains(seed.colorHex) && colors.length < 8) colors.add(seed.colorHex);
      final agg = {...existing.tagsAggregate, ...tags}.take(12).toList();
      await sBox.put(id, SeedSpecies(
        speciesId: existing.speciesId,
        version: existing.version,
        baseWord: existing.baseWord,
        element: existing.element,
        type: existing.type,
        kind: existing.kind,
        rarity: existing.rarity,
        secondaryExamples: sec,
        colorHexExamples: colors,
        attacksCanonical: existing.attacksCanonical,
        firstSeenAt: existing.firstSeenAt,
        journalRefCount: existing.journalRefCount + 1,
        tagsAggregate: agg,
      ));
    }
  }
}

class EncounterServiceImpl implements EncounterService {
  final _uuid = const Uuid();
  @override
  Future<String> createTicket({required int entryId, required SeedResult seed, String? sourceTitle, DateTime? sourceDate}) async {
    final tBox = encounterTicketBox();
    final id = _uuid.v4();
    final snap = seed.toMap();
    if (sourceTitle != null && sourceTitle.isNotEmpty) snap['sourceTitle'] = sourceTitle;
    if (sourceDate != null) snap['sourceDate'] = sourceDate.toIso8601String();
    final ticket = EncounterTicket(
      ticketId: id,
      entryId: entryId,
      speciesId: speciesIdFrom(seed),
      seedHash: seed.hash,
      seedSnapshot: snap,
      state: 'open',
      createdAt: DateTime.now().toUtc(),
    );
    await tBox.put(id, ticket);
    return id;
  }

  @override
  Future<void> consumeTicket(String ticketId) async {
    final tBox = encounterTicketBox();
    final t = tBox.get(ticketId);
    if (t == null) return;
    await tBox.put(ticketId, EncounterTicket(
      ticketId: t.ticketId,
      entryId: t.entryId,
      speciesId: t.speciesId,
      seedHash: t.seedHash,
      seedSnapshot: t.seedSnapshot,
      state: 'consumed',
      createdAt: t.createdAt,
    ));
  }
}

class BattleServiceImpl implements BattleService {
  final _uuid = const Uuid();
  final CodexService codex;
  final EchoService echo;
  BattleServiceImpl({required this.codex, required this.echo});

  @override
  Future<String> start(String ticketId) async {
    final tBox = encounterTicketBox();
    final t = tBox.get(ticketId);
    if (t == null) { throw StateError('Ticket not found'); }
    if (t.state != 'open') { throw StateError('Ticket must be open'); }
    // consume ticket
    await EncounterServiceImpl().consumeTicket(ticketId);
    final id = _uuid.v4();
    final b = Battle(
      battleId: id,
      ticketId: ticketId,
      speciesId: t.speciesId,
      seedHash: t.seedHash,
      startedAt: DateTime.now().toUtc(),
    );
    await battleBox().put(id, b);
    return id;
  }

  @override
  Future<void> resolve({required String battleId, required String result, required int turnCount, required bool flawless}) async {
    final bBox = battleBox();
    final tBox = encounterTicketBox();
    final b = bBox.get(battleId);
    if (b == null) return;
    final updated = Battle(
      battleId: b.battleId,
      ticketId: b.ticketId,
      speciesId: b.speciesId,
      seedHash: b.seedHash,
      startedAt: b.startedAt,
      endedAt: DateTime.now().toUtc(),
      result: result,
      turnCount: turnCount,
    );
    await bBox.put(battleId, updated);

    if (result != 'win') {
      // On loss/escape, return the encounter to the open pool so it can be retried
      final t = tBox.get(updated.ticketId);
      if (t != null) {
        await tBox.put(t.ticketId, EncounterTicket(
          ticketId: t.ticketId,
          entryId: t.entryId,
          speciesId: t.speciesId,
          seedHash: t.seedHash,
          seedSnapshot: t.seedSnapshot,
          state: 'open',
          createdAt: t.createdAt,
        ));
      }
      return;
    }

    // On win: codex + echo
    final ticket = tBox.get(updated.ticketId);
    String? displayName;
    if (ticket != null) {
      try {
        final seed = SeedResultSerialize.fromMap(Map<String, dynamic>.from(ticket.seedSnapshot));
        displayName = seed.displayName;
      } catch (_) {}
    }
    await codex.onVictory(speciesId: updated.speciesId, displayName: displayName);
    // Achievements: battle_end event
    try {
      // infer weapon from currently equipped
      String? weaponKey;
      try {
        final eq = equipmentBox().get('slots') as Map?;
        final w = (eq?['weapon'] as Map?)?.map((k, v) => MapEntry(k.toString(), v));
        if (w != null) {
          final crafted = CraftedInventoryService.getById((w['id'] ?? '').toString());
          weaponKey = crafted?.def.key;
        }
      } catch (_) {}
      await AchievementService().recordBattleEnd(
        victory: result == 'win',
        turns: turnCount,
        isBoss: (ticket?.seedSnapshot['isBoss'] == true),
        damageTaken: 0,
        itemsUsedTotal: 0,
        itemsUsedHeal: 0,
        skillsUsedHeal: 0,
        hpPct: 100,
        weaponKey: weaponKey,
      );
    } catch (_) {}
    if (ticket != null && (ticket.seedSnapshot['noEcho'] != true)) {
      final seed = SeedResultSerialize.fromMap(Map<String, dynamic>.from(ticket.seedSnapshot));
      await echo.maybeDropEcho(
        battleId: updated.battleId,
        entryId: ticket.entryId,
        seed: seed,
        flawless: flawless,
      );
    }
  }
}

class CodexServiceImpl implements CodexService {
  @override
  Future<void> onVictory({required String speciesId, String? displayName}) async {
    final box = monsterCodexBox();
    final existing = box.get(speciesId);
    if (existing == null) {
      await box.put(speciesId, MonsterCodex(
        speciesId: speciesId,
        discoveredAt: DateTime.now().toUtc(),
        defeatedCount: 1,
        displayName: displayName,
      ));
    } else {
      await box.put(speciesId, MonsterCodex(
        speciesId: existing.speciesId,
        discoveredAt: existing.discoveredAt,
        defeatedCount: existing.defeatedCount + 1,
        notes: existing.notes,
        displayName: existing.displayName ?? displayName,
      ));
    }
  }
}

class EchoServiceImpl implements EchoService {
  static const Map<String, double> _rates = {
    'common': 0.60,
    'uncommon': 0.45,
    'rare': 0.30,
    'epic': 0.15,
  };

  @override
  Future<String?> maybeDropEcho({required String battleId, required int entryId, required SeedResult seed, required bool flawless}) async {
    var rate = _rates[seed.rarity] ?? 0.30;
    final s = _settings();
    if (s.autoGrantEchoOnWinDebug) rate = 1.0;
    if (flawless) rate = (rate + 0.05).clamp(0.0, 0.9);
    final rng = _rngFrom(battleId, seed.hash);
    if (rng.nextDouble() <= rate) {
      final id = const Uuid().v4();
      final e = ResonantEcho(
        echoId: id,
        battleId: battleId,
        entryId: entryId,
        speciesId: speciesIdFrom(seed),
        seedHash: seed.hash,
        title: seed.displayName,
        excerpt: seed.baseWord,
        element: seed.element,
        colorHex: seed.colorHex,
        rarity: seed.rarity,
        createdAt: DateTime.now().toUtc(),
      );
      await resonantEchoBox().put(id, e);
      return id;
    }
    return null;
  }

  Random _rngFrom(String battleId, String seedHash) {
    // hash both strings into a seed
    final s = '$battleId|$seedHash';
    int acc = 0;
    for (final code in s.codeUnits) { acc = (acc * 31 + code) & 0x7fffffff; }
    return Random(acc);
  }
}

class SummonServiceImpl implements SummonService {
  @override
  Future<String> createSummonInstance({required String speciesId, required Map<String, dynamic> seedSnapshot, required String seedHash, required Map<String, int> stats, required List<Map<String, dynamic>> attacks}) async {
    final id = const Uuid().v4();
    final inst = SeedInstance(
      instanceId: id,
      speciesId: speciesId,
      createdAt: DateTime.now().toUtc(),
      source: 'journal',
      seedHash: seedHash,
      seedSnapshot: seedSnapshot,
      stats: stats,
      attacks: attacks,
      state: 'inventory',
    );
    await seedInstanceBox().put(id, inst);
    await summonsInventoryBox().put(id, SummonsInventoryItem(instanceId: id));
    return id;
  }
}

Settings _settings() {
  final b = settingsBox();
  return b.values.isNotEmpty ? b.values.first : Settings(id: 'default');
}

Random _rngFrom(String salt, int entryId, String seedHash) {
  final s = '$salt|$entryId|$seedHash';
  int acc = 0;
  for (final code in s.codeUnits) { acc = (acc * 31 + code) & 0x7fffffff; }
  return Random(acc);
}


SeedResult _asMonsterFromContextVariant(SeedResult s, LexiconBundle bundle, {required int entryId, required String title, required String body, required List<String> tags, int variant = 0}) {
  // Use entryId + variant to inject variety across similar entries while keeping weighting.
  final rng = _rngFrom('monster_family|v$variant', entryId, s.hash);
  final family = _pickFamily(title: title, body: body, tags: tags, baseWord: s.baseWord, element: s.element, rng: rng);
  // Base modifier from generator, with a 20% chance to swap to an element-appropriate synonym
  String mod = (s.secondaryWord.isNotEmpty) ? s.secondaryWord : _fallbackModForElement(s.element, rng);
  final syns = _synonymsForElement(s.element);
  if (syns.isNotEmpty && (rng.nextDouble() < 0.20)) {
    // pick a synonym different from current when possible
    final pool = syns.where((w) => w.toLowerCase() != mod.toLowerCase()).toList(growable: true);
    if (pool.isEmpty) pool.addAll(syns);
    mod = pool[rng.nextInt(pool.length)];
  }
  final display = '${_cap(mod)} ${_cap(family)}';
  // Lock the type to the canonical family token (lowercase) for stability and asset matching.
  final typeCanonical = family.toLowerCase();
  return SeedResult(
    kind: 'monster',
    displayName: display,
    baseWord: s.baseWord,
    secondaryWord: s.secondaryWord,
    element: s.element,
    type: typeCanonical,
    colorHex: s.colorHex,
    rarity: s.rarity,
    stats: s.stats,
    attacks: s.attacks,
    hash: s.hash,
    version: s.version,
  );
}

SeedResult _asSprite(SeedResult s, LexiconBundle bundle) {
  final list = bundle.spriteTypes[s.element] ?? const <String>[];
  final types = list.isNotEmpty ? list : const <String>['Wisp'];
  final idx = _stableIndex('${s.hash}|sprite', types.length);
  final t = types[idx];
  return SeedResult(
    kind: 'sprite',
    displayName: s.displayName,
    baseWord: s.baseWord,
    secondaryWord: s.secondaryWord,
    element: s.element,
    type: t,
    colorHex: s.colorHex,
    rarity: s.rarity,
    stats: s.stats,
    attacks: s.attacks,
    hash: s.hash,
    version: s.version,
  );
}

int _stableIndex(String s, int mod) {
  if (mod <= 1) return 0;
  int hash = 0;
  for (final code in s.codeUnits) { hash = (hash * 31 + code) & 0x7fffffff; }
  return hash % mod;
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _fallbackModForElement(String element, Random rng) {
  final byElem = <String, List<String>>{
    'fire': ['Cinder','Ember','Ash','Forge'],
    'water': ['Ripple','Brine','Tide','Mire'],
    'air': ['Gust','Zephyr','Draft','Sigh'],
    'light': ['Halo','Gleam','Ray','Prism'],
    'shadow': ['Shade','Veil','Gloom','Dusk'],
    'nature': ['Thorn','Bloom','Root','Leaf'],
    'metal': ['Gear','Aegis','Iron','Copper'],
  };
  final list = byElem[element] ?? const ['Echo'];
  return list[rng.nextInt(list.length)];
}

String _normalize(String input) {
  final lower = input.toLowerCase();
  final cleaned = lower.replaceAll(RegExp(r"[^a-z0-9\s]"), ' ');
  return cleaned.replaceAll(RegExp(r"\s+"), ' ').trim();
}

List<String> _tokens(String s) {
  if (s.isEmpty) return const [];
  final raw = s.split(' ');
  const stop = {
    'a','an','the','and','or','but','if','then','else','at','by','for','from','in','on','of','to','up','with','as','is','it','be','are','was','were','so','that','this','these','those','i','you','he','she','they','we','me','my','your','our','their','them','do','did','does','not','no','yes','can','could','should','would','will','just','about','over','under','again','once','out','off','than','too','very','more','most','some','such','own','same'
  };
  final out = <String>[];
  for (final t in raw) {
    if (t.isEmpty || stop.contains(t)) continue;
    out.add(t);
  }
  return out;
}

String _pickFamily({
  required String title,
  required String body,
  required List<String> tags,
  required String baseWord,
  required String element,
  required Random rng,
}) {
  const families = [
    'slime','wisp','shade','imp','goblin','beast','drake','serpent','insectoid','myconid','spriggan','golem','gargoyle','harpy','undead','construct'
  ];
  final scores = {for (final f in families) f: 1.0};

  final text = _normalize('$title $body ${tags.join(' ')}');
  final toks = _tokens(text).toSet();

  final map = <String, List<String>>{
    'slime': ['slime','ooze','gel','goo','mire'],
    'wisp': ['wisp','orb','spark','flare','echo','gleam'],
    'shade': ['shade','dusk','gloom','night','veil','void','shadow'],
    'imp': ['imp','mischief','prank','sprite'],
    'goblin': ['goblin','gremlin','trick','scrap','tinker'],
    'beast': ['beast','wolf','cat','claw','fang','pounce'],
    'drake': ['drake','dragon','wyrm','scale','fire'],
    'serpent': ['serpent','snake','cobra','coil','venom','hiss'],
    'insectoid': ['insect','beetle','mantis','bug','chitin'],
    'myconid': ['mushroom','spore','fungi','cap','mold'],
    'spriggan': ['thorn','briar','sprig','root','leaf','twig','wood'],
    'golem': ['golem','stone','rock','boulder','monolith'],
    'gargoyle': ['gargoyle','statue','perch','spire'],
    'harpy': ['harpy','bird','talon','wing','gust'],
    'undead': ['undead','skeleton','bone','ghoul','revenant'],
    'construct': ['construct','gear','cog','metal','iron','tin','clock','robot','automaton'],
  };

  // Keyword matches
  for (final entry in map.entries) {
    final fam = entry.key;
    for (final k in entry.value) {
      if (toks.contains(k)) scores[fam] = (scores[fam]! + 3.0);
    }
  }

  // Direct family word in tokens is a strong signal
  for (final fam in families) {
    if (toks.contains(fam)) scores[fam] = (scores[fam]! + 4.0);
  }

  // Element synergy
  final synergy = <String, List<String>>{
    'water': ['serpent','slime','myconid'],
    'air': ['harpy','wisp','drake'],
    'fire': ['drake','imp','gargoyle'],
    'nature': ['spriggan','myconid','beast','serpent'],
    'metal': ['construct','golem','gargoyle'],
    'light': ['wisp','harpy','gargoyle'],
    'shadow': ['shade','undead','gargoyle','imp'],
  };
  for (final fam in (synergy[element] ?? const <String>[])) {
    scores[fam] = (scores[fam]! + 1.5);
  }

  // Avoid over-picking imp unless explicitly suggested
  scores['imp'] = (scores['imp']! * 0.7);

  // Weighted pick
  final total = scores.values.fold<double>(0.0, (a, b) => a + b);
  double roll = rng.nextDouble() * (total == 0 ? 1.0 : total);
  for (final fam in families) {
    final w = scores[fam]!;
    if (roll <= w) return fam;
    roll -= w;
  }
  return 'goblin';
}

List<String> _synonymsForElement(String element) {
  switch (element.toLowerCase()) {
    case 'fire':
      return const ['Ember','Cinder','Ash','Flare','Flame','Blaze','Forge','Sear','Spark'];
    case 'water':
      return const ['Ripple','Tide','Brine','Surge','Spray','Mist','Current','Stream','Wave'];
    case 'air':
      return const ['Gust','Zephyr','Draft','Sigh','Whirl','Gale','Breath','Vapor'];
    case 'light':
      return const ['Halo','Gleam','Prism','Ray','Beam','Shine','Aurora','Glow'];
    case 'shadow':
      return const ['Shade','Veil','Gloom','Dusk','Night','Umbral','Eclipse'];
    case 'nature':
      return const ['Thorn','Briar','Root','Leaf','Bloom','Petal','Sap','Vine'];
    case 'metal':
      return const ['Gear','Aegis','Iron','Steel','Copper','Rust','Alloy','Plate'];
    default:
      return const ['Echo'];
  }
}
