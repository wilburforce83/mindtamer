import 'package:flutter/material.dart';

class PixelTheme {
  static const _bg = Color(0xFF0D0F12); // very dark grey
  static const _surface = Color(0xFF151920);
  static const _primary = Color(0xFF7ED957); // soft green
  static const _accent = Color(0xFF58C4DD); // cyan
  static const _error = Color(0xFFE57373);

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: _bg,
      colorScheme: base.colorScheme.copyWith(
        primary: _primary,
        secondary: _accent,
        surface: _surface,
        error: _error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        margin: const EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'PixelFont',
            letterSpacing: 1.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'PixelFont',
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
