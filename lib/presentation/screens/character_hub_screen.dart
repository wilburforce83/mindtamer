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
    final gearOrder = [
      'head','shoulders','neck','weapon',
      'hands','bracers','ringLeft','chest','ringRight',
      'legs','feet',
    ];

    return GameScaffold(
      title: 'Character',
      body: RefreshIndicator(
        onRefresh: vm.refreshTickets,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('Character', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.0),
                      itemCount: gearOrder.length,
                      itemBuilder: (_, i) {
                        final slot = gearOrder[i];
                        return GearSlot(
                          slotId: slot,
                          item: state.gear[slot],
                          onTap: () => context.push('/items', extra: {'slot': slot}),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
