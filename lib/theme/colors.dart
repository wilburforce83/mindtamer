// lib/theme/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Brand neutrals
  static const midnight = Color(0xFF00021C);
  static const ivory    = Color(0xFFF0EDD8);

  // Brand roles
  static const primary        = Color(0xFF1BA683); // teal
  static const onPrimary      = ivory;
  static const secondary      = Color(0xFFA6216E); // magenta
  static const onSecondary    = ivory;
  static const tertiary       = Color(0xFF2469B3); // blue
  static const onTertiary     = ivory;
  static const accentWarm     = Color(0xFFF7C93E); // sunshine
  static const onAccentWarm   = midnight;

  static const background     = Color(0xFF00021C); // midnight
  static const onBackground   = ivory;
  static const surface        = Color(0xFF1C284D);
  static const onSurface      = ivory;
  static const surfaceVariant = Color(0xFF2D5280);
  static const outline        = Color(0xFF4D7A99);
  static const muted          = Color(0xFF7497A6);
  static const mutedAlt       = Color(0xFFA3CCD9);

  // Status
  static const success        = Color(0xFF67B31B);
  static const warning        = Color(0xFFF7C93E);
  static const error          = Color(0xFFF25565);
  static const info           = Color(0xFF0B8BE6);
}
