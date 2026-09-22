import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const brand = Color(0xFF4F46E5);
  static const brand2 = Color(0xFF6366F1);
  static const background = Color(0xFFF7F8FC);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF7B8497);
  static const line = Color(0xFFE5E8F0);
  static const soft = Color(0xFFEEF2FF);
  static const danger = Color(0xFFDC5A63);
  static const success = Color(0xFF16836B);

  static ThemeData get lightTheme => _theme(Brightness.light);
  static ThemeData get darkTheme => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF11131A) : background,
      colorScheme: scheme.copyWith(
        primary: brand,
        secondary: brand2,
        surface: isDark ? const Color(0xFF1A1D26) : Colors.white,
        error: danger,
      ),
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? const Color(0xFF11131A) : background,
        foregroundColor: isDark ? Colors.white : ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1A1D26) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? const Color(0xFF2A2E39) : line,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1D26) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brand, width: 1.4),
        ),
      ),
    );
  }
}
