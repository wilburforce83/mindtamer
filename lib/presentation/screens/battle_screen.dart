import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/gameplay/battle_notifier.dart';
import '../../game/services/player_image_service.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/pixel_button.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final String? battleId;
  const BattleScreen({super.key, this.battleId});
  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> with TickerProviderStateMixin {
  Future<ui.Image?>? _playerImgFut;
  // Overlay flash
  late final AnimationController _overlayFlash;
  // Manual frame-based movement
  Offset _playerOffset = Offset.zero;
  Offset _enemyOffset = Offset.zero;
  int _lastActionSeq = 0;
  int _lastLogLen = 0;
  String? _floatText;
  Alignment _floatAlign = Alignment.center;
  Color _floatColor = Colors.white;
  DateTime _floatUntil = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    if (widget.battleId != null) {
      Future.microtask(() => ref.read(battleProvider.notifier).init(battleId: widget.battleId!));
    }
    _playerImgFut = PlayerImageService().renderCurrentPlayer();
    _overlayFlash = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

  }

  void _runActionAnim(Map<String, dynamic> action) async {
    // Flash overlay
    _overlayFlash.stop();
    _overlayFlash.reset();
    _overlayFlash.forward().then((_) => _overlayFlash.reverse());

    final attacker = (action['attacker'] ?? 'player') as String;
    final target = (action['target'] ?? 'enemy') as String;
    final melee = (action['melee'] ?? false) as bool;
    final box = context.size; // might be null at init; compute lunge distance from MediaQuery if so
    final w = (box?.width ?? MediaQuery.of(context).size.width);
    final double lungeDist = w * 0.12;

    // Sequence: lunge (if melee) then shake target; 5 frames total each
    if (melee) {
      if (attacker == 'player') {
        await _runFrames(true, [
          Offset(lungeDist * 0.25, 0),
          Offset(lungeDist * 0.5, 0),
          Offset(lungeDist * 0.9, 0),
          Offset(lungeDist * 0.5, 0),
          Offset.zero,
        ]);
      } else {
        await _runFrames(false, [
          Offset(-lungeDist * 0.25, 0),
          Offset(-lungeDist * 0.5, 0),
          Offset(-lungeDist * 0.9, 0),
          Offset(-lungeDist * 0.5, 0),
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
    _overlayFlash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(battleProvider);

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
        _floatAlign = (state.lastAction!['target'] == 'enemy') ? Alignment.bottomRight : Alignment.bottomLeft;
        _floatUntil = DateTime.now().add(const Duration(milliseconds: 700));
      }
      _lastLogLen = state.log.length;
    }

    // Outcome routing (only for this battleId)
    if (state.result != null && state.battleId == widget.battleId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.result == 'win' ? 'Victory! Loot added.' : 'Defeat.')));
        // Return to home
        Navigator.of(context).pop();
      });
    }

    final topHud = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatBar(label: 'HP', current: state.playerHp, max: state.playerMaxHp, color: Colors.redAccent),
        const SizedBox(height: 6),
        _StatBar(label: state.enemyName ?? 'Enemy', current: state.enemyHp, max: state.enemyMaxHp, color: Colors.teal),
      ],
    );

    final battleArea = AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (state.backgroundAsset.isNotEmpty)
            Image.asset(state.backgroundAsset, fit: BoxFit.cover, filterQuality: FilterQuality.none),
          // Foreground: player left, enemy right
          // Foreground combatants with transforms (shake/lunge)
          LayoutBuilder(builder: (context, cts) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: _playerOffset,
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
                          return RawImage(image: img, filterQuality: FilterQuality.none, fit: BoxFit.contain);
                        },
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: _enemyOffset,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: state.enemyAssetPath != null
                          ? Image.asset(state.enemyAssetPath!, filterQuality: FilterQuality.none, fit: BoxFit.contain)
                          : Center(child: Text(state.enemyName ?? 'Enemy', style: Theme.of(context).textTheme.titleSmall)),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Attack overlay stub tinted by element
          if (state.lastAction != null)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: FadeTransition(
                  opacity: _overlayFlash.drive(Tween<double>(begin: 0.0, end: 0.7)),
                  child: _AttackOverlay(target: state.lastAction!['target'] == 'enemy' ? Alignment.bottomRight : Alignment.bottomLeft, element: state.lastAction!['element'] as String?),
                ),
              ),
            ),
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
                padding: const EdgeInsets.only(bottom: 120, left: 24, right: 24),
                child: Text(_floatText!, style: TextStyle(color: _floatColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );

    final skills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < state.skills.length; i++)
          PixelButton(
            label: state.skillCooldowns.elementAt(i) > 0 ? '${state.skills[i]} (${state.skillCooldowns[i]})' : state.skills[i],
            onPressed: state.skillCooldowns.elementAt(i) > 0 ? null : () => ref.read(battleProvider.notifier).useSkill(i),
          ),
        for (int i = 0; i < state.sprites.length; i++)
          PixelButton(
            label: state.spriteCooldowns.elementAt(i) > 0 ? '${state.sprites[i]} (${state.spriteCooldowns[i]})' : state.sprites[i],
            onPressed: state.spriteCooldowns.elementAt(i) > 0 ? null : () => ref.read(battleProvider.notifier).useSprite(i),
            primary: false,
          ),
      ],
    );

    final items = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < state.quickItems.length && i < 4; i++)
          SizedBox(
            width: 140,
            child: PixelButton(
              label: '${state.quickItems[i]['label']} x${state.quickItems[i]['qty']}',
              onPressed: (state.quickItems[i]['qty'] as int) > 0 ? () => ref.read(battleProvider.notifier).useItem(i) : null,
              primary: false,
            ),
          ),
      ],
    );

    final logList = Expanded(
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            for (final l in state.log) Text(l),
          ],
        ),
      ),
    );

    return GameScaffold(
      title: 'Battle',
      padding: const EdgeInsets.all(12),
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
              Expanded(flex: 2, child: skills),
              const SizedBox(width: 8),
              Expanded(child: items),
            ],
          ),
          const SizedBox(height: 8),
          logList,
        ],
      ),
    );
  }
}

class _AttackOverlay extends StatelessWidget {
  final Alignment target; // where to place splash (approx near actor)
  final String? element;
  const _AttackOverlay({required this.target, this.element});
  @override
  Widget build(BuildContext context) {
    final color = _elementColor(element);
    return Align(
      alignment: target,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
        ),
      ),
    );
  }
}

Color _elementColor(String? e) {
  switch ((e ?? '').toLowerCase()) {
    case 'fire': return const Color(0xFFF27961);
    case 'water': return const Color(0xFF0B8BE6);
    case 'air': return const Color(0xFFA3CCD9);
    case 'nature': return const Color(0xFF119955);
    case 'metal': return const Color(0xFF4D7A99);
    case 'light': return const Color(0xFFF7C93E);
    case 'shadow': return const Color(0xFF343473);
    default: return Colors.white;
  }
}

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
  const _StatBar({required this.label, required this.current, required this.max, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      height: 18,
      child: Stack(children: [
        Container(decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant))),
        FractionallySizedBox(widthFactor: pct, child: Container(color: color.withValues(alpha: 0.8))),
        Positioned.fill(child: Center(child: Text('$label: $current/$max', style: Theme.of(context).textTheme.labelSmall))),
      ]),
    );
  }
}
