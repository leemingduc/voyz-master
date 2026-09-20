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
  static const Color cyan = Color(0xFF00E5FF);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color magenta = Color(0xFFFF3366);
  static const Color backgroundDark = Color(0xFF06070B);
  static const Color navyAccent = Color(0xFF0B0E15);
  static const Color surfaceDark = Color(0xFF10131A);
  static const Color primaryPink = magenta;
  static const Color secondaryOrange = violet;
  static const Color accentBlue = cyan;
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Gradient ──────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [cyan, violet, magenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashTextGradient = LinearGradient(
    colors: [cyan, violet, magenta],
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

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return EdgeInsets.symmetric(horizontal: width >= 720 ? 24 : 16);
  }

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
      GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: magenta,
        tertiary: violet,
        surface: surfaceDark,
        onSurface: Colors.white,
        error: Color(0xFFEF4444),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark.withValues(alpha: 0.84),
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: cyan,
        unselectedItemColor: textMuted,
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
      GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
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
