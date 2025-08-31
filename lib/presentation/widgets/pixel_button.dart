import 'package:flutter/material.dart';
import '../../core/pixel_assets.dart';

class PixelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final bool primary;
  final Color? bgColor;
  final Color? fgColor;

  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.padding,
    this.primary = true,
    this.bgColor,
    this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final scheme = Theme.of(context).colorScheme;
    final bg = bgColor ?? (primary ? scheme.primary : scheme.surface);
    final fg = fgColor ?? (primary ? scheme.onPrimary : scheme.onSurface);

    final content = Center(
      child: Text(label, style: TextStyle(color: fg, fontSize: 12)),
    );

    // If button sprite exists, use nine-slice with centerSlice and nearest-neighbor.
    if (PixelAssets.has(PixelAssets.btnPrimary9Slice)) {
      return InkWell(
        onTap: onPressed,
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(PixelAssets.btnPrimary9Slice),
              centerSlice: Rect.fromLTWH(8, 8, 8, 8),
              filterQuality: FilterQuality.none,
            ),
          ),
          child: content,
        ),
      );
    }

    // Code-only pixel button with a lighter border derived from the bg color.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        overlayColor: WidgetStateProperty.resolveWith((states){
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.16);
          }
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return Colors.white.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
        onTap: onPressed,
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: enabled ? bg : bg.withValues(alpha: 0.5),
            border: Border.all(
              color: Color.lerp(enabled ? bg : bg.withValues(alpha: 0.5), Colors.white, 0.35)!,
              width: 1,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
