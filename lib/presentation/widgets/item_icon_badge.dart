import 'package:flutter/material.dart';
import '../../crafting/models.dart';
import '../../theme/colors.dart';

class ItemIconBadge extends StatelessWidget {
  final String iconPath;
  final Rarity rarity;
  final ElementType element;
  final int tier;
  final double size;
  final bool showTier;
  final bool framed; // draw internal border/frame
  const ItemIconBadge({
    super.key,
    required this.iconPath,
    required this.rarity,
    required this.element,
    required this.tier,
    this.size = 32,
    this.showTier = true,
    this.framed = true,
  });

  @override
  Widget build(BuildContext context) {
    final border = _rarityColor(rarity);
    final elem = _elementColor(element);
    String fallbackAsset(String path) {
      final p = path.toLowerCase();
      if (p.contains('ring')) {
        return 'assets/images/ui/slots/ring_empty_32.png';
      }
      if (p.contains('hand') || p.contains('hands')) {
        return 'assets/images/ui/slots/hand_empty_32.png';
      }
      return 'assets/images/ui/slots/chest_empty_32.png';
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: [
        // Subtle radial element highlight
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    elem.withValues(alpha: 0.22),
                    elem.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                  center: Alignment.center,
                  radius: 0.85,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Image.asset(
            iconPath,
            filterQuality: FilterQuality.none,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              // ignore: avoid_print
              print('[ItemIconBadge] Missing asset: $iconPath — falling back');
              return Image.asset(fallbackAsset(iconPath),
                  filterQuality: FilterQuality.none, fit: BoxFit.contain);
            },
          ),
        ),
        if (framed)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: border, width: 1.0),
                ),
              ),
            ),
          ),
        if (showTier)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: (size * 0.08).clamp(2, 4),
                vertical: (size * 0.02).clamp(1, 2),
              ),
              decoration: BoxDecoration(
                color: AppColors.panel.withValues(alpha: 0.74),
                border: Border.all(color: AppColors.outlineBright, width: 0.75),
              ),
              child: Text(
                'T$tier',
                style: TextStyle(
                  fontSize: (size * 0.18).clamp(5, 8).toDouble(),
                  color: AppColors.ivory,
                  height: 1,
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Color _rarityColor(Rarity r) {
    return AppColors.rarityColorByName(r.name);
  }

  Color _elementColor(ElementType e) {
    return AppColors.elementColorByName(e.name);
  }
}
