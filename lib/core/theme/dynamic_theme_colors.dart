import 'package:flutter/material.dart';
import '../models/color_theme.dart';

/// Dynamic theme colors that automatically update based on selected ColorTheme
/// This provides a bridge between the old static AppTheme colors and the new dynamic system
class DynamicThemeColors {
  static ColorTheme _currentTheme = ColorTheme.defaultTheme;

  /// Update the current theme (called when theme changes)
  static void updateTheme(ColorTheme theme) {
    _currentTheme = theme;
  }

  /// Primary color - main brand color
  static Color get primaryColor => _currentTheme.primaryColor;

  /// Secondary color - accent color
  static Color get secondaryColor => _currentTheme.secondaryColor;

  /// Tertiary/accent color
  static Color get accentColor => _currentTheme.accentColor;

  /// Error color
  static Color get errorColor => _currentTheme.errorColor;

  /// Success color
  static Color get successColor => _currentTheme.successColor;

  /// Warning color
  static Color get warningColor => _currentTheme.warningColor;

  /// Background color
  static Color get backgroundColor => _currentTheme.backgroundColor;

  /// Surface/Card color
  static Color get surfaceColor => _currentTheme.surfaceColor;

  /// Primary text color
  static Color get textPrimary => _currentTheme.textPrimary;

  /// Secondary text color
  static Color get textSecondary => _currentTheme.textSecondary;

  /// Border color
  static Color get borderColor => _currentTheme.borderColor;

  /// Complementary color for highlights
  static Color get complementaryColor => _currentTheme.complementaryColor;

  /// Card background color
  static Color get cardBackground => _currentTheme.cardBackground;

  /// Dark mode card background (for compatibility)
  static Color get darkCardBackground => _currentTheme.isDark
      ? _currentTheme.cardBackground
      : const Color(0xFF1E293B);

  /// Wallet gradient colors
  static List<Color> get walletGradient => _currentTheme.walletGradient;

  /// Navigation active color - color for active bottom navigation items
  static Color get navigationActiveColor => _currentTheme.navigationActiveColor;

  /// Navigation bar background (e.g. bottom nav bar)
  static Color get navigationBarBackground =>
      _currentTheme.navigationBarBackground;

  /// Modal/sheet background (e.g. bottom sheet modals)
  static Color get modalBackground => _currentTheme.modalBackground;

  /// Check if current theme is dark
  static bool get isDark => _currentTheme.isDark;

  /// Get current theme
  static ColorTheme get currentTheme => _currentTheme;
}
