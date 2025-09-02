import 'dart:math';
import 'package:uuid/uuid.dart';

import '../../data/hive/boxes.dart';
import '../../data/models/settings.dart';
import '../../seed/seed_generator.dart';
import '../models/journal_seed_meta.dart';
import '../models/seed_species.dart';
import '../models/encounter_ticket.dart';
import '../models/battle.dart';
import '../models/monster_codex.dart';
import '../models/resonant_echo.dart';
import '../models/seed_instance.dart';
import '../models/summons_inventory.dart';

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
  Future<String> createTicket({required int entryId, required SeedResult seed});
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

abstract class CodexService { Future<void> onVictory(String speciesId); }

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

    final speciesId = speciesIdFrom(seed);
    await _upsertSpecies(seed, tags);

    if (seed.kind == 'sprite') {
      await summonService.createSummonInstance(
        speciesId: speciesId,
        seedSnapshot: seed.toMap(),
        seedHash: seed.hash,
        stats: seed.stats,
        attacks: seed.attacks,
      );
      // could link instance to journal if desired later
      await jBox.put(entryId, JournalSeedMeta(
        entryId: entryId,
        seedHash: seed.hash,
        seedVersion: seed.version,
        seedSnapshot: seed.toMap(),
        seedRouting: 'sprite',
      ));
      return;
    }

    // Monster → ticket
    await encounterService.createTicket(entryId: entryId, seed: seed);
    await jBox.put(entryId, JournalSeedMeta(
      entryId: entryId,
      seedHash: seed.hash,
      seedVersion: seed.version,
      seedSnapshot: seed.toMap(),
      seedRouting: 'monster',
    ));
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
  Future<String> createTicket({required int entryId, required SeedResult seed}) async {
    final tBox = encounterTicketBox();
    EncounterTicket? existing;
    for (final t in tBox.values) { if (t.entryId == entryId && t.state == 'open') { existing = t; break; } }
    if (existing != null) return existing.ticketId;
    final id = _uuid.v4();
    final ticket = EncounterTicket(
      ticketId: id,
      entryId: entryId,
      speciesId: speciesIdFrom(seed),
      seedHash: seed.hash,
      seedSnapshot: seed.toMap(),
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
      // debug setting: optionally return ticket to open on loss
      final s = _settings();
      if ((result == 'loss' || result == 'escape') && s.returnTicketOnLossDebug) {
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
      }
      return;
    }

    // On win: codex + echo
    await codex.onVictory(updated.speciesId);
    final ticket = tBox.get(updated.ticketId);
    if (ticket != null) {
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
  Future<void> onVictory(String speciesId) async {
    final box = monsterCodexBox();
    final existing = box.get(speciesId);
    if (existing == null) {
      await box.put(speciesId, MonsterCodex(
        speciesId: speciesId,
        discoveredAt: DateTime.now().toUtc(),
        defeatedCount: 1,
      ));
    } else {
      await box.put(speciesId, MonsterCodex(
        speciesId: existing.speciesId,
        discoveredAt: existing.discoveredAt,
        defeatedCount: existing.defeatedCount + 1,
        notes: existing.notes,
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
