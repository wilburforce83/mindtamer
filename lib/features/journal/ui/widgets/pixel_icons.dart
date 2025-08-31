// FILE: lib/features/journal/ui/widgets/pixel_icons.dart
import 'package:flutter/material.dart';

abstract class _PixelIconBase extends StatelessWidget {
  final double? size;
  final Color? color;
  const _PixelIconBase({super.key, this.size, this.color});

  CustomPainter painter(Color color);

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final s = size ?? iconTheme.size ?? 24;
    final c = color ?? iconTheme.color ?? Colors.white;
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(painter: painter(c)),
    );
  }
}

class PixelSearchIcon extends _PixelIconBase {
  const PixelSearchIcon({super.key, double? size, Color? color}) : super(size: size, color: color);
  @override
  CustomPainter painter(Color color) => _SearchPainter(color);
}

class PixelEditIcon extends _PixelIconBase {
  const PixelEditIcon({super.key, double? size, Color? color}) : super(size: size, color: color);
  @override
  CustomPainter painter(Color color) => _EditPainter(color);
}

class PixelDeleteIcon extends _PixelIconBase {
  const PixelDeleteIcon({super.key, double? size, Color? color}) : super(size: size, color: color);
  @override
  CustomPainter painter(Color color) => _DeletePainter(color);
}

class PixelCloseIcon extends _PixelIconBase {
  const PixelCloseIcon({super.key, double? size, Color? color}) : super(size: size, color: color);
  @override
  CustomPainter painter(Color color) => _ClosePainter(color);
}

// Simple 12x12 pixel-grid painters
class _SearchPainter extends CustomPainter {
  final Color color;
  const _SearchPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final u = (size.shortestSide / 12).floorToDouble().clamp(1.0, size.shortestSide);
    final ox = (size.width - u * 12) / 2;
    final oy = (size.height - u * 12) / 2;
    void px(int x, int y) => canvas.drawRect(Rect.fromLTWH(ox + x * u, oy + y * u, u, u), paint);
    // Circle approx
    for (final p in [
      [4, 3], [5, 3], [6, 3],
      [3, 4], [7, 4],
      [3, 5], [7, 5],
      [3, 6], [7, 6],
      [4, 7], [5, 7], [6, 7],
    ]) px(p[0], p[1]);
    // Handle
    px(8, 8); px(9, 9); px(10, 10);
  }
  @override
  bool shouldRepaint(covariant _SearchPainter old) => old.color != color;
}

class _EditPainter extends CustomPainter {
  final Color color;
  const _EditPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final u = (size.shortestSide / 12).floorToDouble().clamp(1.0, size.shortestSide);
    final ox = (size.width - u * 12) / 2;
    final oy = (size.height - u * 12) / 2;
    void px(int x, int y) => canvas.drawRect(Rect.fromLTWH(ox + x * u, oy + y * u, u, u), p);
    // Pencil oriented bottom-left to top-right
    // Tip
    px(2, 10); px(3, 9);
    // Shaft (2px thick diagonal)
    for (int i = 0; i < 6; i++) {
      px(4 + i, 8 - i);
      px(4 + i, 7 - i);
    }
    // Eraser block at top-right
    for (int x = 10; x <= 11; x++) {
      for (int y = 1; y <= 2; y++) {
        px(x, y);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _EditPainter old) => old.color != color;
}

class _DeletePainter extends CustomPainter {
  final Color color;
  const _DeletePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final u = (size.shortestSide / 12).floorToDouble().clamp(1.0, size.shortestSide);
    final ox = (size.width - u * 12) / 2;
    final oy = (size.height - u * 12) / 2;
    void px(int x, int y) => canvas.drawRect(Rect.fromLTWH(ox + x * u, oy + y * u, u, u), p);
    // Lid
    for (int x = 3; x <= 8; x++) px(x, 2);
    for (int x = 4; x <= 7; x++) px(x, 3);
    // Body
    for (int y = 4; y <= 10; y++) { px(3, y); px(8, y); }
    for (int x = 4; x <= 7; x++) { px(x, 10); }
    // Handle
    px(5, 1); px(6, 1);
    // Stripes
    for (int y = 5; y <= 9; y++) { px(4, y); px(6, y); }
  }
  @override
  bool shouldRepaint(covariant _DeletePainter old) => old.color != color;
}

class _ClosePainter extends CustomPainter {
  final Color color;
  const _ClosePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final u = (size.shortestSide / 12).floorToDouble().clamp(1.0, size.shortestSide);
    final ox = (size.width - u * 12) / 2;
    final oy = (size.height - u * 12) / 2;
    void px(int x, int y) => canvas.drawRect(Rect.fromLTWH(ox + x * u, oy + y * u, u, u), p);
    // Diagonal top-left to bottom-right
    for (int i = 3; i <= 8; i++) { px(i, i); }
    // Diagonal top-right to bottom-left
    for (int i = 3; i <= 8; i++) { px(11 - i, i); }
  }
  @override
  bool shouldRepaint(covariant _ClosePainter old) => old.color != color;
}
