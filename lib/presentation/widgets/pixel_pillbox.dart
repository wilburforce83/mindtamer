import 'package:flutter/material.dart';
import '../../core/pixel_assets.dart';
import '../../theme/colors.dart';

class PixelPillbox extends StatelessWidget {
  final List<String> slots;
  const PixelPillbox({super.key, required this.slots});
  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in slots)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              border: const Border.fromBorderSide(BorderSide(color: AppColors.outline, width: 1)),
              image: PixelAssets.has(PixelAssets.pillCell32)
                  ? const DecorationImage(
                      image: AssetImage(PixelAssets.pillCell32),
                      centerSlice: Rect.fromLTWH(8, 8, 16, 16),
                      filterQuality: FilterQuality.none,
                      fit: BoxFit.fill,
                    )
                  : null,
            ),
            child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
