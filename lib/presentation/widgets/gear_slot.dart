import 'package:flutter/material.dart';
import '../../data/repos/equipment_repo.dart';

class GearSlot extends StatelessWidget {
  final String slotId; // head, weapon, etc.
  final EquippedItem? item;
  final VoidCallback onTap;
  const GearSlot({super.key, required this.slotId, required this.item, required this.onTap});

  String _toTitle(String s) {
    switch (s) {
      case 'ringLeft':
        return 'Ring (L)';
      case 'ringRight':
        return 'Ring (R)';
      default:
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _toTitle(slotId);
    final hasItem = item != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Placeholder(fallbackHeight: 32, fallbackWidth: 32),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            if (hasItem) ...[
              const SizedBox(height: 4),
              Text(item!.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

