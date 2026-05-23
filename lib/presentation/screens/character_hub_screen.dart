import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../widgets/gear_slot.dart';
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
import '../../services/sprite_instance_utils.dart';
import '../../game/models/seed_instance.dart';
import 'dart:async';
import '../../theme/colors.dart';
import '../../game/services/player_image_service.dart';
import '../../services/achievement_service.dart';
import '../../services/crafting_tutorial_service.dart';
import '../../crafting/inventory_service.dart';
import '../../crafting/models.dart';
import '../widgets/item_icon_badge.dart';
import '../widgets/item_stats_line.dart';
import '../widgets/item_provenance_block.dart';

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
  StreamSubscription? _profileSub;
  StreamSubscription? _metaSub;
  StreamSubscription? _echoSub;
  ui.Image? _playerImage;
  String? _playerAssetPath; // raw asset fallback
  bool _hideCraftingCoach = false;

  @override
  void initState() {
    super.initState();
    vm = context.read<CharacterHubVM>();
    spriteSlots = context.read<SpriteSlotsRepo>();
    vm.load();
    _loadEquippedSprites();
    _refreshPlayerImage();
    // Refresh when equipment/sprite slots change
    _equipSub = equipmentBox().watch().listen((event) async {
      if (!mounted) return;
      await vm.load();
      await _loadEquippedSprites();
      await _refreshPlayerImage();
    });
    // Also react to profile changes (HP/XP/class) and meta (name, gender)
    _profileSub = profileBox().watch().listen((_) {
      if (mounted) setState(() {});
    });
    _metaSub = playerMetaBox().watch().listen((_) async {
      if (!mounted) return;
      await _refreshPlayerImage();
      setState(() {});
    });
    _echoSub = resonantEchoBox().watch().listen((_) {
      if (!mounted) return;
      setState(() {
        _hideCraftingCoach = false;
      });
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
    setState(() {
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
      try {
        await AchievementService().recordSpriteEquipped();
      } catch (_) {}
    }
    if (mounted) setState(() => _selecting = false);
  }

  void _showSpriteSheet(BuildContext context, int slot) {
    final inst = slot == 1 ? _inst1 : _inst2;
    showModalBottomSheet(
        context: context,
        builder: (_) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sprite $slot',
                              style: Theme.of(context).textTheme.titleMedium),
                          TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await _pickSprite(slot);
                              },
                              child: const Text('Change')),
                        ]),
                    const SizedBox(height: 8),
                    if (inst != null) ...[
                      SizedBox(
                          height: 80,
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: RawImage(
                                  image: slot == 1 ? _spriteImg1 : _spriteImg2,
                                  filterQuality: FilterQuality.none))),
                      const SizedBox(height: 6),
                      Text('Stats',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                          'HP ${inst.stats['hp'] ?? 0}  ATK ${inst.stats['atk'] ?? 0}  SPD ${inst.stats['spd'] ?? 0}  SPIRIT ${inst.stats['spirit'] ?? 0}',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 6),
                      if (SpriteInstanceUtils.strongestAttackForInstance(
                              inst) !=
                          null)
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Attack',
                                  style:
                                      Theme.of(context).textTheme.labelSmall),
                              const SizedBox(height: 2),
                              Text(
                                '• ${SpriteInstanceUtils.attackNameForInstance(inst)} (Pwr: ${SpriteInstanceUtils.attackPowerForInstance(inst)})',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ]),
                      const SizedBox(height: 6),
                      Text(
                        'Origin: ${SpriteInstanceUtils.sourceTypeLabel(inst.source)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Source: ${SpriteInstanceUtils.sourceTitleOf(inst) ?? 'Unknown'}'
                        '${SpriteInstanceUtils.sourceDateOf(inst) != null ? ' (${_formatSpriteSourceDate(SpriteInstanceUtils.sourceDateOf(inst)!)})' : ''}',
                        style: Theme.of(context).textTheme.labelSmall,
                        softWrap: true,
                      ),
                      if (SpriteInstanceUtils.fusedFromNamesOf(inst).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Lineage: ${SpriteInstanceUtils.fusedFromNamesOf(inst).join(' + ')}',
                            style: Theme.of(context).textTheme.labelSmall,
                            softWrap: true,
                          ),
                        ),
                    ] else ...[
                      const Text('No sprite assigned.'),
                    ],
                  ]),
            ),
          );
        });
  }

  String _formatSpriteSourceDate(DateTime dt) {
    final d = dt.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  void _onSlotTap(BuildContext context, String slotId, EquippedItem? item) {
    if (item == null) {
      // Directly open inventory for this slot
      String filter = slotId;
      if (slotId == 'ringLeft' || slotId == 'ringRight') filter = 'ring';
      if (slotId == 'neck') filter = 'neck';
      context.push('/inventory', extra: {'filter': filter});
      return;
    }
    _showItemSheet(context, slotId, item);
  }

  void _showItemSheet(BuildContext context, String slotId, EquippedItem item) {
    final crafted = CraftedInventoryService.getById(item.id);
    showModalBottomSheet(
        context: context,
        builder: (_) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: icon (if available) + slot title + Change
                    Row(children: [
                      if (crafted != null) ...[
                        ItemIconBadge(
                            iconPath: crafted.def.iconPath,
                            rarity: crafted.rarity,
                            element: crafted.element,
                            tier: crafted.tier,
                            size: 32),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                          child: Text(_slotTitle(slotId),
                              style: Theme.of(context).textTheme.titleMedium,
                              softWrap: true)),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _onSlotTap(context, slotId, null);
                          },
                          child: const Text('Change')),
                    ]),
                    const SizedBox(height: 8),
                    // Body top line: item name (wrapped, no icon here)
                    Text(crafted?.displayName ?? item.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    if (crafted != null) ...[
                      Text(
                          'Slot: ${_prettySlot(crafted.def)}  Tier ${crafted.tier}  Rarity: ${crafted.rarity.name}',
                          style: Theme.of(context).textTheme.labelSmall),
                      if ((crafted.classAffinity ??
                              crafted.def.classAffinity) !=
                          null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Class Affinity: ${(crafted.classAffinity ?? crafted.def.classAffinity)!}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      if (crafted.stats.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stats: ',
                                  style:
                                      Theme.of(context).textTheme.labelSmall),
                              Expanded(
                                  child: ItemStatsLine(
                                      stats: crafted.stats,
                                      element: crafted.element,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall)),
                            ]),
                      ],
                      if (crafted.stats.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Effects',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 2),
                        ..._effectTexts(crafted.stats).map((t) => Text('• $t',
                            style: Theme.of(context).textTheme.labelSmall)),
                      ],
                      if (crafted.memorySources.isNotEmpty ||
                          crafted.lineageSteps.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ItemProvenanceBlock(
                          item: crafted,
                          headingStyle: Theme.of(context).textTheme.labelMedium,
                          bodyStyle: Theme.of(context).textTheme.labelSmall,
                          maxSources: 5,
                          maxLineageSteps: 4,
                        ),
                      ],
                      const SizedBox(height: 8),
                    ] else ...[
                      // No crafted details: only slot line
                      Text('Slot: ${_slotTitle(slotId)}',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                    ],
                  ]),
            ),
          );
        });
  }

  List<String> _effectTexts(Map<String, num> stats) {
    final lines = <String>[];
    const baseOrder = ['def', 'atk', 'hp', 'spd', 'spirit'];
    for (final k in baseOrder) {
      final v = stats[k];
      if (v != null && v != 0) {
        final iv = v.round();
        final sign = iv > 0 ? '+' : '';
        lines.add('${k.toUpperCase()} $sign$iv');
      }
    }
    final mods = <String, int>{};
    stats.forEach((k, v) {
      if (k.startsWith('mod_')) {
        final stat = k.substring(4);
        mods[stat] = (mods[stat] ?? 0) + v.round();
      }
    });
    for (final entry in mods.entries) {
      final k = entry.key.toUpperCase();
      final v = entry.value;
      if (v == 0) continue;
      final sign = v > 0 ? '+' : '';
      lines.add('$k $sign$v');
    }
    stats.forEach((k, v) {
      if (baseOrder.contains(k) || k.startsWith('mod_')) return;
      final iv = v.round();
      if (iv == 0) return;
      final sign = iv > 0 ? '+' : '';
      lines.add('${k.toUpperCase()} $sign$iv');
    });
    return lines;
  }

  String _slotTitle(String slotId) {
    switch (slotId) {
      case 'head':
        return 'Head';
      case 'chest':
        return 'Chest';
      case 'hands':
        return 'Hands';
      case 'legs':
        return 'Legs';
      case 'feet':
        return 'Feet';
      case 'neck':
        return 'Neck';
      case 'ringLeft':
        return 'Ring (Left)';
      case 'ringRight':
        return 'Ring (Right)';
      case 'weapon':
        return 'Weapon';
      default:
        return slotId;
    }
  }

  String _prettySlot(ItemDef def) {
    final eq = (def.equipSlot ?? '').toLowerCase();
    if (eq == 'ring') return 'Ring';
    if (eq == 'neck') return 'Necklace';
    switch (def.slot) {
      case SlotId.head:
        return 'Head';
      case SlotId.chest:
        return 'Chest';
      case SlotId.hands:
        return 'Hands';
      case SlotId.legs:
        return 'Legs';
      case SlotId.feet:
        return 'Feet';
      case SlotId.weapon:
        return 'Weapon';
    }
  }

  bool _showCraftingCoach() {
    return !_hideCraftingCoach && CraftingTutorialService.shouldShowHubCoach();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CharacterHubVM>().state;

    // Title uses player name and follows the shared left-aligned app chrome.
    String titleName = 'Adventurer';
    try {
      final n = playerMetaBox().get('name');
      if (n is String && n.trim().isNotEmpty) titleName = n.trim();
    } catch (_) {}

    return GameScaffold(
      title: titleName,
      body: Stack(children: [
        // Background image with dark overlay
        Positioned.fill(
            child: Image.asset('assets/images/splash_bg.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.deepNight.withValues(alpha: 0.46),
                  AppColors.midnight.withValues(alpha: 0.68),
                  AppColors.deepNight.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.18),
                radius: 0.98,
                colors: [
                  AppColors.secondary.withValues(alpha: 0.09),
                  AppColors.primary.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.34, 1.0],
              ),
            ),
          ),
        ),
        RefreshIndicator(
          onRefresh: vm.refreshTickets,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HubBars(),
                        if (_showCraftingCoach()) ...[
                          _CraftingCoachCard(
                            echoCount: resonantEchoBox().length,
                            onOpen: () => context.push('/crafting'),
                            onDismiss: () => setState(() {
                              _hideCraftingCoach = true;
                            }),
                          ),
                          const SizedBox(height: 12),
                        ],
                        LayoutBuilder(
                          builder: (ctx, c) {
                            final w = c.maxWidth;
                            final viewH = MediaQuery.of(context).size.height;
                            final compact = w < 400;
                            const topInset = 4.0;
                            const bottomInset = 10.0;
                            final double h = (viewH * (compact ? 0.285 : 0.305))
                                .clamp(238.0, 286.0);
                            final sideInset = w * 0.072;
                            final double boxSize =
                                w < 370 ? 46.0 : (w < 420 ? 50.0 : 56.0);
                            const charWFactor = 0.32;
                            double charSize = w * charWFactor;
                            final maxCharByHeight =
                                h - (2 * boxSize) - topInset - bottomInset - 6;
                            if (maxCharByHeight > 0 &&
                                maxCharByHeight < charSize) {
                              charSize = maxCharByHeight;
                            }
                            final slotTravel =
                                (h - boxSize - topInset - bottomInset)
                                    .clamp(0.0, double.infinity);
                            double vPos(int i, int count) =>
                                topInset +
                                slotTravel *
                                    (count <= 1 ? 0.0 : i / (count - 1));
                            return Container(
                              height: h + 12,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.panel.withValues(alpha: 0.38),
                                border: Border.all(
                                  color: AppColors.outlineSoft
                                      .withValues(alpha: 0.9),
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.overlayShadow,
                                    offset: Offset(0, 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                height: h,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: charSize,
                                      height: charSize,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface
                                            .withValues(alpha: 0.3),
                                        border: Border.all(
                                          color: AppColors.outlineBright
                                              .withValues(alpha: 0.72),
                                        ),
                                        borderRadius: BorderRadius.zero,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.secondary
                                                .withValues(alpha: 0.14),
                                            blurRadius: 0,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: _playerImage != null
                                          ? RawImage(
                                              image: _playerImage,
                                              filterQuality: FilterQuality.none,
                                              fit: BoxFit.contain,
                                              width: charSize,
                                              height: charSize)
                                          : (_playerAssetPath != null
                                              ? Image.asset(_playerAssetPath!,
                                                  filterQuality:
                                                      FilterQuality.none,
                                                  fit: BoxFit.contain,
                                                  width: charSize,
                                                  height: charSize,
                                                  errorBuilder: (_, __, ___) =>
                                                      Text('Character',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium))
                                              : Text('Character',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium)),
                                    ),
                                    Positioned(
                                      top: vPos(0, 4),
                                      left: (w / 2) - boxSize - 8,
                                      child: GearSlot(
                                          slotId: 'head',
                                          item: state.gear['head'],
                                          onTap: () => _onSlotTap(context,
                                              'head', state.gear['head']),
                                          size: boxSize),
                                    ),
                                    Positioned(
                                      top: vPos(0, 4),
                                      left: (w / 2) + 8,
                                      child: GearSlot(
                                          slotId: 'neck',
                                          item: state.gear['neck'],
                                          onTap: () => _onSlotTap(context,
                                              'neck', state.gear['neck']),
                                          size: boxSize),
                                    ),
                                    Positioned(
                                      top: vPos(0, 4),
                                      left: sideInset,
                                      child: GearSlot(
                                          slotId: 'chest',
                                          item: state.gear['chest'],
                                          onTap: () => _onSlotTap(context,
                                              'chest', state.gear['chest']),
                                          size: boxSize),
                                    ),
                                    Positioned(
                                      top: vPos(1, 4),
                                      left: sideInset,
                                      child: GearSlot(
                                          slotId: 'hands',
                                          item: state.gear['hands'],
                                          onTap: () => _onSlotTap(context,
                                              'hands', state.gear['hands']),
                                          size: boxSize),
                                    ),
                                    Positioned(
                                      top: vPos(2, 4),
                                      left: sideInset,
                                      child: GearSlot(
                                          slotId: 'legs',
                                          item: state.gear['legs'],
                                          onTap: () => _onSlotTap(context,
                                              'legs', state.gear['legs']),
                                          size: boxSize),
                                    ),
                                    Positioned(
                                      top: vPos(3, 4),
                                      left: sideInset,
                                      child: GearSlot(
                                          slotId: 'feet',
                                          item: state.gear['feet'],
                                          onTap: () => _onSlotTap(context,
                                              'feet', state.gear['feet']),
                                          size: boxSize),
                                    ),
                                    Positioned(
                                      top: vPos(0, 4),
                                      right: sideInset,
                                      child: GearSlot(
                                          slotId: 'ringLeft',
                                          item: state.gear['ringLeft'],
                                          onTap: () => _onSlotTap(
                                              context,
                                              'ringLeft',
                                              state.gear['ringLeft']),
                                          size: boxSize),
                                    ),
                                    Positioned(
                                      top: vPos(1, 4),
                                      right: sideInset,
                                      child: GearSlot(
                                          slotId: 'ringRight',
                                          item: state.gear['ringRight'],
                                          onTap: () => _onSlotTap(
                                              context,
                                              'ringRight',
                                              state.gear['ringRight']),
                                          size: boxSize),
                                    ),
                                    Positioned(
                                      top: vPos(2, 4),
                                      right: sideInset,
                                      child: GearSlot(
                                          slotId: 'weapon',
                                          item: state.gear['weapon'],
                                          onTap: () => _onSlotTap(context,
                                              'weapon', state.gear['weapon']),
                                          size: boxSize),
                                    ),
                                    Positioned(
                                      top: vPos(3, 4),
                                      right: sideInset,
                                      child: SizedBox(
                                        width: boxSize,
                                        height: boxSize,
                                        child: PopupMenuButton<_HubMenuAction>(
                                          tooltip: 'Menu',
                                          padding: EdgeInsets.zero,
                                          position: PopupMenuPosition.under,
                                          onSelected: (v) {
                                            switch (v) {
                                              case _HubMenuAction.echoes:
                                                context.push('/echoes');
                                                break;
                                              case _HubMenuAction.items:
                                                context.push('/items');
                                                break;
                                              case _HubMenuAction.weapons:
                                                context.push('/items');
                                                break;
                                              case _HubMenuAction.armor:
                                                context.push('/items');
                                                break;
                                              case _HubMenuAction.codex:
                                                context.push('/codex');
                                                break;
                                              case _HubMenuAction.crafting:
                                                context.push('/crafting');
                                                break;
                                              case _HubMenuAction.achievements:
                                                context.push('/achievements');
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                                value: _HubMenuAction.items,
                                                child: _MenuItemRow(
                                                    icon: Icons.backpack,
                                                    label: 'Items')),
                                            PopupMenuItem(
                                                value: _HubMenuAction.codex,
                                                child: _MenuItemRow(
                                                    icon: Icons.auto_stories,
                                                    label: 'Codex')),
                                            PopupMenuItem(
                                                value: _HubMenuAction.crafting,
                                                child: _MenuItemRow(
                                                    icon: Icons.handyman,
                                                    label: 'Crafting')),
                                            PopupMenuItem(
                                                value:
                                                    _HubMenuAction.achievements,
                                                child: _MenuItemRow(
                                                    icon: Icons.emoji_events,
                                                    label: 'Achievements')),
                                          ],
                                          child: Container(
                                            width: boxSize,
                                            height: boxSize,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: AppColors.panelSoft
                                                  .withValues(alpha: 0.3),
                                              border: Border.all(
                                                color: AppColors.outlineBright
                                                    .withValues(alpha: 0.55),
                                                width: 1.2,
                                              ),
                                              borderRadius: BorderRadius.zero,
                                            ),
                                            child: Icon(
                                              Icons.menu_rounded,
                                              size: boxSize * 0.5,
                                              color: AppColors.parchment
                                                  .withValues(alpha: 0.88),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: h - boxSize - bottomInset,
                                      left: (w / 2) - boxSize - 8,
                                      child: SizedBox(
                                        width: boxSize,
                                        height: boxSize,
                                        child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              GearSlot(
                                                  slotId: 'sprite1',
                                                  item: null,
                                                  onTap: () => _showSpriteSheet(
                                                      context, 1),
                                                  size: boxSize),
                                              if (_spriteImg1 != null)
                                                IgnorePointer(
                                                    ignoring: true,
                                                    child: RawImage(
                                                        image: _spriteImg1,
                                                        filterQuality:
                                                            FilterQuality.none,
                                                        width: boxSize * 0.8,
                                                        height: boxSize * 0.8)),
                                            ]),
                                      ),
                                    ),
                                    Positioned(
                                      top: h - boxSize - bottomInset,
                                      left: (w / 2) + 8,
                                      child: SizedBox(
                                        width: boxSize,
                                        height: boxSize,
                                        child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              GearSlot(
                                                  slotId: 'sprite2',
                                                  item: null,
                                                  onTap: () => _showSpriteSheet(
                                                      context, 2),
                                                  size: boxSize),
                                              if (_spriteImg2 != null)
                                                IgnorePointer(
                                                    ignoring: true,
                                                    child: RawImage(
                                                        image: _spriteImg2,
                                                        filterQuality:
                                                            FilterQuality.none,
                                                        width: boxSize * 0.8,
                                                        height: boxSize * 0.8)),
                                            ]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        _StatsAndAttacks(inst1: _inst1, inst2: _inst2),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.ivory,
                            side: const BorderSide(
                              color: AppColors.outlineBright,
                              width: 1.5,
                            ),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: state.openTickets > 0
                              ? () async {
                                  final encounters =
                                      context.read<EncountersRepo>();
                                  final id =
                                      await encounters.getFirstOpenTicketId();
                                  if (id == null) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('No open encounters.')));
                                    return;
                                  }
                                  try {
                                    final battleId = await BattleServiceImpl(
                                            codex: CodexServiceImpl(),
                                            echo: EchoServiceImpl())
                                        .start(id);
                                    if (!context.mounted) return;
                                    await context.push('/battle',
                                        extra: {'battleId': battleId});
                                    if (!context.mounted) return;
                                    await vm.refreshTickets();
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Battle flow not ready')));
                                  }
                                }
                              : null,
                          child: Text(state.openTickets > 0
                              ? 'Battle Now'
                              : 'No Battles Available'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // Deprecated debug stub removed; use live battle flow via /battle.

  @override
  void dispose() {
    _equipSub?.cancel();
    _profileSub?.cancel();
    _metaSub?.cancel();
    _echoSub?.cancel();
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
    int hp = 60;
    int maxHp = 60;
    try {
      hp = (playerMetaBox().get('hp') as int?) ?? 60;
    } catch (_) {}
    // Compute dynamic max HP: base + class mod + level bonus + sprite bonuses
    const baseHp = 60;
    String classKey = 'Sage';
    int level = 1;
    try {
      final vals = profileBox().values;
      if (vals.isNotEmpty) {
        level = vals.first.level;
        classKey = vals.first.classKey;
      }
    } catch (_) {}
    int classMod = 0;
    switch (classKey) {
      case 'Warden':
        classMod = 8;
        break;
      case 'Sentinel':
        classMod = 5;
        break;
      case 'Empath':
        classMod = 5;
        break;
      default:
        classMod = 0;
        break;
    }
    final hpLv = ((level - 1).clamp(0, 999)) * 3;
    // Sprite HP from equipped slots
    int spriteHp = 0;
    try {
      final raw = (equipmentBox().get('sprite_slots') as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v?.toString())) ??
          const <String, String?>{};
      for (final sid in ['sprite1', 'sprite2']) {
        final id = raw[sid];
        if (id == null || id.isEmpty) continue;
        try {
          final inst =
              seedInstanceBox().values.firstWhere((e) => e.instanceId == id);
          spriteHp += (inst.stats['hp'] ?? 0);
        } catch (_) {}
      }
    } catch (_) {}
    maxHp = baseHp + classMod + hpLv + spriteHp;
    if (hp > maxHp) {
      hp = maxHp;
    }
    int xp = 0;
    try {
      final vals = profileBox().values;
      if (vals.isNotEmpty) {
        level = vals.first.level;
        xp = vals.first.xp;
      }
    } catch (_) {}
    final nextXp = level * 20; // small scale
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HubStatBar(
            label: 'HP', current: hp, max: maxHp, color: AppColors.error),
        const SizedBox(height: 6),
        _HubStatBar(
            label: 'XP L$level',
            current: xp,
            max: nextXp,
            color: AppColors.info),
      ],
    );
  }
}

class _HubStatBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;
  const _HubStatBar(
      {required this.label,
      required this.current,
      required this.max,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      height: 22,
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.panel.withValues(alpha: 0.78),
            border: Border.all(
              color: AppColors.outlineBright.withValues(alpha: 0.72),
            ),
          ),
        ),
        FractionallySizedBox(
          widthFactor: pct,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.88),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.24),
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              '$label: $current/$max',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ivory,
                shadows: const [
                  Shadow(offset: Offset(0, 1), blurRadius: 0),
                ],
              ),
            ),
          ),
        ),
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

  // Sum base equipment stats (non-mod_ keys) from equipped gear
  Map<String, int> _gearBase() {
    const keys = ['hp', 'atk', 'spd', 'spirit', 'def'];
    final out = {for (final k in keys) k: 0};
    try {
      final raw = equipmentBox().get('slots') as Map? ?? const {};
      for (final v in raw.values) {
        if (v is! Map) continue;
        final id = (v['id'] ?? '').toString();
        final crafted = CraftedInventoryService.getById(id);
        if (crafted == null) continue;
        crafted.stats.forEach((k, val) {
          if (k.startsWith('mod_')) return;
          if (!out.containsKey(k)) return;
          final n = val.round();
          out[k] = (out[k] ?? 0) + n;
        });
      }
    } catch (_) {}
    return out;
  }

  // Sum enchantment (mod_) stats from equipped gear
  Map<String, int> _gearMods() {
    const keys = ['hp', 'atk', 'spd', 'spirit', 'def'];
    final out = {for (final k in keys) k: 0};
    try {
      final raw = equipmentBox().get('slots') as Map? ?? const {};
      for (final v in raw.values) {
        if (v is! Map) continue;
        final id = (v['id'] ?? '').toString();
        final crafted = CraftedInventoryService.getById(id);
        if (crafted == null) continue;
        crafted.stats.forEach((k, val) {
          if (!k.startsWith('mod_')) return;
          final stat = k.substring(4);
          if (!out.containsKey(stat)) return;
          final n = val.round();
          out[stat] = (out[stat] ?? 0) + n;
        });
      }
    } catch (_) {}
    return out;
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
    // Ensure DEF exists in sprite stats as 0
    final spriteAll = {...spriteStats, 'def': 0};
    final baseStats = _classPerk(classKey);
    // Apply level-based scaling: +3 HP per level, +1 ATK every 2 levels, +1 SPD every 3, +1 SPIRIT every 3
    final lv = (level - 1).clamp(0, 999);
    final scaled = {
      'hp': (baseStats['hp'] ?? 0) + lv * 3,
      'atk': (baseStats['atk'] ?? 0) + (lv ~/ 2),
      'spd': (baseStats['spd'] ?? 0) + (lv ~/ 3),
      'spirit': (baseStats['spirit'] ?? 0) + (lv ~/ 3),
    };
    final gearBase = _gearBase();
    final gearMods = _gearMods();
    const keys = ['hp', 'atk', 'spd', 'spirit', 'def'];
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

    final attacks = (() {
      final selected = <Map<String, dynamic>>[];
      for (final inst in [inst1, inst2]) {
        final best = SpriteInstanceUtils.strongestAttackForInstance(inst);
        if (best != null) {
          selected.add(best);
        }
      }
      final uniq = selected.toList()
        ..sort((a, b) {
          final bp = int.tryParse(b['power']?.toString() ?? '') ?? 0;
          final ap = int.tryParse(a['power']?.toString() ?? '') ?? 0;
          return bp.compareTo(ap);
        });
      return uniq;
    })();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.52),
        border: Border.all(
          color: AppColors.outlineBright.withValues(alpha: 0.62),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlayShadow,
            blurRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Player identity rows
        Text('Class: $classKey (Lvl $level)',
            style: small.copyWith(color: classColor(classKey))),
        const SizedBox(height: 8),
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 70, child: Text(k.toUpperCase(), style: small)),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Builder(builder: (context) {
                        // Show base (class+level) value only here
                        final v = (scaled[k] ?? 0);
                        final style = v > 0
                            ? small.copyWith(color: classColor(classKey))
                            : small;
                        return Text('$v', style: style);
                      }),
                      Text('+${spriteAll[k] ?? 0}',
                          style: small.copyWith(color: AppColors.success)),
                      Text('+${gearBase[k] ?? 0}',
                          style: small.copyWith(color: AppColors.tertiary)),
                      Text('+${gearMods[k] ?? 0}',
                          style: small.copyWith(color: AppColors.secondary)),
                      Text('-0', style: small.copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text('Attacks', style: small),
        const SizedBox(height: 4),
        if (attacks.isEmpty) Text('No attacks equipped', style: small),
        ...attacks.map(
          (a) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('- ', style: small),
                Expanded(
                  child: Text(
                    '${a['name'] ?? 'Attack'} (Pwr: ${a['power'] ?? '?'})',
                    style: small,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _CraftingCoachCard extends StatelessWidget {
  final int echoCount;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  const _CraftingCoachCard({
    required this.echoCount,
    required this.onOpen,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panelSoft.withValues(alpha: 0.46),
        border: Border.all(
          color: AppColors.glowTeal.withValues(alpha: 0.55),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlayShadow,
            blurRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.handyman,
                  size: 20, color: AppColors.glowTeal.withValues(alpha: 0.95)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You have $echoCount echoes ready to forge',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'Hide tip',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Crafting turns echoes into gear, upgrades items with echo energy, and fuses crafted items into stronger results.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Try Crafting'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _HubMenuAction {
  echoes,
  items,
  weapons,
  armor,
  codex,
  crafting,
  achievements
}

class _MenuItemRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuItemRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
