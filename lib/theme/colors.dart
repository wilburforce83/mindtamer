// lib/theme/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Brand neutrals
  static const midnight = Color(0xFF100E18);
  static const deepNight = Color(0xFF171421);
  static const ivory = Color(0xFFF2EAD8);
  static const parchment = Color(0xFFD9C8A8);

  // Brand roles
  static const primary = Color(0xFF6F9C84); // moss jade
  static const onPrimary = ivory;
  static const secondary = Color(0xFF8E687D); // dusty plum
  static const onSecondary = ivory;
  static const tertiary = Color(0xFF738EAB); // rain blue
  static const onTertiary = ivory;
  static const accentWarm = Color(0xFFD7B26B); // candle gold
  static const onAccentWarm = midnight;

  static const background = Color(0xFF12111B);
  static const onBackground = ivory;
  static const surface = Color(0xFF202331);
  static const surfaceRaised = Color(0xFF2B3040);
  static const panel = Color(0xFF181B28);
  static const panelSoft = Color(0xFF262C3A);
  static const nav = Color(0xFF1D2230);
  static const navActive = Color(0xFF303748);
  static const onSurface = ivory;
  static const surfaceVariant = Color(0xFF3A4658);
  static const outline = Color(0xFF6A6B74);
  static const outlineSoft = Color(0xFF444853);
  static const outlineBright = Color(0xFFDCCFB1);
  static const muted = Color(0xFF948F88);
  static const mutedAlt = Color(0xFFB8B09F);
  static const glowTeal = Color(0xFF8CB8A8);
  static const ember = Color(0xFFC8885B);
  static const overlayShadow = Color(0x88000000);

  // Status
  static const success = Color(0xFF83A66F);
  static const warning = Color(0xFFD4AC64);
  static const error = Color(0xFFC26C74);
  static const info = Color(0xFF7A99B8);

  static const elementFire = Color(0xFFC87D57);
  static const elementWater = Color(0xFF7A9FBC);
  static const elementAir = Color(0xFF9EBFC7);
  static const elementNature = Color(0xFF7E9F6D);
  static const elementMetal = Color(0xFF8B8C93);
  static const elementLight = Color(0xFFD8BE82);
  static const elementShadow = Color(0xFF8F7995);

  static Color rarityColorByName(String? rarity) {
    switch ((rarity ?? '').toLowerCase()) {
      case 'uncommon':
        return tertiary;
      case 'rare':
        return elementShadow;
      case 'epic':
        return ember;
      case 'legendary':
        return glowTeal;
      case 'common':
      default:
        return muted;
    }
  }

  static Color elementColorByName(String? element) {
    switch ((element ?? '').toLowerCase()) {
      case 'fire':
        return elementFire;
      case 'water':
        return elementWater;
      case 'air':
        return elementAir;
      case 'nature':
        return elementNature;
      case 'metal':
        return elementMetal;
      case 'light':
        return elementLight;
      case 'shadow':
        return elementShadow;
      default:
        return muted;
    }
  }

  static Color achievementCategoryColor(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'journal':
        return accentWarm;
      case 'mood':
        return tertiary;
      case 'medication':
        return primary;
      case 'combat':
        return error;
      case 'crafting':
        return ember;
      case 'items':
        return glowTeal;
      case 'echoes':
        return elementShadow;
      case 'sprites':
        return info;
      case 'equipment':
        return elementWater;
      case 'progress':
        return parchment;
      default:
        return mutedAlt;
    }
  }

  static Color battleEffectColor(String? effect) {
    switch ((effect ?? '').toLowerCase()) {
      case 'atk+':
        return ember;
      case 'def+':
        return tertiary;
      case 'def-':
        return error;
      case 'regen':
        return success;
      case 'guard':
        return info;
      case 'focus':
        return secondary;
      case 'spirit+':
        return accentWarm;
      case 'atk-':
        return error;
      case 'poison':
        return elementNature;
      default:
        return mutedAlt;
    }
  }
}
