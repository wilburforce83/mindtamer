import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/gameplay/battle_notifier.dart';
import '../../game/services/player_image_service.dart';
import '../../data/hive/boxes.dart';
import '../../services/inventory_service.dart';
import '../../game/services/seed_pipeline.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/pixel_button.dart';
import '../../core/pixel_assets.dart';
import '../../services/item_catalog.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final String? battleId;
  const BattleScreen({super.key, this.battleId});
  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  static const _battleLeaveMessage =
      'You cannot change pages during battle. Use Run Away if you want to leave.';
  Future<ui.Image?>? _playerImgFut;
  // Manual frame-based movement
  Offset _playerOffset = Offset.zero;
  Offset _enemyOffset = Offset.zero;
  int _lastActionSeq = 0;
  int _lastLogLen = 0;
  String? _floatText;
  Alignment _floatAlign = Alignment.center;
  Color _floatColor = Colors.white;
  DateTime _floatUntil = DateTime.fromMillisecondsSinceEpoch(0);
  double _floatDrift = 0.0;
  Timer? _floatTimer;
  bool _popped = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.battleId != null) {
      Future.microtask(() =>
          ref.read(battleProvider.notifier).init(battleId: widget.battleId!));
    }
    _playerImgFut = PlayerImageService().renderCurrentPlayer();
    // Preload asset manifest for item icons
    PixelAssets.init();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void didUpdateWidget(covariant BattleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.battleId != oldWidget.battleId && widget.battleId != null) {
      // Reset UI state and re-init battle when navigating to a new battle id
      _popped = false;
      _playerOffset = Offset.zero;
      _enemyOffset = Offset.zero;
      _floatText = null;
      _floatDrift = 0.0;
      _lastActionSeq = 0;
      _lastLogLen = 0;
      try {
        _floatTimer?.cancel();
      } catch (_) {}
      // Defer provider update until after current build to satisfy Riverpod constraints
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.battleId == null) return;
        ref.read(battleProvider.notifier).init(battleId: widget.battleId!);
      });
    }
  }

  void _runActionAnim(Map<String, dynamic> action) async {
    final attacker = (action['attacker'] ?? 'player') as String;
    final target = (action['target'] ?? 'enemy') as String;
    final melee = (action['melee'] ?? false) as bool;
    final box =
        context.size; // might be null at init; compute from MediaQuery if so
    final w = (box?.width ?? MediaQuery.of(context).size.width);
    // Compute approximate distance between sprites: width - horizontal padding (32) - 2*spriteSize
    const sprite = 64.0;
    const pad = 32.0;
    final double distBetween = (w - pad - (2 * sprite)).clamp(0.0, w);

    // Sequence: lunge (if melee) then shake target; 5 frames total each
    if (melee) {
      if (attacker == 'player') {
        await _runFrames(true, [
          Offset(distBetween * 0.25, 0),
          Offset(distBetween * 0.5, 0),
          Offset(distBetween * 0.95, 0),
          Offset(distBetween * 0.5, 0),
          Offset.zero,
        ]);
      } else {
        await _runFrames(false, [
          Offset(-distBetween * 0.25, 0),
          Offset(-distBetween * 0.5, 0),
          Offset(-distBetween * 0.95, 0),
          Offset(-distBetween * 0.5, 0),
          Offset.zero,
        ]);
      }
    }

    // Shake target (5 discrete frames)
    const double s = 6.0;
    final shake = [
      const Offset(-s, 0),
      const Offset(s, 0),
      const Offset(0, -s),
      const Offset(0, s),
      Offset.zero,
    ];
    await _runFrames(target != 'enemy', shake);
  }

  Future<void> _runFrames(bool player, List<Offset> frames) async {
    for (final off in frames) {
      if (!mounted) return;
      setState(() {
        if (player) {
          _playerOffset = off;
        } else {
          _enemyOffset = off;
        }
      });
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  @override
  void dispose() {
    try {
      _floatTimer?.cancel();
    } catch (_) {}
    try {
      _pulseCtrl.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _showItemsModal(WidgetRef ref) async {
    final locked = ref.read(battleProvider).inputLocked;
    if (locked) return;
    final inv = InventoryService.inventory();
    // Filter only catalog-defined items
    final usable = inv
        .where((e) => ItemCatalog.defOf((e['type'] ?? '').toString()) != null)
        .toList();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Use Item', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: usable.length,
                    itemBuilder: (_, i) {
                      final it = usable[i];
                      final id = it['id'] as String;
                      final type = (it['type'] ?? '').toString();
                      final label = ItemEffects.label(type);
                      final asset = ItemCatalog.assetOf(type);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          if (asset != null && PixelAssets.has(asset))
                            Image.asset(asset,
                                width: 20,
                                height: 20,
                                filterQuality: FilterQuality.none)
                          else
                            const Icon(Icons.inventory_2_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(label,
                                  style: Theme.of(context).textTheme.labelSmall,
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text('x${it['qty']}',
                              style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact),
                            onPressed: (it['qty'] as int) > 0 && !locked
                                ? () {
                                    Navigator.of(ctx).pop();
                                    ref
                                        .read(battleProvider.notifier)
                                        .useItemFromInventory(id);
                                  }
                                : null,
                            child: const Text('Use',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ]),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBattleLockedMessage() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(content: Text(_battleLeaveMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(battleProvider);
    final navigationLocked = state.result == null;

    // Trigger animations when an action occurs (post-frame to avoid build-time side effects)
    if (state.actionSeq != _lastActionSeq && state.lastAction != null) {
      final action = state.lastAction!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _runActionAnim(action);
      });
      _lastActionSeq = state.actionSeq;
    }

    // Floating damage/heal text from latest log line
    if (state.log.length > _lastLogLen && state.lastAction != null) {
      final last = state.log.isNotEmpty ? state.log.last : '';
      String? text;
      Color color = Colors.white;
      final dmg = RegExp(r'for\s+(\d+)\s+damage').firstMatch(last);
      if (dmg != null) {
        text = '-${dmg.group(1)}';
        color = Colors.redAccent;
      }
      final heal = RegExp(r'\+(\d+)HP').firstMatch(last);
      if (heal != null) {
        text = '+${heal.group(1)}';
        color = Colors.greenAccent;
      }
      if (text != null) {
        _floatText = text;
        _floatColor = color;
        _floatAlign = (state.lastAction!['target'] == 'enemy')
            ? Alignment.bottomRight
            : Alignment.bottomLeft;
        final start = DateTime.now();
        _floatUntil = start.add(const Duration(milliseconds: 800));
        _floatDrift = 0;
        _floatTimer?.cancel();
        _floatTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          final elapsed = DateTime.now().difference(start).inMilliseconds;
          const total = 800;
          final p = elapsed / total;
          if (p >= 1) {
            setState(() {
              _floatText = null;
              _floatDrift = 0;
            });
            t.cancel();
          } else {
            setState(() {
              _floatDrift = 24.0 * p;
            });
          }
        });
      }
      _lastLogLen = state.log.length;
    }

    // Outcome routing (only for this battleId): show modal summary
    if (!_popped && state.result != null && state.battleId == widget.battleId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _popped = true;
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              final items = state.winLoot
                  .map((e) =>
                      "${ItemEffects.label(e['type'] as String)} x${e['qty']}")
                  .toList();
              final codex = state.codexAdded ? 'Added to Codex' : null;
              final echo = state.echoDropped ? 'Resonant Echo acquired' : null;
              final details = <String>[
                'XP +${state.xpGained}${state.leveledUp ? ' (Level Up!)' : ''}',
                if (items.isNotEmpty) 'Loot: ${items.join(', ')}',
                if (codex != null) codex,
                if (echo != null) echo,
              ];
              return AlertDialog(
                title: Text(state.result == 'win'
                    ? 'Victory!'
                    : (state.result == 'escape' ? 'Escaped' : 'Defeat')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in details)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(line)),
                    if (details.isEmpty) const Text('No rewards this time.')
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.go('/character');
                      },
                      child: const Text('Home')),
                  Builder(builder: (bctx) {
                    final open = encounterTicketBox()
                        .values
                        .where((e) => e.state == 'open')
                        .toList();
                    if (open.isEmpty || state.result != 'win') {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final first = open.first;
                          final id = await BattleServiceImpl(
                                  codex: CodexServiceImpl(),
                                  echo: EchoServiceImpl())
                              .start(first.ticketId);
                          if (!mounted) return;
                          this.context.go('/battle', extra: {'battleId': id});
                        },
                        child: const Text('Next Battle'));
                  })
                ],
              );
            });
      });
    }

    final topHud = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatBar(
            label: 'HP',
            current: state.playerHp,
            max: state.playerMaxHp,
            color: Colors.redAccent),
        const SizedBox(height: 6),
        _StatBar(
            label: state.enemyName ?? 'Enemy',
            current: state.enemyHp,
            max: state.enemyMaxHp,
            color: Colors.teal),
      ],
    );

    final battleArea = AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (state.backgroundAsset.isNotEmpty)
            Image.asset(state.backgroundAsset,
                fit: BoxFit.cover, filterQuality: FilterQuality.none),
          // Foreground: player left, enemy right
          // Foreground combatants with transforms (shake/lunge)
          LayoutBuilder(builder: (context, cts) {
            final width = cts.maxWidth;
            final height = width / (16 / 9);
            final baseShift = width *
                0.10; // move 10% towards center (further apart by ~15% from previous)
            final upShift = -height * 0.05; // move up by ~5%
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: _playerOffset + Offset(baseShift, upShift),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: FutureBuilder<ui.Image?>(
                        future: _playerImgFut,
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const SizedBox();
                          }
                          final img = snap.data;
                          if (img == null) return const Text('You');
                          return RawImage(
                              image: img,
                              filterQuality: FilterQuality.none,
                              fit: BoxFit.contain);
                        },
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: _enemyOffset + Offset(-baseShift, upShift),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: state.enemyAssetPath != null
                          ? Image.asset(state.enemyAssetPath!,
                              filterQuality: FilterQuality.none,
                              fit: BoxFit.contain)
                          : Center(
                              child: Text(state.enemyName ?? 'Enemy',
                                  style:
                                      Theme.of(context).textTheme.titleSmall)),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Removed hit highlighting overlay per design
          // Status tags stubs for player/enemy
          Positioned(
            left: 16,
            bottom: 64 + 12,
            child: _StatusTags(statuses: state.playerStatuses),
          ),
          Positioned(
            right: 16,
            bottom: 64 + 12,
            child: _StatusTags(statuses: state.enemyStatuses, alignRight: true),
          ),
          if (_floatText != null && DateTime.now().isBefore(_floatUntil))
            Align(
              alignment: _floatAlign,
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: 120, left: 24, right: 24),
                child: Transform.translate(
                  offset: Offset(0, -_floatDrift),
                  child: Text(_floatText!,
                      style: TextStyle(
                          color: _floatColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );

    Color colorForElement(String? e) {
      switch ((e ?? '').toLowerCase()) {
        case 'fire':
          return Colors.deepOrange;
        case 'water':
          return Colors.blueAccent;
        case 'air':
          return Colors.lightBlueAccent;
        case 'light':
          return Colors.amber;
        case 'shadow':
          return Colors.purple;
        case 'nature':
          return Colors.green;
        case 'metal':
          return Colors.grey;
        default:
          return Theme.of(context).colorScheme.surface; // neutral
      }
    }

    final skillsWrap = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < state.skills.length; i++)
          PixelButton(
            label: state.skillCooldowns.elementAt(i) > 0
                ? '${state.skills[i]} (${state.skillCooldowns[i]})'
                : state.skills[i],
            onPressed:
                state.skillCooldowns.elementAt(i) > 0 || state.inputLocked
                    ? null
                    : () => ref.read(battleProvider.notifier).useSkill(i),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
      ],
    );

    final spritesWrap = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < state.sprites.length; i++)
          Builder(builder: (ctx) {
            final elem = i < state.spriteElements.length
                ? state.spriteElements[i]
                : null;
            final bg = colorForElement(elem).withValues(alpha: 0.85);
            const fg = Colors.white;
            final label = state.spriteCooldowns.elementAt(i) > 0
                ? '${state.sprites[i]} (${state.spriteCooldowns[i]})'
                : state.sprites[i];
            return PixelButton(
              label: label,
              onPressed:
                  state.spriteCooldowns.elementAt(i) > 0 || state.inputLocked
                      ? null
                      : () => ref.read(battleProvider.notifier).useSprite(i),
              primary: false,
              bgColor: bg,
              fgColor: fg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }),
      ],
    );

    final itemsOpenButton = Align(
      alignment: Alignment.centerLeft,
      child: PixelButton(
        label: 'Items',
        onPressed: state.inputLocked ? null : () => _showItemsModal(ref),
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );

    bool hasHealingItem() {
      try {
        for (final it in InventoryService.inventory()) {
          final t = (it['type'] ?? '').toString();
          final q = (it['qty'] as int?) ?? 0;
          if (q <= 0) continue;
          final def = ItemCatalog.defOf(t);
          if (def == null) continue;
          if ((def.healInstant ?? 0) > 0 ||
              ((def.regenPerTurn ?? 0) > 0 && (def.regenTurns ?? 0) > 0)) {
            return true;
          }
        }
      } catch (_) {}
      return false;
    }

    final healAvailable = hasHealingItem();
    final below25 =
        state.playerMaxHp > 0 && (state.playerHp / state.playerMaxHp) <= 0.25;
    final shouldPulse = healAvailable && below25 && (state.result == null);
    if (shouldPulse) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      if (_pulseCtrl.isAnimating) _pulseCtrl.stop();
    }

    Widget quickHealButton() {
      final btn = PixelButton(
        label: 'Quick Heal',
        onPressed: healAvailable && !state.inputLocked
            ? () => ref.read(battleProvider.notifier).quickHeal()
            : null,
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
      if (!shouldPulse) return btn;
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (ctx, child) {
          final t = _pulseCtrl.value; // 0..1
          final w = 1.5 + 1.5 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
          final c = Colors.redAccent.withValues(alpha: 0.7);
          return Container(
            decoration: BoxDecoration(border: Border.all(color: c, width: w)),
            child: child,
          );
        },
        child: btn,
      );
    }

    Widget runAwayButton() {
      return PixelButton(
        label: 'Run Away',
        onPressed: state.inputLocked
            ? null
            : () async {
                final leave = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Leave Battle?'),
                        content: const Text(
                            'You can hide from your echoes, but you have to face them one day. Leave?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Stay')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Leave')),
                        ],
                      );
                    });
                if (leave == true && mounted) {
                  ref.read(battleProvider.notifier).escapeBattle();
                }
              },
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
    }

    final logList = Expanded(
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant)),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            for (final l in state.log) Text(l),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: !navigationLocked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && navigationLocked) {
          _showBattleLockedMessage();
        }
      },
      child: GameScaffold(
        title: 'Battle',
        padding: const EdgeInsets.all(12),
        lockNavigation: navigationLocked,
        navigationLockMessage: _battleLeaveMessage,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            topHud,
            const SizedBox(height: 8),
            battleArea,
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      skillsWrap,
                      const SizedBox(height: 8),
                      itemsOpenButton,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      spritesWrap,
                      const SizedBox(height: 8),
                      quickHealButton(),
                      const SizedBox(height: 8),
                      runAwayButton(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            logList,
          ],
        ),
      ),
    );
  }
}

// Highlight overlay removed per updated design

class _StatusTags extends StatelessWidget {
  final Map<String, int> statuses;
  final bool alignRight;
  const _StatusTags({required this.statuses, this.alignRight = false});
  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) return const SizedBox.shrink();
    final keys = statuses.keys.toList()..sort();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in keys) _StatusPill(keyName: k, turns: statuses[k] ?? 0),
      ].reversed.toList(growable: false),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String keyName;
  final int turns;
  const _StatusPill({required this.keyName, required this.turns});
  @override
  Widget build(BuildContext context) {
    final map = <String, Color>{
      'atk+': Colors.orange,
      'def+': Colors.blueGrey,
      'def-': Colors.redAccent,
      'regen': Colors.green,
      'guard': Colors.blue,
      'focus': Colors.purple,
      'spirit+': Colors.amber,
      'atk-': Colors.red,
      'poison': Colors.greenAccent,
    };
    final color = map[keyName] ?? Colors.white;
    final label = '$keyName${turns > 0 ? '($turns)' : ''}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;
  const _StatBar(
      {required this.label,
      required this.current,
      required this.max,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      height: 18,
      child: Stack(children: [
        Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant))),
        FractionallySizedBox(
            widthFactor: pct,
            child: Container(color: color.withValues(alpha: 0.8))),
        Positioned.fill(
            child: Center(
                child: Text('$label: $current/$max',
                    style: Theme.of(context).textTheme.labelSmall))),
      ]),
    );
  }
}
