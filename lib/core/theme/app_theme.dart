import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Palette
  static const _lightPrimary = Color(0xFF2563EB); // Vibrant Royal Blue
  static const _lightSecondary = Color(0xFF0284C7); // Sky Accent
  static const _lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const _lightSurface = Color(0xFFFFFFFF); // Pure White
  static const _lightSurfaceContainer = Color(0xFFF1F5F9); // Slate 100
  static const _lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const _lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const _lightTextSecondary = Color(0xFF64748B); // Slate 500

  // Dark Theme Palette
  static const _darkPrimary = Color(0xFF3B82F6); // Electric Blue
  static const _darkSecondary = Color(0xFF38BDF8); // Bright Sky
  static const _darkBackground = Color(0xFF0F172A); // Slate 900 / Obsidian
  static const _darkSurface = Color(0xFF1E293B); // Slate 800
  static const _darkSurfaceContainer = Color(0xFF334155); // Slate 700
  static const _darkBorder = Color(0xFF334155); // Slate 700
  static const _darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const _darkTextSecondary = Color(0xFF94A3B8); // Slate 400

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDBEAFE),
        onPrimaryContainer: Color(0xFF1E40AF),
        secondary: _lightSecondary,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE0F2FE),
        onSecondaryContainer: Color(0xFF0369A1),
        surface: _lightSurface,
        onSurface: _lightTextPrimary,
        surfaceContainerLow: Color(0xFFF8FAFC),
        surfaceContainer: _lightSurfaceContainer,
        surfaceContainerHigh: Color(0xFFE2E8F0),
        outline: _lightBorder,
        outlineVariant: Color(0xFFCBD5E1),
      ),
      scaffoldBackgroundColor: _lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightSurface,
        foregroundColor: _lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: _lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _lightSurface,
        elevation: 0,
        selectedIconTheme: const IconThemeData(color: _lightPrimary, size: 24),
        unselectedIconTheme: const IconThemeData(color: _lightTextSecondary, size: 22),
        selectedLabelTextStyle: const TextStyle(
          color: _lightPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: _lightTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        indicatorColor: const Color(0xFFDBEAFE),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: _lightTextSecondary, fontSize: 14),
        hintStyle: TextStyle(color: _lightTextSecondary.withOpacity(0.7), fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _lightBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _lightBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1E3A8A),
        onPrimaryContainer: Color(0xFF93C5FD),
        secondary: _darkSecondary,
        onSecondary: Color(0xFF0F172A),
        secondaryContainer: Color(0xFF0C4A6E),
        onSecondaryContainer: Color(0xFF7DD3FC),
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
        surfaceContainerLow: Color(0xFF0F172A),
        surfaceContainer: _darkSurfaceContainer,
        surfaceContainerHigh: Color(0xFF475569),
        outline: _darkBorder,
        outlineVariant: Color(0xFF475569),
      ),
      scaffoldBackgroundColor: _darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: _darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: _darkSurface,
        elevation: 0,
        selectedIconTheme: const IconThemeData(color: _darkPrimary, size: 24),
        unselectedIconTheme: const IconThemeData(color: _darkTextSecondary, size: 22),
        selectedLabelTextStyle: const TextStyle(
          color: _darkPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: _darkTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        indicatorColor: const Color(0xFF1E3A8A),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: _darkTextSecondary, fontSize: 14),
        hintStyle: TextStyle(color: _darkTextSecondary.withOpacity(0.7), fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _darkBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
