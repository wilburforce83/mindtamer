import 'package:flutter/material.dart';
import '../../data/hive/boxes.dart';

class SummonsScreen extends StatelessWidget {
  const SummonsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final list = seedInstanceBox().values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Summons')),
      body: list.isEmpty
          ? const Center(child: Text('No sprites owned yet'))
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = list[i];
                final name = (s.seedSnapshot['displayName'] ?? 'Sprite').toString();
                final element = (s.seedSnapshot['element'] ?? '').toString();
                final rarity = (s.seedSnapshot['rarity'] ?? '').toString();
                return ListTile(
                  title: Text(name),
                  subtitle: Text('$element • $rarity'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Equip into selected sprite slot
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}

