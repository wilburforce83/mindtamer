import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pixelate.dart';

/// Programmatic wisp-like icon used for Resonant Echoes.
/// Color is derived from element/colorHex; shape variant seeded by [seed].
class EchoWispIcon extends StatelessWidget {
  final Color color;
  final String seed;
  final double size;
  final bool pixelate; // render as pixel art
  final int pixels; // resolution when pixelated
  const EchoWispIcon({
    super.key,
    required this.color,
    required this.seed,
    this.size = 32,
    this.pixelate = false,
    this.pixels = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Slightly vary hue/brightness by seed
    final v = seed.hashCode & 0x7fffffff;
    final hueShift = ((v % 24) - 12) / 360.0; // -12..+12 degrees
    final hsl = HSLColor.fromColor(color);
    final c = hsl.withHue((hsl.hue + hueShift * 360) % 360).toColor();
    final painter = CustomPaint(size: Size.square(size), painter: _WispPainter(c, v));
    if (!pixelate) return painter;
    return Pixelate(
      size: size,
      pixels: pixels,
      watch: '$seed:${color.toARGB32()}:${size.toStringAsFixed(2)}:$pixels:$pixelate',
      child: painter,
    );
  }
}

class _WispPainter extends CustomPainter {
  final Color color; final int seed;
  _WispPainter(this.color, this.seed);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = size.width * 0.32;
    // Glow
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.6, glow);
    // Core
    final core = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, core);
    // Ring
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;
    canvas.drawCircle(center, radius * 0.85, ring);
    // Tail (wavy) — seeded rotation
    final rnd = (seed % 360) * math.pi / 180.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rnd);
    final tail = Path();
    tail.moveTo(0, radius*0.8);
    tail.cubicTo(size.width*0.10, radius*1.2, -size.width*0.08, radius*1.5, 0, radius*1.9);
    final tailPaint = Paint()
      ..shader = LinearGradient(colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(-size.width/2, 0, size.width, size.height))
      ..strokeWidth = size.width*0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tail, tailPaint);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _WispPainter oldDelegate) => oldDelegate.color != color || oldDelegate.seed != seed;
}
