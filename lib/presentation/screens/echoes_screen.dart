import 'package:flutter/material.dart';
import '../../data/hive/boxes.dart';

class EchoesScreen extends StatelessWidget {
  const EchoesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final list = resonantEchoBox().values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Resonant Echoes')),
      body: list.isEmpty
          ? const Center(child: Text('No echoes yet'))
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = list[i];
                return ListTile(
                  title: Text(e.title),
                  subtitle: Text('${e.element} • ${e.rarity}'),
                );
              },
            ),
    );
  }
}

