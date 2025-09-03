import 'package:flutter/material.dart';
import '../../data/repos/equipment_repo.dart';
import '../../core/pixel_assets.dart';

class GearSlot extends StatelessWidget {
  final String slotId; // head, weapon, etc.
  final EquippedItem? item;
  final VoidCallback onTap;
  final double size; // visual box size (e.g., 64)
  const GearSlot({super.key, required this.slotId, required this.item, required this.onTap, this.size = 64});

  Color _rarityColor(BuildContext context, String? rarity) {
    switch (rarity) {
      case 'uncommon':
        return Colors.blueAccent;
      case 'rare':
        return Colors.purpleAccent;
      case 'epic':
        return Colors.orangeAccent;
      default:
        return Theme.of(context).colorScheme.outlineVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasItem = item != null;
    final borderColor = _rarityColor(context, item?.rarity);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          border: Border.all(color: borderColor, width: 1.2),
          borderRadius: BorderRadius.zero,
        ),
        child: hasItem
            ? Icon(Icons.check, size: size * 0.5) // placeholder for future 64x64 item art
            : _emptyVisual(slotId, size, context),
      ),
    );
  }

  Widget _emptyVisual(String slotId, double size, BuildContext context) {
    final asset = PixelAssets.emptyAssetForSlot(slotId);
    if (asset != null) {
      _debugLogOnce('GearSlot:$slotId uses empty asset: $asset (inManifest=${PixelAssets.has(asset)})');
      final slots = PixelAssets.listSlotPlaceholders();
      _debugLogOnce('Slots in manifest: ${slots.join(', ')}');
      return Image.asset(
        asset,
        width: size * 0.8,
        height: size * 0.8,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, error, stack) {
          _debugLogOnce('Failed to load $asset: $error');
          return Icon(Icons.stop_rounded, size: size * 0.4, color: Theme.of(context).colorScheme.outline);
        },
      );
    }
    return Icon(Icons.stop_rounded, size: size * 0.4, color: Theme.of(context).colorScheme.outline);
  }

  static final Set<String> _logged = <String>{};
  void _debugLogOnce(String msg) {
    if (_logged.add(msg)) {
      // ignore: avoid_print
      print(msg);
    }
  }
}
