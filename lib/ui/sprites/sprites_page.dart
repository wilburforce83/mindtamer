import 'package:flutter/material.dart';
import '../../models/sprite_model.dart';
import '../../models/sprite_attack.dart';
import '../../services/sprite_palette.dart';
import '../../services/fusion_service.dart';
import '../../data/hive/boxes.dart';
import '../../game/models/seed_instance.dart';
import '../../game/models/journal_seed_meta.dart';
import '../../game/models/summons_inventory.dart';
import 'package:uuid/uuid.dart';
import '../../data/repos/sprite_slots_repo.dart';
import 'sprite_grid.dart';
import 'sprite_details_panel.dart';

class SpritesPage extends StatefulWidget {
  final bool selectMode;
  const SpritesPage({super.key, this.selectMode = false});
  @override
  State<SpritesPage> createState() => _SpritesPageState();
}

class _SpritesPageState extends State<SpritesPage> {
  List<SpriteModel> _items = [];
  SpriteModel? _selected;
  String? _selTitle;
  String? _selPrimaryTag;
  bool _fusing = false;
  SpriteModel? _fusePrimary;
  final Map<String, SeedInstance> _instById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  SpriteModel _strongerOf(SpriteModel a, SpriteModel b) {
    int score(SpriteModel s) => s.rarity * 100 + s.attack.power + s.tier * 10;
    return score(a) >= score(b) ? a : b;
  }

  SpriteModel _fuseSprites(SpriteModel a, SpriteModel b) {
    final service = FusionService();
    final stronger = _strongerOf(a, b);
    final weaker = stronger.id == a.id ? b : a;
    var fused = service.fuse(stronger, weaker);
    // Generate a concise new name for the fused sprite
    final mergedElem = _blendElement(stronger.element, weaker.element) ?? (stronger.element ?? weaker.element);
    final newName = _newFusedName(stronger, weaker, mergedElem: mergedElem);
    // Preserve stronger's identity for in-memory display; persistence will create a new instance
    fused = SpriteModel(
      id: stronger.id,
      seedName: newName,
      tier: fused.tier,
      rarity: fused.rarity,
      hue: fused.hue,
      argbRamp: fused.argbRamp,
      attack: fused.attack,
      createdAt: DateTime.now(),
      element: mergedElem,
      colorHex: stronger.colorHex ?? weaker.colorHex,
    );
    return fused;
  }

  String? _blendElement(String? ea, String? eb) {
    final a = (ea ?? '').toLowerCase();
    final b = (eb ?? '').toLowerCase();
    if (a.isEmpty && b.isEmpty) return null;
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    if (a == b) return a;
    final pair = ([a, b]..sort()).join('+');
    const combos = <String, String>{
      'light+shadow': 'twilight',
      'fire+water': 'steam',
      'air+water': 'mist',
      'fire+air': 'emberwind',
      'metal+nature': 'thornsteel',
      'metal+shadow': 'obsidian',
      'fire+metal': 'forge',
      'light+nature': 'bloomlight',
      'shadow+water': 'abyss',
      'nature+water': 'verdtide',
      'air+light': 'halo',
      'air+shadow': 'gloomwind',
    };
    return combos[pair] ?? a; // default to first element
  }

  String _newFusedName(SpriteModel a, SpriteModel b, {String? mergedElem}) {
    List<String> parts(String s) => s.split(RegExp(r"\s+")).where((e) => e.isNotEmpty).toList();
    final pa = parts(a.seedName);
    final pb = parts(b.seedName);
    final first = pa.isNotEmpty ? pa.first : 'Sprite';
    final lastB = pb.isNotEmpty ? pb.last : (pa.length > 1 ? pa.last : 'Core');
    const suffixes = ['Prime','Ascendant','Nova','Pulse','Arc','Veil','Bloom'];
    final idx = (a.id.hashCode ^ b.id.hashCode).abs() % suffixes.length;
    // Pick among concise patterns
    if ((idx % 4) == 0 && (mergedElem != null && mergedElem.isNotEmpty)) {
      // Element-led names where suitable
      final cap = mergedElem[0].toUpperCase() + mergedElem.substring(1);
      return '$cap $first';
    }
    if ((idx % 4) == 1) return '$first ${suffixes[idx]}';
    if ((idx % 4) == 2) return '$first $lastB';
    return '${suffixes[idx]} $first';
  }

  Future<void> _persistFusion(SpriteModel a, SpriteModel b, SpriteModel fused) async {
    final instA = _instById[a.id];
    final instB = _instById[b.id];
    if (instA == null || instB == null) return;
    final newId = const Uuid().v4();
    final snap = Map<String, dynamic>.from(instA.seedSnapshot);
    snap['displayName'] = fused.seedName;
    String rarityStrFromInt(int r) => switch (r) { 1 => 'uncommon', 2 => 'rare', 3 => 'epic', 4 => 'legendary', _ => 'common' };
    snap['rarity'] = rarityStrFromInt(fused.rarity);
    if (fused.element != null && fused.element!.isNotEmpty) snap['element'] = fused.element;
    if (fused.colorHex != null && fused.colorHex!.isNotEmpty) snap['colorHex'] = fused.colorHex;
    final attacks = <Map<String, dynamic>>[
      { 'name': fused.attack.name, 'power': fused.attack.power, 'cooldown': fused.attack.durationTurns }
    ];
    snap['tier'] = fused.tier;
    final instNew = SeedInstance(
      instanceId: newId,
      speciesId: instA.speciesId,
      createdAt: DateTime.now().toUtc(),
      source: 'fusion',
      seedHash: 'fused:${instA.seedHash.substring(0,6)}:${instB.seedHash.substring(0,6)}',
      seedSnapshot: snap,
      stats: Map<String, int>.from(instA.stats),
      attacks: attacks,
      state: 'inventory',
    );
    await seedInstanceBox().put(newId, instNew);
    await summonsInventoryBox().put(newId, SummonsInventoryItem(instanceId: newId));
    await seedInstanceBox().delete(instA.instanceId);
    await seedInstanceBox().delete(instB.instanceId);
    await summonsInventoryBox().delete(instA.instanceId);
    await summonsInventoryBox().delete(instB.instanceId);
    try {
      final slotsRepo = SpriteSlotsRepoImpl();
      final current = await slotsRepo.getAll();
      if (current['sprite1'] == instA.instanceId || current['sprite1'] == instB.instanceId) {
        await slotsRepo.set('sprite1', null);
      }
      if (current['sprite2'] == instA.instanceId || current['sprite2'] == instB.instanceId) {
        await slotsRepo.set('sprite2', null);
      }
    } catch (_) {}
    _instById.remove(instA.instanceId);
    _instById.remove(instB.instanceId);
    _instById[newId] = instNew;
    setState(() {
      _items.removeWhere((x) => x.id == instA.instanceId || x.id == instB.instanceId);
      _items.insert(0, SpriteModel(
        id: newId,
        seedName: fused.seedName,
        tier: fused.tier,
        rarity: fused.rarity,
        hue: fused.hue,
        argbRamp: fused.argbRamp,
        attack: fused.attack,
        createdAt: DateTime.now(),
        element: fused.element,
        colorHex: fused.colorHex,
        fused: true,
      ));
    });
  }

  Future<void> _load() async {
    final list = seedInstanceBox().values.toList();
    final metas = journalSeedMetaBox().values.toList();
    final out = <SpriteModel>[];
    for (final inst in list) {
      _instById[inst.instanceId] = inst;
      out.add(_fromInstance(inst));
    }
    setState(() { _items = out; });
    if (_items.isNotEmpty) _onSelect(_items.first, metas);
  }

  SpriteModel _fromInstance(SeedInstance inst) {
    final seed = inst.seedHash;
    final id = inst.instanceId;
    final ramp = SpritePalette.pickRampForSeed(seed);
    final hue = (seed.hashCode & 0x7fffffff) % 360;
    final rarityStr = (inst.seedSnapshot['rarity'] ?? 'common').toString();
    final rarity = switch (rarityStr) { 'uncommon' => 1, 'rare' => 2, 'epic' => 3, 'legendary' => 4, _ => 0 };
    final element = (inst.seedSnapshot['element'] ?? '').toString();
    final colorHex = (inst.seedSnapshot['colorHex'] ?? '').toString();
    String atkName = 'Sprite Attack';
    int power = 30;
    int duration = 2;
    if (inst.attacks.isNotEmpty) {
      final a = inst.attacks.first;
      atkName = (a['name'] ?? atkName).toString();
      power = (a['power'] ?? power) as int;
      duration = (a['cooldown'] ?? duration) as int; // reusing for demo
    }
    final atk = SpriteAttack(name: atkName, description: 'Fires a focused burst for $power power over $duration turns.', power: power, durationTurns: duration);
    final name = (inst.seedSnapshot['displayName'] ?? inst.speciesId).toString();
    final tier = (inst.seedSnapshot['tier'] is int)
        ? (inst.seedSnapshot['tier'] as int)
        : int.tryParse((inst.seedSnapshot['tier'] ?? '0').toString()) ?? 0;
    final isFused = (inst.source.toLowerCase() == 'fusion');
    return SpriteModel(
      id: id,
      seedName: name,
      tier: tier,
      rarity: rarity,
      hue: hue,
      argbRamp: ramp,
      attack: atk,
      createdAt: inst.createdAt,
      element: element.isEmpty? null: element,
      colorHex: colorHex.isEmpty? null: colorHex,
      fused: isFused,
    );
  }

  void _onSelect(SpriteModel s, List<JournalSeedMeta> metas) {
    final m = metas.firstWhere((e) => e.seedSnapshot['displayName'] == s.seedName, orElse: () => JournalSeedMeta(entryId: -1, seedHash: '', seedVersion: '', seedSnapshot: const {}, seedRouting: 'none'));
    setState(() {
      _selected = s;
      _selTitle = m.title;
      _selPrimaryTag = m.primaryTag;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metas = journalSeedMetaBox().values.toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.selectMode ? 'Select Sprite' : 'Sprites')),
      body: Column(
        children: [
          Expanded(
            child: SpriteGrid(
              sprites: _items,
              onSelect: (s) => _onSelect(s, metas),
            ),
          ),
          SpriteDetailsPanel(
            selected: _selected,
            seedTitle: _selTitle,
            primaryTag: _selPrimaryTag,
            fuseMode: _fusing,
            fusePrimary: _fusePrimary,
            onEquip: () {
              if (widget.selectMode && _selected != null) {
                Navigator.pop(context, _selected);
              }
            },
            onFuse: () async {
              if (!_fusing) {
                // Begin fusion
                if (_selected == null) return;
                setState(() { _fusing = true; _fusePrimary = _selected; });
              } else {
                // Execute fusion if a second sprite is selected
                final a = _fusePrimary; final b = _selected;
                if (a == null || b == null || a.id == b.id) return;
                final fused = _fuseSprites(a, b);
                final metas = journalSeedMetaBox().values.toList();
                // Choose source title: stronger of two seeds (by rarity, then attack power)
                final stronger = _strongerOf(a, b);
                final m = metas.firstWhere((e) => e.seedSnapshot['displayName'] == stronger.seedName, orElse: () => JournalSeedMeta(entryId: -1, seedHash: '', seedVersion: '', seedSnapshot: const {}, seedRouting: 'none'));
                await _persistFusion(a, b, fused);
                setState(() {
                  _fusing = false;
                  _fusePrimary = null;
                  _selected = _items.firstWhere((it) => it.seedName == fused.seedName, orElse: () => _items.first);
                  _selTitle = m.title;
                  _selPrimaryTag = m.primaryTag;
                });
              }
            },
            onCancel: () { setState(() { _fusing = false; _fusePrimary = null; }); },
          ),
        ],
      ),
    );
  }
}
