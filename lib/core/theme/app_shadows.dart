import 'package:flutter/material.dart';

/// Centralized shadow constants for card-style widgets in light and dark mode.
///
/// Change these values in one place to adjust shadow depth across the app.
/// Use [card] to build a consistent List<BoxShadow>, or reference the
/// constants when you need to scale (e.g. blurRadius.scaled(context)).
class AppShadows {
  AppShadows._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD SHADOW (quick action cards, list cards, section cards, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Light mode: shadow color alpha (0 = transparent, 1 = opaque).
  static const double cardAlphaLight = 0.10;

  /// Dark mode: shadow color alpha.
  static const double cardAlphaDark = 0.15;

  /// Blur radius (logical pixels).
  static const double cardBlur = 14.0;

  /// Vertical offset (positive = shadow below).
  static const double cardOffsetY = 4.0;

  /// Spread radius (negative = tighter shadow).
  /// Use spread: 0 for Settings-style blocks and transaction/recent-expense cards.
  static const double cardSpread = -2.0;

  /// Stronger variant for feature cards (e.g. More screen large cards).
  static const double cardAlphaLightStrong = 0.14;
  static const double cardAlphaDarkStrong = 0.30;

  /// Elevated card (e.g. streak card) – larger blur and offset.
  static const double cardElevatedBlur = 22.0;
  static const double cardElevatedOffsetY = 8.0;

  /// Returns a single shadow for card-style containers.
  ///
  /// Use [color] for the shadow tint (default [Colors.black]).
  /// Override [alphaLight]/[alphaDark], [blur], [offsetY], [spread] when needed.
  static List<BoxShadow> card({
    required bool isDark,
    Color color = Colors.black,
    double? alphaLight,
    double? alphaDark,
    double? blur,
    double? offsetY,
    double? spread,
  }) {
    return [
      BoxShadow(
        color: color.withValues(
          alpha: isDark ? (alphaDark ?? cardAlphaDark) : (alphaLight ?? cardAlphaLight),
        ),
        blurRadius: blur ?? cardBlur,
        offset: Offset(0, offsetY ?? cardOffsetY),
        spreadRadius: spread ?? cardSpread,
      ),
    ];
  }

  /// Same as [card] but with stronger alpha (e.g. QuickActionFeatureCard, streak card).
  static List<BoxShadow> cardStrong({
    required bool isDark,
    Color color = Colors.black,
    double? blur,
    double? offsetY,
    double? spread,
  }) {
    return card(
      isDark: isDark,
      color: color,
      alphaLight: cardAlphaLightStrong,
      alphaDark: cardAlphaDarkStrong,
      blur: blur,
      offsetY: offsetY,
      spread: spread,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYERED CARD (e.g. streak card: primary + soft lift)
  // ═══════════════════════════════════════════════════════════════════════════

  static const double cardLiftAlphaLight = 0.06;
  static const double cardLiftBlur = 44.0;
  static const double cardLiftOffsetY = 12.0;
  static const double cardLiftSpread = -8.0;

  /// Soft secondary shadow for layered cards (used with [card] or [cardStrong]).
  static List<BoxShadow> cardLift({Color color = Colors.black}) => [
        BoxShadow(
          color: color.withValues(alpha: cardLiftAlphaLight),
          blurRadius: cardLiftBlur,
          offset: Offset(0, cardLiftOffsetY),
          spreadRadius: cardLiftSpread,
        ),
      ];
}
