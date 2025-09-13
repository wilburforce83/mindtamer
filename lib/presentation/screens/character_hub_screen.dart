import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../widgets/gear_slot.dart';
import '../widgets/action_tile.dart';
import '../viewmodels/character_hub_vm.dart';
import '../../data/repos/encounters_repo.dart';
import '../../data/repos/equipment_repo.dart';
import '../../game/services/seed_pipeline.dart';
import '../widgets/game_scaffold.dart';
import 'dart:ui' as ui;
import '../../ui/sprites/sprites_page.dart';
import '../../models/sprite_model.dart';
import '../../services/sprite_generator.dart';
import '../../data/repos/sprite_slots_repo.dart';
import '../../data/hive/boxes.dart';
import '../../services/sprite_palette.dart';
import '../../game/models/seed_instance.dart';
import 'dart:async';
import '../../theme/colors.dart';
import '../../game/services/player_image_service.dart';

class CharacterHubScreen extends StatefulWidget {
  const CharacterHubScreen({super.key});
  @override
  State<CharacterHubScreen> createState() => _CharacterHubScreenState();
}

class _CharacterHubScreenState extends State<CharacterHubScreen> {
  late final CharacterHubVM vm;
  late final SpriteSlotsRepo spriteSlots;
  ui.Image? _spriteImg1;
  ui.Image? _spriteImg2;
  bool _selecting = false;
  SeedInstance? _inst1;
  SeedInstance? _inst2;
  StreamSubscription? _equipSub;
  ui.Image? _playerImage;
  String? _playerAssetPath; // raw asset fallback

  @override
  void initState() {
    super.initState();
    vm = context.read<CharacterHubVM>();
    spriteSlots = context.read<SpriteSlotsRepo>();
    vm.load();
    _loadEquippedSprites();
    _refreshPlayerImage();
    // Refresh when equipment/sprite slots change
    _equipSub = equipmentBox().watch().listen((event) {
      if (!mounted) return;
      _loadEquippedSprites();
      _refreshPlayerImage();
    });
  }

  Future<void> _loadEquippedSprites() async {
    final slots = await spriteSlots.getAll();
    final id1 = slots['sprite1'];
    final id2 = slots['sprite2'];
    SeedInstance? inst1;
    SeedInstance? inst2;
    if (id1 != null && id1.isNotEmpty) {
      try {
        inst1 = seedInstanceBox().values.firstWhere((e) => e.instanceId == id1);
      } catch (_) {
        try {
          inst1 = seedInstanceBox().get(id1);
        } catch (_) {}
      }
    }
    if (id2 != null && id2.isNotEmpty) {
      try {
        inst2 = seedInstanceBox().values.firstWhere((e) => e.instanceId == id2);
      } catch (_) {
        try {
          inst2 = seedInstanceBox().get(id2);
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() {
      _inst1 = inst1;
      _inst2 = inst2;
    });
    // Generate images for any found instances
    final gen = SpriteGenerator();
    if (inst1 != null) {
      final ramp = SpritePalette.pickRampForSeed(inst1.seedHash);
      final render = await gen.generate(inst1.seedHash, 0, ramp);
      if (mounted) setState(() => _spriteImg1 = render.staticFrame);
    }
    if (inst2 != null) {
      final ramp = SpritePalette.pickRampForSeed(inst2.seedHash);
      final render = await gen.generate(inst2.seedHash, 0, ramp);
      if (mounted) setState(() => _spriteImg2 = render.staticFrame);
    }
  }

  Future<void> _refreshPlayerImage() async {
    final svc = PlayerImageService();
    final img = await svc.renderCurrentPlayer();
    String? path;
    try {
      final meta = playerMetaBox();
      final cls = (profileBox().values.isNotEmpty)
          ? profileBox().values.first.classKey
          : (meta.get('class')?.toString() ?? 'Sage');
      final gender = (meta.get('gender')?.toString() ?? 'm');
      path = await PlayerImageService.resolveAssetPath(cls, gender);
      path ??= PlayerImageService.assetPathFor(cls, gender);
    } catch (_) {}
    if (!mounted) return;
    setState((){
      _playerImage = img;
      _playerAssetPath = path;
    });
  }

  Future<void> _pickSprite(int slot) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    final sel = await Navigator.of(context).push<SpriteModel>(
      MaterialPageRoute(builder: (_) => const SpritesPage(selectMode: true)),
    );
    if (sel != null) {
      final gen = SpriteGenerator();
      final render = await gen.generate(sel.seedName, sel.tier, sel.argbRamp);
      setState(() {
        if (slot == 1) {
          _spriteImg1 = render.staticFrame;
          try {
            _inst1 = seedInstanceBox()
                .values
                .firstWhere((e) => e.instanceId == sel.id);
          } catch (_) {}
          spriteSlots.set('sprite1', sel.id);
        } else {
          _spriteImg2 = render.staticFrame;
          try {
            _inst2 = seedInstanceBox()
                .values
                .firstWhere((e) => e.instanceId == sel.id);
          } catch (_) {}
          spriteSlots.set('sprite2', sel.id);
        }
      });
    }
    if (mounted) setState(() => _selecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CharacterHubVM>().state;

    // Title uses player name, centered
    String titleName = 'Adventurer';
    try {
      final n = playerMetaBox().get('name');
      if (n is String && n.trim().isNotEmpty) titleName = n.trim();
    } catch (_) {}

    return GameScaffold(
      title: titleName,
      centerTitle: true,
      body: RefreshIndicator(
        onRefresh: vm.refreshTickets,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HubBars(),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (ctx, c) {
                final w = c.maxWidth;
                // Use 30% of screen height for the character + slots area
                final viewH = MediaQuery.of(context).size.height;
                final double h = viewH * 0.35;
                final sideInset = w * 0.08;
                // Determine slot box size
                final desired = w < 420 ? 56.0 : 64.0;
                final double boxSize = desired;
                // Character box (square)
                const charWFactor = 0.42;
                double charSize = w * charWFactor;
                final maxCharByHeight = h -
                    (2 * boxSize) -
                    8; // leave small gap between top/bottom rows
                if (maxCharByHeight > 0 && maxCharByHeight < charSize) {
                  charSize = maxCharByHeight;
                }
                double vPos(int i, int count) =>
                    (h - boxSize) * (count <= 1 ? 0.0 : i / (count - 1));
                return SizedBox(
                  height: h,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Character center box
                      Container(
                        width: charSize,
                        height: charSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: _playerImage != null
                            ? RawImage(
                                image: _playerImage,
                                filterQuality: FilterQuality.none,
                                fit: BoxFit.contain,
                                width: charSize,
                                height: charSize,
                              )
                            : (_playerAssetPath != null
                                ? Image.asset(
                                    _playerAssetPath!,
                                    filterQuality: FilterQuality.none,
                                    fit: BoxFit.contain,
                                    width: charSize,
                                    height: charSize,
                                    errorBuilder: (_, __, ___) => Text('Character', style: Theme.of(context).textTheme.titleMedium),
                                  )
                                : Text('Character', style: Theme.of(context).textTheme.titleMedium)),
                      ),

                      // Top row center: head and neck aligned with top widgets
                      Positioned(
                        top: vPos(0, 4),
                        left: (w / 2) - boxSize - 8,
                        child: GearSlot(
                            slotId: 'head',
                            item: state.gear['head'],
                            onTap: () =>
                                context.push('/items', extra: {'slot': 'head'}),
                            size: boxSize),
                      ),
                      Positioned(
                        top: vPos(0, 4),
                        left: (w / 2) + 8,
                        child: GearSlot(
                            slotId: 'neck',
                            item: state.gear['neck'],
                            onTap: () =>
                                context.push('/items', extra: {'slot': 'neck'}),
                            size: boxSize),
                      ),

                      // Left column (top→bottom): chest, hands, legs, feet
                      Positioned(
                        top: vPos(0, 4),
                        left: sideInset,
                        child: GearSlot(
                            slotId: 'chest',
                            item: state.gear['chest'],
                            onTap: () => context
                                .push('/items', extra: {'slot': 'chest'}),
                            size: boxSize),
                      ),
                      Positioned(
                        top: vPos(1, 4),
                        left: sideInset,
                        child: GearSlot(
                            slotId: 'hands',
                            item: state.gear['hands'],
                            onTap: () => context
                                .push('/items', extra: {'slot': 'hands'}),
                            size: boxSize),
                      ),
                      Positioned(
                        top: vPos(2, 4),
                        left: sideInset,
                        child: GearSlot(
                            slotId: 'legs',
                            item: state.gear['legs'],
                            onTap: () =>
                                context.push('/items', extra: {'slot': 'legs'}),
                            size: boxSize),
                      ),
                      Positioned(
                        top: vPos(3, 4),
                        left: sideInset,
                        child: GearSlot(
                            slotId: 'feet',
                            item: state.gear['feet'],
                            onTap: () =>
                                context.push('/items', extra: {'slot': 'feet'}),
                            size: boxSize),
                      ),

                      // Right column (top→bottom): rings, weapon
                      Positioned(
                        top: vPos(0, 3),
                        right: sideInset,
                        child: GearSlot(
                            slotId: 'ringLeft',
                            item: state.gear['ringLeft'],
                            onTap: () => context
                                .push('/items', extra: {'slot': 'ringLeft'}),
                            size: boxSize),
                      ),
                      Positioned(
                        top: vPos(1, 3),
                        right: sideInset,
                        child: GearSlot(
                            slotId: 'ringRight',
                            item: state.gear['ringRight'],
                            onTap: () => context
                                .push('/items', extra: {'slot': 'ringRight'}),
                            size: boxSize),
                      ),
                      Positioned(
                        top: vPos(2, 3),
                        right: sideInset,
                        child: GearSlot(
                            slotId: 'weapon',
                            item: state.gear['weapon'],
                            onTap: () => context
                                .push('/items', extra: {'slot': 'weapon'}),
                            size: boxSize),
                      ),

                      // Sprite slots: bottom aligned, centered
                      Positioned(
                        top: h - boxSize,
                        left: (w / 2) - boxSize - 8,
                        child: SizedBox(
                          width: boxSize,
                          height: boxSize,
                          child: Stack(alignment: Alignment.center, children: [
                            GearSlot(
                                slotId: 'sprite1',
                                item: null,
                                onTap: () => _pickSprite(1),
                                size: boxSize),
                            if (_spriteImg1 != null)
                              IgnorePointer(
                                  ignoring: true,
                                  child: RawImage(
                                      image: _spriteImg1,
                                      filterQuality: FilterQuality.none,
                                      width: boxSize * 0.8,
                                      height: boxSize * 0.8)),
                          ]),
                        ),
                      ),
                      Positioned(
                        top: h - boxSize,
                        left: (w / 2) + 8,
                        child: SizedBox(
                          width: boxSize,
                          height: boxSize,
                          child: Stack(alignment: Alignment.center, children: [
                            GearSlot(
                                slotId: 'sprite2',
                                item: null,
                                onTap: () => _pickSprite(2),
                                size: boxSize),
                            if (_spriteImg2 != null)
                              IgnorePointer(
                                  ignoring: true,
                                  child: RawImage(
                                      image: _spriteImg2,
                                      filterQuality: FilterQuality.none,
                                      width: boxSize * 0.8,
                                      height: boxSize * 0.8)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Stats and Attacks panel
            const SizedBox(height: 12),
            _StatsAndAttacks(inst1: _inst1, inst2: _inst2),

            const SizedBox(height: 16),

            // Battle button above tiles
            FilledButton(
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: state.openTickets > 0
                  ? () async {
                      final encounters = context.read<EncountersRepo>();
                      final id = await encounters.getFirstOpenTicketId();
                      if (id == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('No open encounters.')));
                        return;
                      }
                      // Start battle and navigate to battle screen
                      try {
                        final battleId = await BattleServiceImpl(
                                codex: CodexServiceImpl(),
                                echo: EchoServiceImpl())
                            .start(id);
                        if (!context.mounted) return;
                        await context.push('/battle', extra: {'battleId': battleId});
                        if (!context.mounted) return;
                        await vm.refreshTickets();
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Battle flow not ready')));
                      }
                    }
                  : null,
              child: Text(state.openTickets > 0
                  ? 'Battle Now'
                  : 'No Battles Available'),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                ActionTile(label: 'Echoes', icon: Icons.graphic_eq, onTap: () => context.push('/echoes')),
                ActionTile(label: 'Fusion', icon: Icons.all_inclusive, onTap: () => context.push('/fusion')),
                ActionTile(label: 'Codex', icon: Icons.auto_stories, onTap: () => context.push('/codex')),
                ActionTile(label: 'Items', icon: Icons.backpack, onTap: () => context.push('/items')),
                ActionTile(label: 'Achievements', icon: Icons.emoji_events, onTap: () => context.push('/achievements')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Deprecated debug stub removed; use live battle flow via /battle.

  @override
  void dispose() {
    _equipSub?.cancel();
    super.dispose();
  }
}

class CharacterHubScope extends StatelessWidget {
  final Widget child;
  const CharacterHubScope({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<EncountersRepo>(create: (_) => EncountersRepoImpl()),
        Provider<EquipmentRepo>(create: (_) => EquipmentRepoImpl()),
        Provider<SpriteSlotsRepo>(create: (_) => SpriteSlotsRepoImpl()),
        ChangeNotifierProvider<CharacterHubVM>(
          create: (ctx) => CharacterHubVM(
            encounters: ctx.read<EncountersRepo>(),
            equipment: ctx.read<EquipmentRepo>(),
          ),
        ),
      ],
      child: child,
    );
  }
}

class _HubBars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int hp = 60; int maxHp = 60;
    try { hp = (playerMetaBox().get('hp') as int?) ?? 60; } catch (_) {}
    // Max HP simple baseline for now
    maxHp = 60;
    int level = 1; int xp = 0;
    try {
      final vals = profileBox().values;
      if (vals.isNotEmpty) { level = vals.first.level; xp = vals.first.xp; }
    } catch (_) {}
    final nextXp = level * 20; // small scale
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HubStatBar(label: 'HP', current: hp, max: maxHp, color: Colors.redAccent),
        const SizedBox(height: 6),
        _HubStatBar(label: 'XP L$level', current: xp, max: nextXp, color: Colors.blueAccent),
      ],
    );
  }
}

class _HubStatBar extends StatelessWidget {
  final String label; final int current; final int max; final Color color;
  const _HubStatBar({required this.label, required this.current, required this.max, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      height: 18,
      child: Stack(children:[
        Container(decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant))),
        FractionallySizedBox(widthFactor: pct, child: Container(color: color.withValues(alpha: 0.85))),
        Positioned.fill(child: Center(child: Text('$label: $current/$max', style: Theme.of(context).textTheme.labelSmall))),
      ]),
    );
  }
}

class _StatsAndAttacks extends StatelessWidget {
  final SeedInstance? inst1;
  final SeedInstance? inst2;
  const _StatsAndAttacks({required this.inst1, required this.inst2});

  Map<String, int> _sumStats() {
    const keys = ['hp', 'atk', 'spd', 'spirit'];
    final base = {for (final k in keys) k: 0};
    void add(Map<String, int>? s) {
      if (s == null) return;
      for (final k in keys) {
        base[k] = (base[k] ?? 0) + (s[k] ?? 0);
      }
    }

    add(inst1?.stats);
    add(inst2?.stats);
    return base;
  }

  Map<String, int> _classPerk(String cls) {
    switch (cls) {
      case 'Warden':
        return const {'hp': 20, 'atk': 2, 'spd': 0, 'spirit': 2};
      case 'Trickster':
        return const {'hp': 10, 'atk': 4, 'spd': 6, 'spirit': 0};
      case 'Sage':
        return const {'hp': 12, 'atk': 0, 'spd': 2, 'spirit': 6};
      case 'Sentinel':
        return const {'hp': 16, 'atk': 3, 'spd': 1, 'spirit': 2};
      case 'Seer':
        return const {'hp': 12, 'atk': 1, 'spd': 3, 'spirit': 6};
      case 'Artificer':
        return const {'hp': 14, 'atk': 5, 'spd': 1, 'spirit': 2};
      case 'Empath':
        return const {'hp': 14, 'atk': 0, 'spd': 2, 'spirit': 6};
      case 'Oracle':
        return const {'hp': 12, 'atk': 2, 'spd': 2, 'spirit': 6};
      case 'Shadow':
        return const {'hp': 13, 'atk': 5, 'spd': 4, 'spirit': 0};
      case 'Alchemist':
        return const {'hp': 15, 'atk': 3, 'spd': 2, 'spirit': 3};
      default:
        return const {'hp': 12, 'atk': 2, 'spd': 2, 'spirit': 4};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Level from profile (first profile or 1 if none)
    int level = 1;
    String classKey = 'Sage';
    try {
      final vals = profileBox().values;
      if (vals.isNotEmpty) {
        level = vals.first.level;
        classKey = vals.first.classKey;
      }
    } catch (_) {}
    

    final spriteStats = _sumStats();
    final baseStats = _classPerk(classKey);
    const keys = ['hp', 'atk', 'spd', 'spirit'];
    // Match mood window label size (titleMedium * 0.6)
    final base = Theme.of(context).textTheme.titleMedium;
    final baseSize = base?.fontSize ?? 14;
    final small = (base?.copyWith(fontSize: baseSize * 0.6)) ??
        const TextStyle(fontSize: 10);

    Color classColor(String cls) {
      switch (cls) {
        case 'Warden':
          return AppColors.success;
        case 'Trickster':
          return AppColors.secondary;
        case 'Sage':
          return AppColors.tertiary;
        case 'Sentinel':
          return AppColors.outline;
        case 'Seer':
          return AppColors.info;
        case 'Artificer':
          return AppColors.primary;
        case 'Empath':
          return AppColors.accentWarm;
        case 'Oracle':
          return AppColors.mutedAlt;
        case 'Shadow':
          return AppColors.error;
        case 'Alchemist':
          return AppColors.primary;
        default:
          return Theme.of(context).colorScheme.primary;
      }
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Player identity rows
        Text('Class: $classKey (Lvl $level)', style: small.copyWith(color: classColor(classKey))),
        const SizedBox(height: 8),
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 70, child: Text(k.toUpperCase(), style: small)),
                Builder(builder: (context) {
                  final v = baseStats[k] ?? 0;
                  final style = v > 0 ? small.copyWith(color: classColor(classKey)) : small;
                  return Text('$v', style: style);
                }),
                const SizedBox(width: 8),
                Text('+${spriteStats[k] ?? 0}',
                    style: small.copyWith(color: Colors.green[700])),
                const SizedBox(width: 8),
                Text('-0', style: small.copyWith(color: Colors.red[700])),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text('Attacks', style: small),
        const SizedBox(height: 4),
        if ((inst1?.attacks.isEmpty ?? true) &&
            (inst2?.attacks.isEmpty ?? true))
          Text('No attacks equipped', style: small),
        ...[
          ...(inst1?.attacks ?? const []),
          ...(inst2?.attacks ?? const []),
        ].map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                  '- ${a['name'] ?? 'Attack'} (Pwr: ${a['power'] ?? '?'} )',
                  style: small),
            )),
      ]),
    );
  }
}
