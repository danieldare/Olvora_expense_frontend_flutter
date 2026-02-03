import 'package:flutter/material.dart';

/// Extension to easily access theme colors from context
/// Use these instead of static AppTheme.primaryColor constants
extension ThemeColors on BuildContext {
  /// Get the current color scheme
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Primary color - main brand color
  Color get primaryColor => colors.primary;

  /// Secondary color - accent color
  Color get secondaryColor => colors.secondary;

  /// Tertiary/accent color
  Color get accentColor => colors.tertiary;

  /// Error color
  Color get errorColor => colors.error;

  /// Success color (use Colors.green or define custom)
  Color get successColor => const Color(0xFF10B981);

  /// Warning color (use Colors.orange or define custom)
  Color get warningColor => const Color(0xFFFFC000);

  /// Background color
  Color get backgroundColor => colors.surface;

  /// Surface/Card color
  Color get surfaceColor => colors.surface;

  /// Primary text color
  Color get textPrimary => colors.onSurface;

  /// Secondary text color
  Color get textSecondary => colors.onSurfaceVariant;

  /// Border color
  Color get borderColor => colors.outline;

  /// Card background color
  Color get cardColor => colors.surfaceContainerHighest;

  /// Check if dark mode is enabled
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
