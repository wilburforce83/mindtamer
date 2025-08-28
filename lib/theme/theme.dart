// lib/theme/theme.dart
import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData mindTamerTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      error: AppColors.error,
      onError: AppColors.midnight,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.ivory,
      outline: AppColors.outline,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: AppColors.ivory,
      onInverseSurface: AppColors.midnight,
      inversePrimary: AppColors.accentWarm,
    ),
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.outline.withOpacity(0.4),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accentWarm,
      selectionColor: Color(0x44F7C93E),
      selectionHandleColor: AppColors.accentWarm,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: TextStyle(color: AppColors.onSurface),
      actionTextColor: AppColors.accentWarm,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2D5280),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.outline),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.outline),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accentWarm, width: 2),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      hintStyle: TextStyle(color: AppColors.muted),
      labelStyle: TextStyle(color: AppColors.mutedAlt),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onBackground,
      elevation: 0,
      centerTitle: false,
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.primary,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outline),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textTheme: base.textTheme.apply(
      fontFamily: "PixelifySans", // or any pixel font you add
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
    ),
    cardTheme: const CardTheme(
      color: AppColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18))),
      margin: EdgeInsets.all(8),
    ),
  );
}
