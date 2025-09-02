import 'package:flutter/material.dart';
import '../../data/hive/boxes.dart';

class MonsterCodexScreen extends StatelessWidget {
  const MonsterCodexScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final list = monsterCodexBox().values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Monster Codex')),
      body: list.isEmpty
          ? const Center(child: Text('Defeat a monster to discover it.'))
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  title: Text(c.speciesId),
                  subtitle: Text('Defeated: ${c.defeatedCount}'),
                );
              },
            ),
    );
  }
}

