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

class CharacterHubScreen extends StatefulWidget {
  const CharacterHubScreen({super.key});
  @override
  State<CharacterHubScreen> createState() => _CharacterHubScreenState();
}

class _CharacterHubScreenState extends State<CharacterHubScreen> {
  late final CharacterHubVM vm;

  @override
  void initState() {
    super.initState();
    vm = context.read<CharacterHubVM>();
    vm.load();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CharacterHubVM>().state;

    return GameScaffold(
      title: 'Character',
      body: RefreshIndicator(
        onRefresh: vm.refreshTickets,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LayoutBuilder(
              builder: (ctx, c) {
                final w = c.maxWidth;
                // Target about 60% of viewport height, capped by an aspect-based height
                double h = w * 1.2; // slightly shorter than before to reduce vertical footprint
                final maxH = MediaQuery.of(context).size.height * 0.60;
                if (h > maxH) h = maxH;
                final boxSize = w < 420 ? 56.0 : 64.0;
                final sideInset = w * 0.08;
                return SizedBox(
                  height: h,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Character center box
                      Container(
                        width: w * 0.42,
                        height: h * 0.38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text('Character', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      ),

                      // Left column (top→bottom): head, chest, hands, legs, feet
                      Positioned(
                        top: 6,
                        left: sideInset,
                        child: GearSlot(slotId: 'head', item: state.gear['head'], onTap: () => context.push('/items', extra: {'slot': 'head'}), size: boxSize),
                      ),
                      Positioned(
                        top: h * 0.36,
                        left: sideInset,
                        child: GearSlot(slotId: 'chest', item: state.gear['chest'], onTap: () => context.push('/items', extra: {'slot': 'chest'}), size: boxSize),
                      ),
                      Positioned(
                        top: h * 0.52,
                        left: sideInset,
                        child: GearSlot(slotId: 'hands', item: state.gear['hands'], onTap: () => context.push('/items', extra: {'slot': 'hands'}), size: boxSize),
                      ),
                      Positioned(
                        top: h * 0.70,
                        left: sideInset,
                        child: GearSlot(slotId: 'legs', item: state.gear['legs'], onTap: () => context.push('/items', extra: {'slot': 'legs'}), size: boxSize),
                      ),
                      Positioned(
                        bottom: 6,
                        left: sideInset,
                        child: GearSlot(slotId: 'feet', item: state.gear['feet'], onTap: () => context.push('/items', extra: {'slot': 'feet'}), size: boxSize),
                      ),

                      // Right column (top→bottom): neck, rings, weapon
                      Positioned(
                        top: 6,
                        right: sideInset,
                        child: GearSlot(slotId: 'neck', item: state.gear['neck'], onTap: () => context.push('/items', extra: {'slot': 'neck'}), size: boxSize),
                      ),
                      Positioned(
                        top: h * 0.32,
                        right: sideInset,
                        child: GearSlot(slotId: 'ringLeft', item: state.gear['ringLeft'], onTap: () => context.push('/items', extra: {'slot': 'ringLeft'}), size: boxSize),
                      ),
                      Positioned(
                        top: h * 0.48,
                        right: sideInset,
                        child: GearSlot(slotId: 'ringRight', item: state.gear['ringRight'], onTap: () => context.push('/items', extra: {'slot': 'ringRight'}), size: boxSize),
                      ),
                      Positioned(
                        bottom: 6,
                        right: sideInset,
                        child: GearSlot(slotId: 'weapon', item: state.gear['weapon'], onTap: () => context.push('/items', extra: {'slot': 'weapon'}), size: boxSize),
                      ),

                      // Sprite slots: two boxes below the character box (centered)
                      Positioned(
                        top: h * 0.74,
                        left: (w / 2) - boxSize - 8,
                        child: GearSlot(slotId: 'sprite1', item: null, onTap: () => context.push('/summons'), size: boxSize),
                      ),
                      Positioned(
                        top: h * 0.74,
                        left: (w / 2) + 8,
                        child: GearSlot(slotId: 'sprite2', item: null, onTap: () => context.push('/summons'), size: boxSize),
                      ),
                    ],
                  ),
                );
              },
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

            const SizedBox(height: 20),

            FilledButton(
              onPressed: state.openTickets > 0
                  ? () async {
                      final encounters = context.read<EncountersRepo>();
                      final id = await encounters.getFirstOpenTicketId();
                      if (id == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No open encounters.')));
                        return;
                      }
                      // Optional: start battle shell
                      try {
                        final battleId = await BattleServiceImpl(codex: CodexServiceImpl(), echo: EchoServiceImpl()).start(id);
                        if (!context.mounted) return;
                        await _showBattleStub(battleId);
                        await vm.refreshTickets();
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Battle flow not ready')));
                      }
                    }
                  : null,
              child: Text(state.openTickets > 0 ? 'Battle Now' : 'No Battles Available'),
            ),

            const SizedBox(height: 8),
            Text(
              'Win battles to unlock Codex entries and roll for Resonant Echoes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBattleStub(String battleId) async {
    int turns = 3;
    String result = 'win';
    bool flawless = true;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Battle (Stub)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: result,
                items: const [
                  DropdownMenuItem(value: 'win', child: Text('Win')),
                  DropdownMenuItem(value: 'loss', child: Text('Loss')),
                  DropdownMenuItem(value: 'escape', child: Text('Escape')),
                ],
                onChanged: (v) { if (v != null) { setState(() => result = v); } },
              ),
              Row(children: [ const Text('Turns:'), const SizedBox(width: 8), Expanded(child: Slider(value: turns.toDouble(), min: 1, max: 20, divisions: 19, label: '$turns', onChanged: (v){ setState(()=>turns = v.round()); })) ]),
              Row(children: [ const Text('Flawless:'), Switch(value: flawless, onChanged: (v){ setState(()=>flawless = v); }) ]),
            ],
          ),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () async {
              await BattleServiceImpl(codex: CodexServiceImpl(), echo: EchoServiceImpl()).resolve(battleId: battleId, result: result, turnCount: turns, flawless: flawless);
              if (context.mounted) Navigator.pop(ctx);
            }, child: const Text('Resolve')),
          ],
        ),
      ),
    );
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
