import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/gameplay/battle_notifier.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/pixel_button.dart';
class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final state = ref.watch(battleProvider);
    return GameScaffold(title: 'Battle', padding: const EdgeInsets.all(12), body: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text('You: ${state.playerHp}   Daemon: ${state.daemonHp}'),
      const SizedBox(height:8),
      Row(children:[
        PixelButton(onPressed: ()=>ref.read(battleProvider.notifier).basicAttack(), label: 'Attack'),
        const SizedBox(width:8),
        PixelButton(onPressed: ()=>ref.read(battleProvider.notifier).daemonTurn(), label: 'End Turn'),
        const SizedBox(width:8),
        PixelButton(onPressed: ()=>ref.read(battleProvider.notifier).reset(), label: 'Reset'),
      ]),
      const Divider(),
      const Text('Battle Log:'),
      Expanded(child: ListView(children:[for(final l in state.log) Text(l)])),
    ]));
  }
}
