import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/hive/boxes.dart';
import '../../data/models/player_profile.dart';
import '../../game/battle/battle_engine.dart';
import '../../game/services/seed_pipeline.dart';
import '../../game/skills/skill.dart';
import '../../game/skills/skill_catalog.dart';
import '../../models/sprite_attack.dart';
import '../../game/services/monster_image_service.dart';
import '../../services/inventory_service.dart';
import '../../services/drop_table.dart';

  class BattleState {
  final String? battleId;
  final String? enemyName;
  final int playerHp;
  final int playerMaxHp;
  final int enemyHp;
  final int enemyMaxHp;
  final List<String> skills; // names
  final List<int> skillCooldowns; // remaining per skill index
  final List<String> sprites; // names
  final List<int> spriteCooldowns;
  final List<Map<String, dynamic>> quickItems; // [{'id','label','qty'}]
  final List<String> log;
  final String backgroundAsset;
  final String? enemyAssetPath;
  final int actionSeq; // increments per action for UI animations
  final Map<String, dynamic>? lastAction; // {attacker:'player'|'enemy', melee:bool, element:String?, target:'enemy'|'player' }
  final Map<String, int> playerStatuses; // key->duration
  final Map<String, int> enemyStatuses; // key->duration
  final String? result; // 'win' | 'loss' | null
  final int turnCount;
  final int xpGained;
  final bool leveledUp;
  final List<Map<String, dynamic>> winLoot;
  final bool codexAdded;
  final bool echoDropped;
  const BattleState({
    this.battleId,
    this.enemyName,
    this.playerHp = 0,
    this.playerMaxHp = 0,
    this.enemyHp = 0,
    this.enemyMaxHp = 0,
    this.skills = const [],
    this.skillCooldowns = const [],
    this.sprites = const [],
    this.spriteCooldowns = const [],
    this.quickItems = const [],
    this.log = const [],
    this.backgroundAsset = 'assets/images/backgrounds/ChatGPT Image Sep 8, 2025, 01_02_37 PM.png',
    this.result,
    this.turnCount = 0,
    this.enemyAssetPath,
    this.actionSeq = 0,
    this.lastAction,
    this.playerStatuses = const {},
    this.enemyStatuses = const {},
    this.xpGained = 0,
    this.leveledUp = false,
    this.winLoot = const [],
    this.codexAdded = false,
    this.echoDropped = false,
  });

  BattleState copyWith({
    String? battleId,
    String? enemyName,
    int? playerHp,
    int? playerMaxHp,
    int? enemyHp,
    int? enemyMaxHp,
    List<String>? skills,
    List<int>? skillCooldowns,
    List<String>? sprites,
    List<int>? spriteCooldowns,
    List<Map<String, dynamic>>? quickItems,
    List<String>? log,
    String? backgroundAsset,
    String? result,
    int? turnCount,
    String? enemyAssetPath,
    int? actionSeq,
    Map<String, dynamic>? lastAction,
    Map<String, int>? playerStatuses,
    Map<String, int>? enemyStatuses,
    int? xpGained,
    bool? leveledUp,
    List<Map<String, dynamic>>? winLoot,
    bool? codexAdded,
    bool? echoDropped,
  }) => BattleState(
      battleId: battleId ?? this.battleId,
      enemyName: enemyName ?? this.enemyName,
      playerHp: playerHp ?? this.playerHp,
      playerMaxHp: playerMaxHp ?? this.playerMaxHp,
      enemyHp: enemyHp ?? this.enemyHp,
      enemyMaxHp: enemyMaxHp ?? this.enemyMaxHp,
      skills: skills ?? this.skills,
      skillCooldowns: skillCooldowns ?? this.skillCooldowns,
      sprites: sprites ?? this.sprites,
      spriteCooldowns: spriteCooldowns ?? this.spriteCooldowns,
      quickItems: quickItems ?? this.quickItems,
      log: log ?? this.log,
      backgroundAsset: backgroundAsset ?? this.backgroundAsset,
      result: result ?? this.result,
      turnCount: turnCount ?? this.turnCount,
      enemyAssetPath: enemyAssetPath ?? this.enemyAssetPath,
      actionSeq: actionSeq ?? this.actionSeq,
      lastAction: lastAction ?? this.lastAction,
      playerStatuses: playerStatuses ?? this.playerStatuses,
      enemyStatuses: enemyStatuses ?? this.enemyStatuses,
      xpGained: xpGained ?? this.xpGained,
      leveledUp: leveledUp ?? this.leveledUp,
      winLoot: winLoot ?? this.winLoot,
      codexAdded: codexAdded ?? this.codexAdded,
      echoDropped: echoDropped ?? this.echoDropped,
    );
}

final battleProvider = StateNotifierProvider.autoDispose<BattleNotifier, BattleState>((ref) => BattleNotifier());

class BattleNotifier extends StateNotifier<BattleState> {
  BattleNotifier() : super(const BattleState());

  late BattleEngine _engine;
  late Combatant _player;
  late Combatant _enemy;
  List<Skill> _playerSkills = const [];
  List<BattleSpriteAction> _playerSprites = const [];

  Future<void> init({required String battleId}) async {
    // Reset state to avoid leaking result/action from previous battle
    state = const BattleState();
    // Build stats
    final profile = profileBox().values.isNotEmpty ? profileBox().values.first : PlayerProfile(id: 'p', classKey: 'Sage');
    final classKey = profile.classKey;
    const int baseHp = 60; const int baseAtk = 4; const int baseDef = 2;
    final mods = _classMods(classKey);
    int curHp = baseHp;
    try { curHp = (playerMetaBox().get('hp') as int?) ?? baseHp; } catch (_) {}
    final maxHp = baseHp + mods[0];
    final pStats = BattleStats(maxHp: maxHp, hp: curHp.clamp(1, maxHp), atk: baseAtk + mods[1], def: baseDef + mods[2]);
    // Load equipped sprites for actions
    final slots = (equipmentBox().get('sprite_slots') as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString()));
    final spriteIds = <String?>[
      (slots?['sprite1']?.toString()) ?? _readSlot('sprite1'),
      (slots?['sprite2']?.toString()) ?? _readSlot('sprite2'),
    ];
    final sprites = <BattleSpriteAction>[];
    for (final id in spriteIds) {
      if (id == null || id.isEmpty) continue;
      try {
        final inst = seedInstanceBox().values.firstWhere((e) => e.instanceId == id);
        if (inst.attacks.isNotEmpty) {
          final a = inst.attacks.first; // single attack for now
          final name = (a['name'] ?? 'Sprite').toString();
          final power = (a['power'] ?? 12) as int;
          final cd = (a['cooldown'] ?? (a['duration'] ?? 3)) as int;
          final sa = SpriteAttack(name: name, description: '', power: power, durationTurns: cd);
          sprites.add(BattleEngine.fromSpriteAttack(sa));
        }
      } catch (_) {}
    }

    _playerSkills = SkillCatalog.forClass(classKey);
    // Deduplicate sprite actions by name, keeping higher power (tie-breaker: lower cooldown)
    final byName = <String, BattleSpriteAction>{};
    for (final a in sprites) {
      final e = byName[a.name];
      if (e == null || a.power > e.power || (a.power == e.power && a.cooldown < e.cooldown)) {
        byName[a.name] = a;
      }
    }
    _playerSprites = byName.values.toList();
    _player = Combatant(name: 'You', stats: pStats, skills: _playerSkills, spriteActions: _playerSprites);
    // Apply any pending pre-battle buffs from meta
    try {
      final buffsRaw = (playerMetaBox().get('pendingBuffs') as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? const <Map<String, dynamic>>[];
      for (final b in buffsRaw) {
        final k = b['key']?.toString() ?? '';
        final m = int.tryParse(b['magnitude']?.toString() ?? '0') ?? 0;
        final d = int.tryParse(b['duration']?.toString() ?? '0') ?? 0;
        if (k.isNotEmpty && m > 0 && d >= 0) {
          _engine.applyStatus(_player, k, m, d);
        }
      }
      await playerMetaBox().put('pendingBuffs', <Map<String, dynamic>>[]);
    } catch (_) {}

    // Enemy from battle ticket/seed
    String enemyName = 'Monster';
    String enemyElement = 'shadow';
    String enemyType = 'beast';
    final b = battleBox().get(battleId);
    if (b != null) {
      final ticket = encounterTicketBox().get(b.ticketId);
      if (ticket != null) {
        try {
          final snap = ticket.seedSnapshot;
          final name = (snap['displayName'] ?? '').toString();
          if (name.isNotEmpty) enemyName = name;
          final el = (snap['element'] ?? '').toString();
          if (el.isNotEmpty) enemyElement = el;
          final typ = (snap['type'] ?? '').toString();
          if (typ.isNotEmpty) enemyType = typ;
        } catch (_) {}
      }
    }
    const int eHp = 50; const int eAtk = 3; const int eDef = 0; // slightly easier enemy
    _enemy = Combatant(name: enemyName, stats: BattleStats(maxHp: eHp, hp: eHp, atk: eAtk, def: eDef), skills: _enemySkills());
    _engine = BattleEngine(player: _player, enemy: _enemy);

    // Background from asset manifest (random pick)
    final bg = await _pickBackground();
    // Enemy image path
    String? enemyAssetPath;
    try {
      enemyAssetPath = await MonsterImageService().resolveImagePath(displayName: enemyName, element: enemyElement, type: enemyType);
    } catch (_) {}

    // Quick items: auto-refill before building list
    await _refillQuickSlots();
    final qi = _loadQuickItems();

    state = state.copyWith(
      battleId: battleId,
      enemyName: enemyName,
      playerHp: _player.stats.hp,
      playerMaxHp: _player.stats.maxHp,
      enemyHp: _enemy.stats.hp,
      enemyMaxHp: _enemy.stats.maxHp,
      skills: _playerSkills.map((s) => s.name).toList(),
      skillCooldowns: List.filled(_playerSkills.length, 0),
      sprites: _playerSprites.map((s) => s.name).toList(),
      spriteCooldowns: List.filled(_playerSprites.length, 0),
      backgroundAsset: bg,
      enemyAssetPath: enemyAssetPath,
      quickItems: qi,
      log: ['A wild $enemyName appears!'],
      turnCount: 0,
      playerStatuses: Map.fromEntries(_player.stats.statuses.entries.map((e)=> MapEntry(e.key, e.value.duration))),
      enemyStatuses: Map.fromEntries(_enemy.stats.statuses.entries.map((e)=> MapEntry(e.key, e.value.duration))),
    );
  }

  List<int> _classMods(String classKey) {
    switch (classKey) {
      case 'Warden': return [8, 0, 1]; // +HP, +ATK, +DEF
      case 'Sentinel': return [5, 0, 1];
      case 'Trickster': return [0, 1, 0];
      case 'Shadow': return [0, 1, 0];
      case 'Artificer': return [0, 1, 0];
      case 'Empath': return [5, 0, 0];
      case 'Oracle': return [0, 0, 1];
      // Casters (Sage, Seer, Alchemist) keep base small stats for balance
      default: return [0, 0, 0];
    }
  }

  void useSkill(int index) {
    if (index < 0 || index >= _playerSkills.length) return;
    final s = _playerSkills[index];
    final log = _engine.takeTurnBySkill(_player, _enemy, s);
    final element = _weaponElement();
    _afterPlayerAction(log, lastAction: {
      'attacker': 'player',
      'target': 'enemy',
      'melee': s.melee,
      'element': element,
    });
  }

  void useSprite(int index) {
    if (index < 0 || index >= _playerSprites.length) return;
    final a = _playerSprites[index];
    final log = _engine.takeTurnBySprite(_player, _enemy, a);
    // Try derive element from the sprite instance if possible (not guaranteed here)
    String? elem;
    try {
      final slots = (equipmentBox().get('sprite_slots') as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString()));
      final ids = [slots?['sprite1']?.toString(), slots?['sprite2']?.toString()];
      for (final id in ids) {
        if (id == null) continue;
        final inst = seedInstanceBox().values.firstWhere((e) => e.instanceId == id);
        final name = (inst.attacks.isNotEmpty ? (inst.attacks.first['name'] ?? '').toString() : '');
        if (name == a.name) { elem = (inst.seedSnapshot['element'] ?? '').toString(); break; }
      }
    } catch (_) {}
    _afterPlayerAction(log, lastAction: {
      'attacker': 'player',
      'target': 'enemy',
      'melee': false,
      'element': elem,
    });
  }

  void useItem(int quickIndex) {
    if (quickIndex < 0 || quickIndex >= state.quickItems.length) return;
    final item = state.quickItems[quickIndex];
    final id = item['id'] as String;
    final type = item['type'] as String? ?? 'potion_small';
    final logs = <String>[];
    bool consumed = false;
    // Determine effect direction and apply
    // Default: positive effects to player, negative to enemy
    bool targetsEnemy = false;
    switch (type) {
      case 'potion_small':
        _player.stats.hp = (_player.stats.hp + 20).clamp(0, _player.stats.maxHp);
        logs.add('You used Potion (+20HP).');
        consumed = true;
        break;
      case 'fruit':
        _player.stats.hp = (_player.stats.hp + 10).clamp(0, _player.stats.maxHp);
        logs.add('You ate Fruit (+10HP).');
        consumed = true;
        break;
      case 'food':
        _player.stats.hp = (_player.stats.hp + 15).clamp(0, _player.stats.maxHp);
        logs.add('You ate Snack (+15HP).');
        consumed = true;
        break;
      case 'poison_small':
        _engine.applyStatus(_enemy, 'def-', 2, 2);
        logs.add('Enemy defense fell!');
        consumed = true;
        targetsEnemy = true;
        break;
      case 'buff_small':
        _engine.applyStatus(_player, 'atk+', 1, 2);
        logs.add('Your attack rose!');
        consumed = true;
        break;
      default:
        break;
    }
    if (consumed) {
      if (InventoryService.consume(id)) {
        final qi = _loadQuickItems();
        state = state.copyWith(
          playerHp: _player.stats.hp,
          quickItems: qi,
          log: [...state.log, ...logs],
          playerStatuses: Map.fromEntries(_player.stats.statuses.entries.map((e)=> MapEntry(e.key, e.value.duration))),
          enemyStatuses: Map.fromEntries(_enemy.stats.statuses.entries.map((e)=> MapEntry(e.key, e.value.duration))),
          actionSeq: state.actionSeq + 1,
          lastAction: {
            'attacker':'player',
            'target': targetsEnemy ? 'enemy' : 'player',
            'melee': false,
            'element': null
          },
        );
        // Using an item counts as action -> enemy turn after short delay
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (_enemy.isAlive() && (state.result == null)) {
            _enemyTurn();
          }
        });
      }
    }
  }

  void _afterPlayerAction(List<String> logs, {Map<String, dynamic>? lastAction}) {
    state = state.copyWith(
      enemyHp: _enemy.stats.hp,
      playerHp: _player.stats.hp,
      log: [...state.log, ...logs],
      playerStatuses: Map.fromEntries(_player.stats.statuses.entries.map((e)=> MapEntry(e.key, e.value.duration))),
      enemyStatuses: Map.fromEntries(_enemy.stats.statuses.entries.map((e)=> MapEntry(e.key, e.value.duration))),
      actionSeq: state.actionSeq + 1,
      lastAction: lastAction,
    );
    if (_enemy.isAlive()) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (_enemy.isAlive() && (state.result == null)) {
          _enemyTurn();
        }
      });
    } else {
      _finish('win');
    }
  }

  void _enemyTurn() {
    final skill = _engine.chooseEnemySkill();
    final logs = _engine.takeTurnBySkill(_enemy, _player, skill);
    _engine.endTurn();
    state = state.copyWith(
      playerHp: _player.stats.hp,
      enemyHp: _enemy.stats.hp,
      log: [...state.log, ...logs],
      skillCooldowns: _playerSkills.map((s) => _player.cooldowns[s.id] ?? 0).toList(),
      spriteCooldowns: _playerSprites.map((a) => _player.cooldowns[a.id] ?? 0).toList(),
      turnCount: state.turnCount + 1,
      playerStatuses: Map.fromEntries(_player.stats.statuses.entries.map((e)=> MapEntry(e.key, e.value.duration))),
      enemyStatuses: Map.fromEntries(_enemy.stats.statuses.entries.map((e)=> MapEntry(e.key, e.value.duration))),
      actionSeq: state.actionSeq + 1,
      lastAction: {'attacker':'enemy','target':'player','melee': skill.melee, 'element': null},
    );
    if (!_player.isAlive()) {
      _finish('loss');
    }
  }

  Future<void> _finish(String result) async {
    final id = state.battleId;
    String? speciesId;
    bool preCodexExists = false;
    bool leveledUpLocal = false;
    if (id != null) {
      try {
        final b = battleBox().get(id);
        speciesId = b?.speciesId;
        if (speciesId != null) {
          preCodexExists = (monsterCodexBox().get(speciesId) != null);
        }
      } catch (_) {}
    }
    if (id != null) {
      try {
        await BattleServiceImpl(codex: CodexServiceImpl(), echo: EchoServiceImpl()).resolve(
          battleId: id,
          result: result,
          turnCount: state.turnCount + 1,
          flawless: _player.stats.hp == _player.stats.maxHp,
        );
      } catch (_) {}
    }
    if (result == 'win') {
      // Drop simple loot
      final loot = _dropLoot();
      // XP gain
      try {
        final box = profileBox();
        if (box.values.isNotEmpty) {
          final p = box.values.first;
          int level = p.level;
          const int gain = 10;
          int xp = p.xp + gain; // small gain
          int target = level * 20;
          bool leveled = false;
          while (xp >= target) {
            xp -= target; level += 1; target = level * 20;
            leveled = true;
          }
          await box.put(p.id, PlayerProfile(id: p.id, classKey: p.classKey, level: level, xp: xp, unlockedSkills: p.unlockedSkills, cosmetics: p.cosmetics, titles: p.titles));
          leveledUpLocal = leveled;
          // Detect codex addition and echo dropped
          bool codexAdded = false;
          bool echoDropped = false;
          try {
            if (speciesId != null) {
              final post = monsterCodexBox().get(speciesId);
              codexAdded = !preCodexExists && (post != null);
            }
          } catch (_) {}
          try {
            echoDropped = resonantEchoBox().values.any((e) => e.battleId == (id ?? ''));
          } catch (_) {}
          state = state.copyWith(
            xpGained: gain,
            leveledUp: leveled,
            winLoot: loot,
            codexAdded: codexAdded,
            echoDropped: echoDropped,
          );
        }
      } catch (_) {}
    }
    // Persist HP back to meta
    try {
      if (leveledUpLocal) {
        // Heal to full on level up
        playerMetaBox().put('hp', _computeMaxHpForPlayer());
      } else {
        playerMetaBox().put('hp', _player.stats.hp);
      }
    } catch (_) {}
    state = state.copyWith(result: result);
  }

  int _computeMaxHpForPlayer() {
    const int baseHp = 60;
    String classKey = 'Sage';
    try {
      final vals = profileBox().values;
      if (vals.isNotEmpty) classKey = vals.first.classKey;
    } catch (_) {}
    int mod = 0;
    switch (classKey) {
      case 'Warden': mod = 8; break;
      case 'Sentinel': mod = 5; break;
      case 'Empath': mod = 5; break;
      default: mod = 0; break;
    }
    return baseHp + mod;
  }

  List<Map<String, dynamic>> _dropLoot() {
    final seed = DateTime.now().microsecondsSinceEpoch;
    final rolled = DropTable.roll(luckSeed: seed);
    for (final it in rolled) {
      InventoryService.add(it['type'] as String, qty: (it['qty'] as int?) ?? 1);
    }
    return rolled;
  }

  List<Map<String, dynamic>> _loadQuickItems() {
    var qs = InventoryService.quickSlots();
    final out = <Map<String, dynamic>>[];
    for (final id in qs.take(4)) {
      final it = InventoryService.getById(id);
      if (it == null) continue;
      out.add({'id': id, 'type': it['type'], 'label': ItemEffects.label(it['type']), 'qty': it['qty']});
    }
    return out;
  }

  Future<void> _refillQuickSlots() async {
    // Remove invalid/empty items from current quick slots, then fill up to 4 from inventory
    var slots = InventoryService.quickSlots();
    final inv = InventoryService.inventory();
    bool hasId(String id) => inv.any((e) => e['id'] == id && (e['qty'] as int? ?? 0) > 0);
    // Clean existing
    slots = slots.where((id) => id.isNotEmpty && hasId(id)).toList();
    // Build candidate pool in priority order (healing first)
    List<Map<String, dynamic>> pick(List<String> types) =>
        inv.where((e) => (e['qty'] as int? ?? 0) > 0 && (types.contains(e['type'])) && !slots.contains(e['id'])).toList();
    final healingOrder = ['potion_small', 'food', 'fruit'];
    final candidates = <Map<String, dynamic>>[
      ...pick(healingOrder),
      ...inv.where((e) => (e['qty'] as int? ?? 0) > 0 && !slots.contains(e['id']) && !healingOrder.contains(e['type'])),
    ];
    for (final it in candidates) {
      if (slots.length >= 4) break;
      final id = it['id'] as String;
      slots.add(id);
    }
    InventoryService.setQuickSlots(slots);
  }

  List<Skill> _enemySkills() {
    // Enemy uses generic basic/special to keep balance
    return const [
      Skill(id:'Enemy.basic', name:'Claw', description:'A crude strike.', type:SkillType.basic, power:3, cooldown:0),
      Skill(id:'Enemy.special', name:'Rend', description:'A heavy tear.', type:SkillType.special, power:6, cooldown:4),
    ];
  }

  String? _weaponElement() {
    try {
      final eq = equipmentBox().get('slots') as Map?;
      final w = (eq?['weapon'] as Map?)?.map((k, v) => MapEntry(k.toString(), v));
      return w?['element']?.toString();
    } catch (_) { return null; }
  }

  Future<String> _pickBackground() async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> map = jsonDecode(manifest);
      final keys = map.keys.where((p) => p.startsWith('assets/images/backgrounds/')).toList();
      if (keys.isNotEmpty) {
        keys.sort();
        final idx = DateTime.now().microsecondsSinceEpoch % keys.length;
        return keys[idx];
      }
    } catch (_) {}
    // No background available in manifest; return empty and let UI show plain backdrop
    return '';
  }

  String? _readSlot(String key) {
    try {
      final slots = equipmentBox().get('slots') as Map?;
      final id = (slots?[key])?.toString();
      return id;
    } catch (_) { return null; }
  }
}
