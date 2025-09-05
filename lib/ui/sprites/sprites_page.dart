import 'package:flutter/material.dart';
import '../../models/sprite_model.dart';
import '../../models/sprite_attack.dart';
import '../../services/sprite_palette.dart';
import '../../data/hive/boxes.dart';
import '../../game/models/seed_instance.dart';
import '../../game/models/journal_seed_meta.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = seedInstanceBox().values.toList();
    final metas = journalSeedMetaBox().values.toList();
    final out = <SpriteModel>[];
    for (final inst in list) {
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
    return SpriteModel(id: id, seedName: name, tier: 0, rarity: rarity, hue: hue, argbRamp: ramp, attack: atk, createdAt: inst.createdAt);
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
            onEquip: () {
              if (widget.selectMode && _selected != null) {
                Navigator.pop(context, _selected);
              }
            },
            onFuse: () {},
          ),
        ],
      ),
    );
  }
}
