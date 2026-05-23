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

  TextStyle? scale(TextStyle? s) => (s == null || s.fontSize == null)
      ? s
      : s.copyWith(fontSize: s.fontSize! * 0.9);

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
    dividerColor: AppColors.outlineSoft.withValues(alpha: 0.8),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accentWarm,
      selectionColor: Color(0x44D7B26B),
      selectionHandleColor: AppColors.accentWarm,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.panelSoft,
      contentTextStyle: TextStyle(color: AppColors.onSurface),
      actionTextColor: AppColors.accentWarm,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panelSoft,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.outlineSoft, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.outlineSoft, width: 2),
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
      backgroundColor: AppColors.deepNight,
      foregroundColor: AppColors.onBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 16,
        color: AppColors.onBackground,
        height: 1.1,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentWarm,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
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
        side: const BorderSide(color: AppColors.outlineBright, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        side: const BorderSide(color: AppColors.outlineBright, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outlineBright),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.panelSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.panelSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        border: Border.all(color: AppColors.outlineSoft),
      ),
      textStyle: const TextStyle(color: AppColors.ivory),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    textTheme: textTheme,
    cardTheme: const CardThemeData(
      color: AppColors.panelSoft,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.outlineSoft, width: 1.2),
      ),
      margin: EdgeInsets.all(8),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(8),
      radius: const Radius.circular(0),
      thumbColor:
          WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.72)),
      trackColor: const WidgetStatePropertyAll(AppColors.panelSoft),
      crossAxisMargin: 2,
      mainAxisMargin: 2,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceVariant,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.nav,
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
