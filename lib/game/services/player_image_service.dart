import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import '../../data/hive/boxes.dart';

class PlayerImageService {
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

      // Build mapping table from source→target colors
      final map = <int, int>{};
      for (int i = 0; i < _hairKeys.length && i < hairRamp6.length; i++) {
        map[_hairKeys[i] & 0xFFFFFF] = hairRamp6[i] & 0xFFFFFF;
      }
      for (int i = 0; i < _skinKeys.length && i < skinRamp6.length; i++) {
        map[_skinKeys[i] & 0xFFFFFF] = skinRamp6[i] & 0xFFFFFF;
      }
      if (weaponGlowRamp3 != null && weaponGlowRamp3.length >= 3) {
        for (int i = 0; i < _weaponGlowKeys.length && i < 3; i++) {
          map[_weaponGlowKeys[i] & 0xFFFFFF] = weaponGlowRamp3[i] & 0xFFFFFF;
        }
      }

      // Iterate pixels and replace colors (ignore alpha in match)
      for (int p = 0; p < src.length; p += 4) {
        final r = src[p];
        final g = src[p + 1];
        final b = src[p + 2];
        final a = src[p + 3];
        if (a == 0) continue;
        final key = (r << 16) | (g << 8) | b;
        final rep = map[key];
        if (rep != null) {
          src[p] = (rep >> 16) & 0xFF;
          src[p + 1] = (rep >> 8) & 0xFF;
          src[p + 2] = rep & 0xFF;
        }
      }

      // Create a new image from modified pixel buffer
      final out = await _imageFromRgba(src, w, h);
      return out;
    } catch (_) {
      return null;
    }
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
}

class _HSL {
  final double h, s, l;
  _HSL(this.h, this.s, this.l);
}
