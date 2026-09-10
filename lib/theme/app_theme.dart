import 'package:flutter/material.dart';

/// Tema visual centralizado do Plotter, reaproveitado por todas as telas.
class AppTheme {
  AppTheme._();

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color earthBrown = Color(0xFF8D6E63);
  static const Color background = Color(0xFFF4F6F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color pendingOrange = Color(0xFFEF6C00);
  static const Color doneGreen = Color(0xFF2E7D32);
  static const Color scheduledBlue = Color(0xFF1565C0);

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: lightGreen,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3DA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3DA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: lightGreen.withValues(alpha: 0.25),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Breakpoints usados para adaptar o layout a diferentes tamanhos de tela.
class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 700;
  static const double desktop = 1100;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  static bool isExtraWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}
