import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme extracted from Stitch design screens.
///
/// Colors derived from the AIVIVU design system:
/// - Primary pink: #FF4D8D
/// - Secondary orange: #FF8C42
/// - Accent blue: #4FACEF
/// - Background dark: #050B15
class AppTheme {
  AppTheme._();

  // ── Brand Colors ──────────────────────────────────────────────────────
  static const Color primaryPink = Color(0xFFFF4D8D);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color accentBlue = Color(0xFF4FACEF);
  static const Color backgroundDark = Color(0xFF050B15);
  static const Color navyAccent = Color(0xFF0A0E1A);
  static const Color surfaceDark = Color(0xFF12182B);

  // ── Gradient ──────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryPink, secondaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashTextGradient = LinearGradient(
    colors: [
      Color(0xFFFF5E8E),
      Color(0xFFF59E0B),
      Color(0xFFA855F7),
      Color(0xFF3B82F6),
    ],
  );

  // ── Spacing ───────────────────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // ── Border Radius ─────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // ── CJK Font Fallbacks ──────────────────────────────────────────────
  // Font Inter (Google Fonts) does not include Korean/Japanese/Chinese
  // glyphs. Add system CJK fonts as fallbacks so those scripts render
  // correctly on every platform.
  static const List<String> _cjkFontFallbacks = [
    'Malgun Gothic', // Windows – Korean
    'Apple SD Gothic Neo', // macOS/iOS – Korean
    'Noto Sans CJK KR', // Linux – Korean
    'Yu Gothic UI', // Windows – Japanese
    'Hiragino Sans', // macOS/iOS – Japanese
    'Microsoft YaHei UI', // Windows – Chinese Simplified
    'PingFang SC', // macOS/iOS – Chinese Simplified
  ];

  /// Returns a copy of [textTheme] where every style has
  /// [fontFamilyFallback] merged with [_cjkFontFallbacks].
  static TextTheme _applyCjkFallbacks(TextTheme textTheme) {
    TextStyle _add(TextStyle? s) => (s ?? const TextStyle()).copyWith(
      fontFamilyFallback: _cjkFontFallbacks,
    );
    return textTheme.copyWith(
      displayLarge: _add(textTheme.displayLarge),
      displayMedium: _add(textTheme.displayMedium),
      displaySmall: _add(textTheme.displaySmall),
      headlineLarge: _add(textTheme.headlineLarge),
      headlineMedium: _add(textTheme.headlineMedium),
      headlineSmall: _add(textTheme.headlineSmall),
      titleLarge: _add(textTheme.titleLarge),
      titleMedium: _add(textTheme.titleMedium),
      titleSmall: _add(textTheme.titleSmall),
      bodyLarge: _add(textTheme.bodyLarge),
      bodyMedium: _add(textTheme.bodyMedium),
      bodySmall: _add(textTheme.bodySmall),
      labelLarge: _add(textTheme.labelLarge),
      labelMedium: _add(textTheme.labelMedium),
      labelSmall: _add(textTheme.labelSmall),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────
  static ThemeData darkTheme() {
    final textTheme = _applyCjkFallbacks(
      GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: primaryPink,
        secondary: secondaryOrange,
        tertiary: accentBlue,
        surface: surfaceDark,
        onSurface: Colors.white,
        error: Color(0xFFEF4444),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark.withValues(alpha: 0.8),
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundDark,
        selectedItemColor: primaryPink,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  // ── Light Theme (placeholder) ─────────────────────────────────────────
  static ThemeData lightTheme() {
    final textTheme = _applyCjkFallbacks(
      GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F8F8),
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: primaryPink,
        secondary: secondaryOrange,
        tertiary: accentBlue,
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
        error: Color(0xFFEF4444),
      ),
    );
  }
}
