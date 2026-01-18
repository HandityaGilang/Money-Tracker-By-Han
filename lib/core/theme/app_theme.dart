import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { white, black, navy }

class AppTheme {
  static const Color _yellowPrimary = Color(0xFFFFC857);
  static const Color _navyBackground = Color(0xFF060F1F);
  static const Color _navySurface = Color(0xFF111827);
  static const Color _darkBackground = Color(0xFF050509);
  static const Color _darkSurface = Color(0xFF181820);

  static TextTheme _textTheme(Color primaryTextColor) {
    return GoogleFonts.poppinsTextTheme().apply(
      bodyColor: primaryTextColor,
      displayColor: primaryTextColor,
    );
  }

  static ThemeData white() {
    const background = Color(0xFFF5F5F7);
    const primary = Color(0xFF2563EB);
    const secondary = Color(0xFF10B981);
    const textPrimary = Color(0xFF111827);

    final base = ThemeData.light();

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      textTheme: _textTheme(textPrimary),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData black() {
    const textPrimary = Colors.white;
    final base = ThemeData.dark();

    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: _yellowPrimary,
        secondary: Colors.blueAccent,
        surface: _darkSurface,
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: _textTheme(textPrimary),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _darkBackground,
        foregroundColor: textPrimary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _yellowPrimary,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _yellowPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _yellowPrimary,
      ),
    );
  }

  static ThemeData navy() {
    const textPrimary = Colors.white;
    final base = ThemeData.dark();

    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: _yellowPrimary,
        secondary: Colors.cyanAccent,
        surface: _navySurface,
      ),
      scaffoldBackgroundColor: _navyBackground,
      textTheme: _textTheme(textPrimary),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _navyBackground,
        foregroundColor: textPrimary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _yellowPrimary,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _navySurface,
        selectedItemColor: _yellowPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _yellowPrimary,
      ),
    );
  }
}
