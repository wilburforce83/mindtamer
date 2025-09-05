import 'package:flutter/material.dart';
import '../../models/sprite_model.dart';

class SpriteDetailsPanel extends StatelessWidget {
  final SpriteModel? selected;
  final VoidCallback onEquip;
  final VoidCallback onFuse;
  final String? seedTitle;
  final String? primaryTag;
  const SpriteDetailsPanel({super.key, required this.selected, required this.onEquip, required this.onFuse, this.seedTitle, this.primaryTag});

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const Text('Tap a sprite to see details'),
      );
    }
    final s = selected!;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seed: ${seedTitle ?? s.seedName}${primaryTag!=null ? ' • #$primaryTag' : ''}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('Tier: ${s.tier==0 ? 'Base' : 'T${s.tier}'} • Rarity: ${s.rarity}'),
          const SizedBox(height: 4),
          Text('Attack: ${s.attack.name}'),
          Text(s.attack.description),
          const Spacer(),
          Row(children: [
            ElevatedButton(onPressed: onEquip, child: const Text('Equip')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: onFuse, child: const Text('Fuse…')),
          ])
        ],
      ),
    );
  }
}
