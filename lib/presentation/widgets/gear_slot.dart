import 'package:flutter/material.dart';
import '../../data/repos/equipment_repo.dart';
import '../../core/pixel_assets.dart';
import '../../crafting/inventory_service.dart';
import '../../theme/colors.dart';
import 'item_icon_badge.dart';

class GearSlot extends StatelessWidget {
  final String slotId; // head, weapon, etc.
  final EquippedItem? item;
  final VoidCallback onTap;
  final double size; // visual box size (e.g., 64)
  const GearSlot(
      {super.key,
      required this.slotId,
      required this.item,
      required this.onTap,
      this.size = 64});

  Color _rarityColor(BuildContext context, String? rarity) {
    if (rarity == null || rarity.isEmpty || rarity == 'common') {
      return AppColors.outlineBright.withValues(alpha: 0.58);
    }
    return AppColors.rarityColorByName(rarity);
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
          color: AppColors.panelSoft.withValues(alpha: 0.34),
          border: Border.all(color: borderColor, width: 1.2),
          borderRadius: BorderRadius.zero,
          boxShadow: hasItem
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.16),
                    blurRadius: 0,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: hasItem
            ? _equippedVisual(context)
            : _emptyVisual(slotId, size, context),
      ),
    );
  }

  Widget _equippedVisual(BuildContext context) {
    final e = item;
    if (e == null) return const SizedBox.shrink();
    final crafted = CraftedInventoryService.getById(e.id);
    if (crafted != null) {
      return ItemIconBadge(
        iconPath: crafted.def.iconPath,
        rarity: crafted.rarity,
        element: crafted.element,
        tier: crafted.tier,
        size: size * 0.82,
        framed: false, // no internal frame; border is on the slot
      );
    }
    // Fallback minimal mark if we don't know the crafted item
    return Icon(Icons.check, size: size * 0.5, color: AppColors.mutedAlt);
  }

  Widget _emptyVisual(String slotId, double size, BuildContext context) {
    final asset = PixelAssets.emptyAssetForSlot(slotId);
    if (asset != null) {
      _debugLogOnce(
          'GearSlot:$slotId uses empty asset: $asset (inManifest=${PixelAssets.has(asset)})');
      final slots = PixelAssets.listSlotPlaceholders();
      _debugLogOnce('Slots in manifest: ${slots.join(', ')}');
      return Image.asset(
        asset,
        width: size * 0.8,
        height: size * 0.8,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, error, stack) {
          _debugLogOnce('Failed to load $asset: $error');
          return Icon(Icons.stop_rounded,
              size: size * 0.4, color: Theme.of(context).colorScheme.outline);
        },
      );
    }
    return Icon(Icons.stop_rounded,
        size: size * 0.4, color: Theme.of(context).colorScheme.outline);
  }

  static final Set<String> _logged = <String>{};
  void _debugLogOnce(String msg) {
    if (_logged.add(msg)) {
      // ignore: avoid_print
      print(msg);
    }
  }
}
