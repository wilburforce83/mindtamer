import 'dart:collection';
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import '../../data/hive/boxes.dart';

class PlayerImageService {
  static const int _zoneNone = 0;
  static const int _zoneHair = 1;
  static const int _zoneSkin = 2;
  static const int _zoneWeapon = 3;

  // Authoring key ramps (exact source colors in the PNGs)
  // Authoring 3-step ramps per latest art spec
  static const List<int> _hairKeys = [
    0xFFFF007F, 0xFFFF3399, 0xFFFF66B2,
  ];
  static const List<int> _skinKeys = [
    0xFF6E00FF, 0xFF8C33FF, 0xFFA966FF,
  ];
  // Weapon body uses Pineapple 32 (not recolored here)
  static const List<int> _weaponGlowKeys = [
    0xFF11BEA3, 0xFF1FD9BC, 0xFF33FFE2,
  ];
  static final Map<String, _ModifierMask> _maskCache = <String, _ModifierMask>{};

  // Build the asset path for a given class and gender (m/f)
  static String assetPathFor(String classKey, String gender) {
    final c = classKey.toLowerCase();
    final g = (gender.isNotEmpty ? gender[0] : 'm').toLowerCase();
    return 'assets/images/players/${c}_$g.png';
  }

  // Attempts to resolve a real asset path for class/gender, trying common
  // case variants and extensions.
  static Future<String?> resolveAssetPath(String classKey, String gender) async {
    final g = (gender.isNotEmpty ? gender[0] : 'm').toLowerCase();
    final bases = <String>[
      'assets/images/players/${classKey.toLowerCase()}_$g',
      'assets/images/players/${classKey}_$g',
    ];
    const exts = ['.png', '.webp'];
    for (final b in bases) {
      for (final ext in exts) {
        final p = '$b$ext';
        try {
          await rootBundle.load(p);
          return p;
        } catch (_) {}
      }
    }
    return null;
  }

  // Public: render current player from meta settings
  Future<ui.Image?> renderCurrentPlayer({String? overrideWeaponElement}) async {
    try {
      final meta = playerMetaBox();
      final classKey = (profileBox().values.isNotEmpty)
          ? profileBox().values.first.classKey
          : (meta.get('class')?.toString() ?? 'Sage');
      final gender = (meta.get('gender')?.toString() ?? 'm');
      final hairBase = (meta.get('hairBase')?.toString() ?? '#6B3F2A');
      final skinBase = (meta.get('skinBase')?.toString() ?? '#E0B6A1');
      // weapon element from equipment unless overridden
      String? weaponElement = overrideWeaponElement;
      if (weaponElement == null) {
        try {
          final eq = equipmentBox().get('slots') as Map?;
          final w = (eq?['weapon'] as Map?)?.map((k, v) => MapEntry(k.toString(), v));
          weaponElement = w?['element']?.toString();
        } catch (_) {}
      }
      final asset = await resolveAssetPath(classKey, gender) ?? assetPathFor(classKey, gender);
      final hairRamp = PlayerImageService.makeRamp3(hairBase);
      final skinRamp = PlayerImageService.makeRamp3(skinBase);
      final glowRamp3 = _elementRamp3(weaponElement) ?? PlayerImageService.defaultWeaponGlowRamp3(); // default to brown tones
      return recolorAsset(
        assetPath: asset,
        hairRamp6: hairRamp,
        skinRamp6: skinRamp,
        weaponGlowRamp3: glowRamp3,
      );
    } catch (_) {
      return null;
    }
  }

  // Core: load asset and recolor according to ramps
  Future<ui.Image?> recolorAsset({
    required String assetPath,
    required List<int> hairRamp6,
    required List<int> skinRamp6,
    List<int>? weaponGlowRamp3, // if null, keep authoring glow
  }) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null) return img;
      final src = bd.buffer.asUint8List();
      final w = img.width;
      final h = img.height;
      final mask = _maskCache.putIfAbsent(
        assetPath,
        () => _buildModifierMask(src, w, h),
      );
      final replacementCache = <int, int>{};

      // Iterate pixels and replace colors (ignore alpha in match)
      for (int p = 0; p < src.length; p += 4) {
        final r = src[p];
        final g = src[p + 1];
        final b = src[p + 2];
        final a = src[p + 3];
        if (a == 0) continue;
        final zone = mask.zones[p ~/ 4];
        if (zone == _zoneNone) continue;
        final key = (r << 16) | (g << 8) | b;
        final cacheKey = (zone << 24) | key;
        int? rep = replacementCache[cacheKey];
        if (rep == null) {
          switch (zone) {
            case _zoneHair:
              rep = hairRamp6[_closestKeyIndex(key, _hairKeys)] & 0xFFFFFF;
              break;
            case _zoneSkin:
              rep = skinRamp6[_closestKeyIndex(key, _skinKeys)] & 0xFFFFFF;
              break;
            case _zoneWeapon:
              final glowRamp = weaponGlowRamp3 ?? _weaponGlowKeys;
              rep = glowRamp[_closestKeyIndex(key, _weaponGlowKeys)] & 0xFFFFFF;
              break;
            default:
              rep = key;
          }
          replacementCache[cacheKey] = rep;
        }
        src[p] = (rep >> 16) & 0xFF;
        src[p + 1] = (rep >> 8) & 0xFF;
        src[p + 2] = rep & 0xFF;
      }

      // Create a new image from modified pixel buffer
      final out = await _imageFromRgba(src, w, h);
      return out;
    } catch (_) {
      return null;
    }
  }

  static _ModifierMask _buildModifierMask(Uint8List rgba, int width, int height) {
    final hairCandidates = _emptyMask(width, height);
    final warmCandidates = _emptyMask(width, height);
    final exactSkinCandidates = _emptyMask(width, height);
    final weaponCandidates = _emptyMask(width, height);
    final saturation = List<List<double>>.generate(
      height,
      (_) => List<double>.filled(width, 0),
      growable: false,
    );

    for (int y = 0; y < height; y++) {
      final rowOffset = y * width * 4;
      for (int x = 0; x < width; x++) {
        final offset = rowOffset + (x * 4);
        final r = rgba[offset];
        final g = rgba[offset + 1];
        final b = rgba[offset + 2];
        final a = rgba[offset + 3];
        if (a == 0) continue;
        final rgb = (r << 16) | (g << 8) | b;
        final hsv = _rgbToHsv(rgb);
        saturation[y][x] = hsv.s;

        if (_isExactSkinKey(rgb)) {
          exactSkinCandidates[y][x] = true;
        }
        if (_isHairCandidate(rgb, hsv, y, height)) {
          hairCandidates[y][x] = true;
        }
        if (_isWeaponCandidate(rgb, hsv)) {
          weaponCandidates[y][x] = true;
        }
        if (_isWarmSkinCandidate(rgb, hsv)) {
          warmCandidates[y][x] = true;
        }
      }
    }

    final hairMask = _refineHairMask(hairCandidates);
    final skinMask = _buildSkinMask(
      warmCandidates,
      exactSkinCandidates,
      saturation,
    );

    final zones = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        if (weaponCandidates[y][x]) {
          zones[index] = _zoneWeapon;
        } else if (hairMask[y][x]) {
          zones[index] = _zoneHair;
        } else if (skinMask[y][x]) {
          zones[index] = _zoneSkin;
        }
      }
    }
    return _ModifierMask(width: width, height: height, zones: zones);
  }

  static List<List<bool>> _emptyMask(int width, int height) {
    return List<List<bool>>.generate(
      height,
      (_) => List<bool>.filled(width, false),
      growable: false,
    );
  }

  static bool _isHairCandidate(int rgb, _HSV hsv, int y, int height) {
    if (_hairKeys.any((k) => (k & 0xFFFFFF) == rgb)) return true;
    final inKeyRange = _closestKeyDistanceSq(rgb, _hairKeys) <= 3600;
    final hueBand = (hsv.h >= 0.84 || hsv.h <= 0.02) &&
        hsv.s >= 0.38 &&
        hsv.v >= 0.22 &&
        _maxRgb(rgb) >= 70 &&
        y < (height * 0.78);
    return inKeyRange || hueBand;
  }

  static bool _isWeaponCandidate(int rgb, _HSV hsv) {
    if (_weaponGlowKeys.any((k) => (k & 0xFFFFFF) == rgb)) return true;
    final inKeyRange = _closestKeyDistanceSq(rgb, _weaponGlowKeys) <= 5200;
    final hueBand = hsv.h >= 0.43 &&
        hsv.h <= 0.58 &&
        hsv.s >= 0.35 &&
        hsv.v >= 0.42 &&
        _maxRgb(rgb) >= 110;
    return inKeyRange || hueBand;
  }

  static bool _isWarmSkinCandidate(int rgb, _HSV hsv) {
    if (_isExactSkinKey(rgb)) return true;
    final r = (rgb >> 16) & 0xFF;
    final g = (rgb >> 8) & 0xFF;
    final b = rgb & 0xFF;
    return hsv.h >= 0.03 &&
        hsv.h <= 0.14 &&
        hsv.s >= 0.12 &&
        hsv.s <= 0.72 &&
        hsv.v >= 0.25 &&
        r >= 70 &&
        g >= 45 &&
        b >= 25 &&
        r >= g &&
        g >= b;
  }

  static bool _isExactSkinKey(int rgb) {
    return _skinKeys.any((k) => (k & 0xFFFFFF) == rgb);
  }

  static int _maxRgb(int rgb) {
    final r = (rgb >> 16) & 0xFF;
    final g = (rgb >> 8) & 0xFF;
    final b = rgb & 0xFF;
    var max = r;
    if (g > max) max = g;
    if (b > max) max = b;
    return max;
  }

  static List<List<bool>> _refineHairMask(List<List<bool>> mask) {
    final height = mask.length;
    final width = mask.first.length;
    final comps = _components(mask);
    if (comps.isEmpty) return mask;

    final keep = Set<({int x, int y})>.from(comps.first.points);
    var frontier = _dilatePoints(keep, width, height, radius: 4);
    var changed = true;
    while (changed) {
      changed = false;
      for (final comp in comps.skip(1)) {
        if (comp.minY > height * 0.72) continue;
        if (comp.points.every((p) => keep.contains(p))) continue;
        if (comp.points.any(frontier.contains)) {
          keep.addAll(comp.points);
          frontier = _dilatePoints(keep, width, height, radius: 4);
          changed = true;
        }
      }
    }

    final refined = _emptyMask(width, height);
    for (final p in keep) {
      refined[p.y][p.x] = true;
    }
    return refined;
  }

  static List<List<bool>> _buildSkinMask(
    List<List<bool>> warmMask,
    List<List<bool>> exactSkinMask,
    List<List<double>> saturation,
  ) {
    final height = warmMask.length;
    final width = warmMask.first.length;
    final skinMask = _emptyMask(width, height);
    final comps = _components(warmMask);
    for (final comp in comps) {
      final meanSat = comp.points
              .map((p) => saturation[p.y][p.x])
              .fold<double>(0, (sum, v) => sum + v) /
          comp.points.length;
      final exactCount = comp.points
          .where((p) => exactSkinMask[p.y][p.x])
          .length;
      final hasExactKeys = exactCount > 0;
      final handMaxArea = hasExactKeys ? 32 : 20;
      final handLeftBoundary = width * (hasExactKeys ? 0.40 : 0.35);
      final handRightBoundary = width * (hasExactKeys ? 0.60 : 0.65);
      final handMaxWidth = hasExactKeys ? 8 : 6;
      final handMaxHeight = hasExactKeys ? 8 : 6;
      final isFace = comp.area <= 120 &&
          comp.centroidY <= height * 0.45 &&
          meanSat >= 0.22;
      final isHand = comp.area <= handMaxArea &&
          comp.centroidY >= height * 0.35 &&
          comp.centroidY <= height * 0.82 &&
          meanSat >= 0.22 &&
          (comp.centroidX <= handLeftBoundary ||
              comp.centroidX >= handRightBoundary) &&
          (comp.maxX - comp.minX) <= handMaxWidth &&
          (comp.maxY - comp.minY) <= handMaxHeight;
      if (!isFace && !isHand) continue;
      for (final p in comp.points) {
        skinMask[p.y][p.x] = true;
      }
    }
    return skinMask;
  }

  static List<_MaskComponent> _components(List<List<bool>> mask) {
    final height = mask.length;
    final width = mask.first.length;
    final seen = _emptyMask(width, height);
    final comps = <_MaskComponent>[];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!mask[y][x] || seen[y][x]) continue;
        final queue = Queue<({int x, int y})>();
        final points = <({int x, int y})>[];
        queue.add((x: x, y: y));
        seen[y][x] = true;
        var minX = x;
        var minY = y;
        var maxX = x;
        var maxY = y;
        var sumX = 0;
        var sumY = 0;

        while (queue.isNotEmpty) {
          final point = queue.removeFirst();
          points.add(point);
          sumX += point.x;
          sumY += point.y;
          if (point.x < minX) minX = point.x;
          if (point.y < minY) minY = point.y;
          if (point.x > maxX) maxX = point.x;
          if (point.y > maxY) maxY = point.y;

          for (final next in [
            (x: point.x + 1, y: point.y),
            (x: point.x - 1, y: point.y),
            (x: point.x, y: point.y + 1),
            (x: point.x, y: point.y - 1),
          ]) {
            if (next.x < 0 ||
                next.y < 0 ||
                next.x >= width ||
                next.y >= height ||
                !mask[next.y][next.x] ||
                seen[next.y][next.x]) {
              continue;
            }
            seen[next.y][next.x] = true;
            queue.add(next);
          }
        }

        comps.add(
          _MaskComponent(
            points: points,
            area: points.length,
            minX: minX,
            minY: minY,
            maxX: maxX,
            maxY: maxY,
            centroidX: sumX / points.length,
            centroidY: sumY / points.length,
          ),
        );
      }
    }

    comps.sort((a, b) => b.area.compareTo(a.area));
    return comps;
  }

  static Set<({int x, int y})> _dilatePoints(
    Set<({int x, int y})> points,
    int width,
    int height, {
    int radius = 4,
  }) {
    final out = <({int x, int y})>{};
    for (final point in points) {
      for (int y = point.y - radius; y <= point.y + radius; y++) {
        if (y < 0 || y >= height) continue;
        for (int x = point.x - radius; x <= point.x + radius; x++) {
          if (x < 0 || x >= width) continue;
          out.add((x: x, y: y));
        }
      }
    }
    return out;
  }

  static int _closestKeyIndex(int rgb, List<int> keys) {
    var bestIndex = 0;
    var bestScore = 1 << 62;
    for (int i = 0; i < keys.length; i++) {
      final score = _rgbDistanceSq(rgb, keys[i] & 0xFFFFFF);
      if (score < bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  static int _closestKeyDistanceSq(int rgb, List<int> keys) {
    var bestScore = 1 << 62;
    for (final key in keys) {
      final score = _rgbDistanceSq(rgb, key & 0xFFFFFF);
      if (score < bestScore) {
        bestScore = score;
      }
    }
    return bestScore;
  }

  static int _rgbDistanceSq(int a, int b) {
    final ar = (a >> 16) & 0xFF;
    final ag = (a >> 8) & 0xFF;
    final ab = a & 0xFF;
    final br = (b >> 16) & 0xFF;
    final bg = (b >> 8) & 0xFF;
    final bb = b & 0xFF;
    final dr = ar - br;
    final dg = ag - bg;
    final db = ab - bb;
    return (dr * dr) + (dg * dg) + (db * db);
  }

  Future<ui.Image> _imageFromRgba(Uint8List rgba, int width, int height) async {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (img) => c.complete(img),
    );
    return c.future;
  }

  // Generate a 3-step ramp around a base hex (dark → mid → light)
  static List<int> makeRamp3(String baseHex) {
    final base = _parseHex(baseHex);
    final hsl = _rgbToHsl(base);
    final steps = [-0.16, 0.0, 0.20];
    final out = <int>[];
    for (final d in steps) {
      final ll = (hsl.l + d).clamp(0.0, 1.0);
      out.add(_hslToRgb(hsl.h, hsl.s, ll));
    }
    return out.map((rgb) => 0xFF000000 | rgb).toList();
  }

  // 3-tone element ramp for weapon glow (dark, mid, light)
  List<int>? _elementRamp3(String? element) {
    if (element == null || element.isEmpty) return null;
    final e = element.toLowerCase();
    List<String>? hex;
    switch (e) {
      case 'fire':
        hex = ['#F25565', '#F27961', '#F09C60'];
        break;
      case 'water':
        hex = ['#2469B3', '#0B8BE6', '#0BAFE6'];
        break;
      case 'air':
        hex = ['#4D7A99', '#A3CCD9', '#96E3C9'];
        break;
      case 'nature':
        hex = ['#17735F', '#119955', '#1BA683'];
        break;
      case 'metal':
        hex = ['#1C284D', '#4D7A99', '#A3CCD9'];
        break;
      case 'light':
        hex = ['#A3CCD9', '#F0EDD8', '#F7C93E'];
        break;
      case 'shadow':
        hex = ['#1C284D', '#343473', '#4D7A99'];
        break;
      default:
        return null;
    }
    return hex.map((h) => 0xFF000000 | _parseHex(h)).toList();
  }

  // Default weapon glow ramp (brown tones: dark → mid → light)
  static List<int> defaultWeaponGlowRamp3() {
    const hex = ['#5A3A1F', '#8C5E34', '#D0A56B'];
    return hex.map((h) => 0xFF000000 | _parseHex(h)).toList();
  }

  static int _parseHex(String hex) {
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 3) {
      s = s.split('').map((c) => '$c$c').join();
    }
    return int.parse(s, radix: 16) & 0xFFFFFF;
  }

  static _HSL _rgbToHsl(int rgb) {
    final r = ((rgb >> 16) & 0xFF) / 255.0;
    final g = ((rgb >> 8) & 0xFF) / 255.0;
    final b = (rgb & 0xFF) / 255.0;
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    double h = 0, s = 0;
    final l = (max + min) / 2.0;
    if (max != min) {
      final d = max - min;
      s = l > 0.5 ? d / (2.0 - max - min) : d / (max + min);
      if (max == r) {
        h = (g - b) / d + (g < b ? 6 : 0);
      } else if (max == g) {
        h = (b - r) / d + 2;
      } else {
        h = (r - g) / d + 4;
      }
      h /= 6.0;
    }
    return _HSL(h, s, l);
  }

  static int _hslToRgb(double h, double s, double l) {
    double hue2rgb(double p, double q, double t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    double r, g, b;
    if (s == 0) {
      r = g = b = l; // achromatic
    } else {
      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }
    final ri = (r * 255).round().clamp(0, 255);
    final gi = (g * 255).round().clamp(0, 255);
    final bi = (b * 255).round().clamp(0, 255);
    return (ri << 16) | (gi << 8) | bi;
  }

  static _HSV _rgbToHsv(int rgb) {
    final r = ((rgb >> 16) & 0xFF) / 255.0;
    final g = ((rgb >> 8) & 0xFF) / 255.0;
    final b = (rgb & 0xFF) / 255.0;
    final max = [r, g, b].reduce((a, c) => a > c ? a : c);
    final min = [r, g, b].reduce((a, c) => a < c ? a : c);
    final delta = max - min;
    var h = 0.0;
    final s = max == 0 ? 0.0 : delta / max;
    final v = max;
    if (delta != 0) {
      if (max == r) {
        h = ((g - b) / delta) % 6;
      } else if (max == g) {
        h = ((b - r) / delta) + 2;
      } else {
        h = ((r - g) / delta) + 4;
      }
      h /= 6.0;
      if (h < 0) h += 1.0;
    }
    return _HSV(h, s, v);
  }
}

class _HSL {
  final double h, s, l;
  _HSL(this.h, this.s, this.l);
}

class _HSV {
  final double h;
  final double s;
  final double v;
  _HSV(this.h, this.s, this.v);
}

class _ModifierMask {
  final int width;
  final int height;
  final Uint8List zones;
  _ModifierMask({
    required this.width,
    required this.height,
    required this.zones,
  });
}

class _MaskComponent {
  final List<({int x, int y})> points;
  final int area;
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;
  final double centroidX;
  final double centroidY;

  _MaskComponent({
    required this.points,
    required this.area,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.centroidX,
    required this.centroidY,
  });
}
