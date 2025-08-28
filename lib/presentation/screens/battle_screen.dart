import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/gameplay/battle_notifier.dart';
class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref){
    final state = ref.watch(battleProvider);
    return Scaffold(appBar: AppBar(title: const Text('Battle')), body: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text('You: ${state.playerHp}   Daemon: ${state.daemonHp}'),
      const SizedBox(height:8),
      Row(children:[
        ElevatedButton(onPressed: ()=>ref.read(battleProvider.notifier).basicAttack(), child: const Text('Attack')),
        const SizedBox(width:8),
        ElevatedButton(onPressed: ()=>ref.read(battleProvider.notifier).daemonTurn(), child: const Text('End Turn')),
        const SizedBox(width:8),
        ElevatedButton(onPressed: ()=>ref.read(battleProvider.notifier).reset(), child: const Text('Reset')),
      ]),
      const Divider(),
      const Text('Battle Log:'),
      Expanded(child: ListView(children:[for(final l in state.log) Text(l)])),
    ])));
  }
}
