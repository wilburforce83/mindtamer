import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

/// Centralized asset availability + helpers.
class PixelAssets {
  static Set<String>? _assets;

  // Commonly referenced asset paths
  static const tabHome = 'assets/images/icons/tab_home_32.png';
  static const tabMood = 'assets/images/icons/tab_mood_32.png';
  static const tabJournal = 'assets/images/icons/tab_journal_32.png';
  static const tabMeds = 'assets/images/icons/tab_meds_32.png';
  static const tabSettings = 'assets/images/icons/tab_settings_32.png';
  static const backIcon24 = 'assets/images/icons/back_24.png';

  static const btnPrimary9Slice = 'assets/images/ui/btn_primary_9slice.png';
  static const sliderKnob16 = 'assets/images/ui/slider_knob_16.png';
  static const sliderTrackTile8 = 'assets/images/ui/slider_track_tile_8x8.png';
  static const pillCell32 = 'assets/images/ui/pill_cell_32.png';
  static const pillIconsDir = 'assets/images/icons/pills/';

  static Future<void> init() async {
    if (_assets != null) return;
    try {
      final json = await rootBundle.loadString('AssetManifest.json');
      final map = jsonDecode(json) as Map<String, dynamic>;
      _assets = map.keys.toSet();
    } catch (_) {
      _assets = <String>{};
    }
  }

  static bool has(String path) => _assets?.contains(path) ?? false;

  static List<String> listPillIcons() {
    final a = _assets ?? const <String>{};
    return a.where((k) => k.startsWith(pillIconsDir)).toList()..sort();
  }

  /// Returns an icon that uses an asset if present; otherwise falls back to a Material icon.
  static Widget iconOr(
    BuildContext context, {
    required String assetPath,
    required IconData fallback,
    double size = 24,
  }) {
    // Defer color/size resolution to where this widget is placed (e.g. BottomNavigationBar).
    return Builder(
      builder: (ctx) {
        final iconTheme = IconTheme.of(ctx);
        final resolvedSize = iconTheme.size ?? size;
        final resolvedColor = iconTheme.color;

        final img = Image.asset(
          assetPath,
          width: resolvedSize,
          height: resolvedSize,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => Icon(fallback, size: resolvedSize),
        );

        if (resolvedColor != null) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
            child: img,
          );
        }
        return img;
      },
    );
  }
}
