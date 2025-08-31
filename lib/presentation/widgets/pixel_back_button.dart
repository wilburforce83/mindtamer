import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

    final Widget icon = _PixelBackIcon(size: size, color: c);

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
    // Draw on a 12x12 grid for a chunkier arrow
    final unit = (size.shortestSide / 12).floorToDouble().clamp(1.0, size.shortestSide);
    final offsetX = (size.width - unit * 12) / 2;
    final offsetY = (size.height - unit * 12) / 2;

    void px(int x, int y) {
      canvas.drawRect(Rect.fromLTWH(offsetX + x * unit, offsetY + y * unit, unit, unit), paint);
    }

    // Arrowhead (left-pointing) - thicker 2px diagonal around center
    // Upper diagonal
    px(8, 3); px(7, 4); px(6, 5); px(5, 6); px(6, 7); px(7, 8); px(8, 9);
    // Thicken
    px(8, 4); px(7, 5); px(6, 6); px(7, 7); px(8, 8);

    // Shaft (horizontal bar on the right)
    for (final y in [5, 6, 7]) {
      px(9, y); px(10, y);
    }
  }

  @override
  bool shouldRepaint(covariant _BackPixelPainter oldDelegate) => oldDelegate.color != color;
}
