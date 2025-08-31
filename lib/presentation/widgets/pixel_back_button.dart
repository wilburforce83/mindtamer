import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/pixel_assets.dart';
import '../../theme/colors.dart';

class PixelBackButton extends StatelessWidget {
  final double size;
  final Color? color;
  const PixelBackButton({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop) return const SizedBox.shrink();
    final c = color ?? Theme.of(context).appBarTheme.foregroundColor ?? AppColors.onBackground;

    Widget icon;
    if (PixelAssets.has(PixelAssets.backIcon24)) {
      icon = ImageIcon(const AssetImage(PixelAssets.backIcon24), size: size, color: c);
    } else {
      icon = _PixelBackIcon(size: size, color: c);
    }

    return IconButton(
      tooltip: 'Back',
      icon: icon,
      onPressed: () {
        if (Navigator.of(context).canPop()) context.pop();
      },
    );
  }
}

class _PixelBackIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _PixelBackIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BackPixelPainter(color: color),
      ),
    );
  }
}

class _BackPixelPainter extends CustomPainter {
  final Color color;
  const _BackPixelPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // Draw on an 8x8 grid, scaled to the requested size.
    final unit = (size.shortestSide / 8).floorToDouble().clamp(1.0, size.shortestSide);
    final offsetX = (size.width - unit * 8) / 2;
    final offsetY = (size.height - unit * 8) / 2;

    void px(int x, int y) {
      canvas.drawRect(Rect.fromLTWH(offsetX + x * unit, offsetY + y * unit, unit, unit), paint);
    }

    // Left-pointing arrow made of pixels
    // Diagonal
    px(5, 1); px(4, 2); px(3, 3); px(2, 4); px(3, 5); px(4, 6); px(5, 7);
    // Tail
    px(6, 3); px(6, 4); px(6, 5);
  }

  @override
  bool shouldRepaint(covariant _BackPixelPainter oldDelegate) => oldDelegate.color != color;
}
