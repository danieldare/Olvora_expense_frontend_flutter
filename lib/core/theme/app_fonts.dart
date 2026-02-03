import 'package:flutter/material.dart';

/// Optimized font configuration for Olvora.
///
/// Font: Manrope - Modern, clean, versatile sans-serif
/// Semi-rounded letterforms with excellent legibility
/// Perfect balance of professionalism and friendliness for fintech
///
/// Font Loading Strategy:
/// - Fonts are bundled with the app (no network download)
/// - Instant display with no FOUT (Flash of Unstyled Text)
/// - Smaller app size than full Google Fonts package
class AppFonts {
  AppFonts._();

  static const String _fontFamily = 'Manrope';

  /// Pre-warm the font cache on app start.
  /// With bundled fonts, this is essentially a no-op but kept for API compatibility.
  static Future<void> preloadFonts() async {
    // Bundled fonts are already available - no preloading needed
  }

  /// Creates a TextStyle with Manrope font.
  static TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    double? decorationThickness,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
    );
  }

  /// Returns the text theme using Manrope font.
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily),
    displayMedium: TextStyle(fontFamily: _fontFamily),
    displaySmall: TextStyle(fontFamily: _fontFamily),
    headlineLarge: TextStyle(fontFamily: _fontFamily),
    headlineMedium: TextStyle(fontFamily: _fontFamily),
    headlineSmall: TextStyle(fontFamily: _fontFamily),
    titleLarge: TextStyle(fontFamily: _fontFamily),
    titleMedium: TextStyle(fontFamily: _fontFamily),
    titleSmall: TextStyle(fontFamily: _fontFamily),
    bodyLarge: TextStyle(fontFamily: _fontFamily),
    bodyMedium: TextStyle(fontFamily: _fontFamily),
    bodySmall: TextStyle(fontFamily: _fontFamily),
    labelLarge: TextStyle(fontFamily: _fontFamily),
    labelMedium: TextStyle(fontFamily: _fontFamily),
    labelSmall: TextStyle(fontFamily: _fontFamily),
  );

  /// Convenience alias for textStyle.
  static TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    double? decorationThickness,
  }) {
    return textStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
    );
  }
}
