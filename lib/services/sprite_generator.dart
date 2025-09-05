import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';
import 'prng.dart';

class SpriteRender {
  final ui.Image staticFrame;
  final ui.Image? animatedSheet; // 8 frames horizontally (256x32)
  const SpriteRender({required this.staticFrame, this.animatedSheet});
}

class SpriteGenerator {
  Future<SpriteRender> generate(String seedName, int tier, List<int> argbRamp) async {
    final img = await _drawStatic(seedName, argbRamp, tier);
    // For v1 keep animation optional (null). Can be added later.
    return SpriteRender(staticFrame: img, animatedSheet: null);
  }

  Future<ui.Image> _drawStatic(String seedName, List<int> ramp, int tier) async {
    const int size = 32;
    const double half = size / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Deterministic RNG from seed + tier
    final rng = XorShift32(fnv1a32('${seedName.toLowerCase()}#$tier'));

    // Star params
    final int spikes = 4 + (rng.nextInt().abs() % 5); // 4..8
    final double baseR = 6.0 + (tier.clamp(0, 3)).toDouble();
    final double amp = 2 + (rng.nextInt().abs() % 4); // 2..5
    final double phase = (rng.nextDouble() * math.pi * 2);
    final double noiseAmp = 0.6 + rng.nextDouble() * 0.6; // subtle radial noise

    // Helper to get target radius for a given angle
    double radiusFor(double a) {
      final wave = math.sin(a * spikes + phase) * amp;
      final noise = (rng.nextDouble() - 0.5) * 2 * noiseAmp;
      return (baseR + wave + noise).clamp(3.0, 13.0);
    }

    // Draw core star field pixel-by-pixel
    final p = Paint()..isAntiAlias = false;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x + 0.5 - half;
        final dy = y + 0.5 - half;
        final ang = math.atan2(dy, dx);
        final r = math.sqrt(dx * dx + dy * dy);
        final R = radiusFor(ang);
        if (r <= R) {
          // radial gradient to pick ramp
          final t = (r / (R + 0.0001)).clamp(0.0, 1.0);
          int idx = (t * 4).round(); // 0..4
          if (idx < 0) {
            idx = 0;
          } else if (idx > 4) {
            idx = 4;
          }
          p.color = Color(ramp[idx]);
          canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), p);
        }
      }
    }

    // Add arms in 8 directions for a more sprite-like burst
    final dirs = <Offset>[
      const Offset(1, 0), const Offset(-1, 0), const Offset(0, 1), const Offset(0, -1),
      const Offset(1, 1), const Offset(-1, 1), const Offset(1, -1), const Offset(-1, -1),
    ];
    for (final d in dirs) {
      final len = 2 + (rng.nextInt().abs() % 6); // 2..7
      for (int i = 0; i < len; i++) {
        final xx = (half + d.dx * (baseR - 1 + i)).round();
        final yy = (half + d.dy * (baseR - 1 + i)).round();
        if (xx >= 0 && xx < size && yy >= 0 && yy < size) {
          p.color = Color(ramp[1]);
          canvas.drawRect(Rect.fromLTWH(xx.toDouble(), yy.toDouble(), 1, 1), p);
          if (i < 2 && (d.dx == 0 || d.dy == 0)) {
            // thicken cardinal near center
            if (xx + 1 < size) canvas.drawRect(Rect.fromLTWH(xx + 1.0, yy.toDouble(), 1, 1), p);
            if (yy + 1 < size) canvas.drawRect(Rect.fromLTWH(xx.toDouble(), yy + 1.0, 1, 1), p);
          }
        }
      }
    }

    // Sparkles around
    final sparkCount = 8 + (rng.nextInt().abs() % 9); // 8..16
    final sparkPaint = Paint()..isAntiAlias = false;
    for (int i = 0; i < sparkCount; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final dist = baseR + 4 + (rng.nextDouble() * 6);
      final sx = (half + math.cos(a) * dist).round();
      final sy = (half + math.sin(a) * dist).round();
      if (sx >= 0 && sx < size && sy >= 0 && sy < size) {
        sparkPaint.color = Color(ramp[rng.nextBool() ? 4 : 2]);
        canvas.drawRect(Rect.fromLTWH(sx.toDouble(), sy.toDouble(), 1, 1), sparkPaint);
      }
    }

    // Inner core highlight
    final core = Paint()..isAntiAlias = false..color = Color(ramp[4]);
    canvas.drawRect(const Rect.fromLTWH(half - 1, half - 1, 2, 2), core);

    final picture = recorder.endRecording();
    return picture.toImage(size, size);
  }
}
