// lib/theme/theme.dart
import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData mindTamerTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'PressStart2P',
  );
  const scheme = ColorScheme(
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
    shadow: Color(0xFF000000),
    scrim: Color(0x99000000),
    inverseSurface: AppColors.ivory,
    onInverseSurface: AppColors.midnight,
    inversePrimary: AppColors.accentWarm,
  );

  final baseTextTheme = base.textTheme.apply(
    bodyColor: AppColors.onSurface,
    displayColor: AppColors.onSurface,
  );

  TextStyle? scale(TextStyle? s) =>
      (s == null || s.fontSize == null) ? s : s.copyWith(fontSize: s.fontSize! * 0.9);

  final textTheme = baseTextTheme.copyWith(
    displayLarge: scale(baseTextTheme.displayLarge),
    displayMedium: scale(baseTextTheme.displayMedium),
    displaySmall: scale(baseTextTheme.displaySmall),
    headlineLarge: scale(baseTextTheme.headlineLarge),
    headlineMedium: scale(baseTextTheme.headlineMedium),
    headlineSmall: scale(baseTextTheme.headlineSmall),
    titleLarge: scale(baseTextTheme.titleLarge),
    titleMedium: scale(baseTextTheme.titleMedium),
    titleSmall: scale(baseTextTheme.titleSmall),
    bodyLarge: scale(baseTextTheme.bodyLarge),
    bodyMedium: scale(baseTextTheme.bodyMedium),
    bodySmall: scale(baseTextTheme.bodySmall),
    labelLarge: scale(baseTextTheme.labelLarge),
    labelMedium: scale(baseTextTheme.labelMedium),
    labelSmall: scale(baseTextTheme.labelSmall),
  );

  return base.copyWith(
    colorScheme: scheme,
    // Remove circular ink splashes globally; we'll paint square overlays in widgets.
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.outline.withValues(alpha: 0.4),
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
        borderSide: BorderSide(color: AppColors.outline, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.outline, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accentWarm, width: 2),
        borderRadius: BorderRadius.zero,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outline),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    textTheme: textTheme,
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.outline, width: 1),
      ),
      margin: EdgeInsets.all(8),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(8),
      radius: const Radius.circular(0),
      thumbColor: WidgetStatePropertyAll(AppColors.secondary.withValues(alpha: 0.8)),
      trackColor: const WidgetStatePropertyAll(AppColors.surface),
      crossAxisMargin: 2,
      mainAxisMargin: 2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accentWarm,
      unselectedItemColor: AppColors.muted,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedIconTheme: IconThemeData(size: 22),
      unselectedIconTheme: IconThemeData(size: 20),
      selectedLabelStyle: TextStyle(fontSize: 10),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
  );
}
