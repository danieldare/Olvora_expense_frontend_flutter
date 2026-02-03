import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared chart color palette for consistent visualization across the app
///
/// This ensures all charts (pie charts, bar charts, etc.) use the same
/// color scheme for better visual consistency.
class ChartColors {
  ChartColors._();

  /// Primary chart color palette
  /// Used for category breakdowns, pie charts, and other categorical visualizations
  static List<Color> get categoryPalette => [
    AppTheme.primaryColor,
    AppTheme.accentColor,
    AppTheme.successColor,
    AppTheme.warningColor,
    AppTheme.errorColor,
    const Color(0xFFEC4899), // Pink
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFF59E0B), // Amber
  ];

  /// Get color for a category by index (with wrapping)
  static Color getCategoryColor(int index) {
    return categoryPalette[index % categoryPalette.length];
  }
}
