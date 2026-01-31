import 'package:flutter/material.dart';

class AppColors {
  static bool _isDark = true;

  static void setDark(bool value) => _isDark = value;
  static bool get isDark => _isDark;

  // Theme-dependent colors
  static Color get background =>
      _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF2F2F7);
  static Color get card =>
      _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get cardSecondary =>
      _isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
  static Color get foreground =>
      _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  static Color get border =>
      _isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

  // Theme-independent colors
  static const primary = Color(0xFFFC3E4E);
  static const mutedForeground = Color(0xFF8E8E93);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: Color(0xFF1C1C1E),
        ),
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          surface: Color(0xFFFFFFFF),
        ),
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF000000),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
