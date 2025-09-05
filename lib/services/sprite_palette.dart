
class SpritePalette {
  static List<int> rampFromHue(int hue, {double sat = 0.85, double val = 0.95}) {
    // 5 shades from dark to light via value multipliers
    final multipliers = [0.25, 0.45, 0.65, 0.82, 1.0];
    return multipliers
        .map((m) => _hsvToArgb(hue.toDouble(), sat, (val * m).clamp(0.0, 1.0)))
        .toList();
  }

  static List<int> pickRampForSeed(String seed) {
    // Deterministic hue: map seed hash -> 0..359
    final h = (seed.toLowerCase().hashCode & 0x7fffffff) % 360;
    return rampFromHue(h);
  }

  static int _hsvToArgb(double h, double s, double v) {
    final c = v * s;
    final x = c * (1 - ((h / 60) % 2 - 1).abs());
    final m = v - c;
    double r = 0, g = 0, b = 0;
    if (0 <= h && h < 60) {
      r = c; g = x; b = 0;
    } else if (60 <= h && h < 120) {
      r = x; g = c; b = 0;
    } else if (120 <= h && h < 180) {
      r = 0; g = c; b = x;
    } else if (180 <= h && h < 240) {
      r = 0; g = x; b = c;
    } else if (240 <= h && h < 300) {
      r = x; g = 0; b = c;
    } else {
      r = c; g = 0; b = x;
    }
    int rr = ((r + m) * 255).round();
    int gg = ((g + m) * 255).round();
    int bb = ((b + m) * 255).round();
    int aa = 255;
    return (aa << 24) | (rr << 16) | (gg << 8) | bb;
  }
}
