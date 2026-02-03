import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Configuration for navigation bar styling
class NavigationConfig {
  /// Background color for the navigation bar container
  final Color Function(bool isDark) backgroundColor;

  /// Active item background color
  final Color activeItemBackgroundColor;

  /// Active item text and icon color
  final Color activeItemColor;

  /// Inactive item text and icon color
  final Color inactiveItemColor;

  /// Border radius for the navigation bar container
  final double containerBorderRadius;

  /// Border radius for active item background
  final double activeItemBorderRadius;

  /// Horizontal margin for the navigation bar
  final EdgeInsets margin;

  /// Padding inside the navigation bar
  final EdgeInsets padding;

  /// Minimum height of the navigation bar
  final double minHeight;

  /// Icon size when selected
  final double selectedIconSize;

  /// Icon size when not selected
  final double unselectedIconSize;

  /// Font size for labels
  final double labelFontSize;

  /// Shadow configuration
  final List<BoxShadow>? boxShadow;

  /// Border configuration
  final Border? Function(bool isDark) border;

  NavigationConfig({
    this.backgroundColor = _defaultBackgroundColor,
    Color? activeItemBackgroundColor,
    Color? activeItemColor,
    this.inactiveItemColor = Colors.grey,
    this.containerBorderRadius = 30.0,
    this.activeItemBorderRadius = 12.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    this.minHeight = 56.0,
    this.selectedIconSize = 22.0,
    this.unselectedIconSize = 20.0,
    this.labelFontSize = 12.0,
    this.boxShadow,
    this.border = _defaultBorder,
  }) : activeItemBackgroundColor =
           activeItemBackgroundColor ??
           AppTheme.primaryColor.withValues(alpha: 0.15),
       activeItemColor = activeItemColor ?? AppTheme.primaryColor;

  static Color _defaultBackgroundColor(bool isDark) {
    return AppTheme.navigationBarBackground;
  }

  /// Default border configuration - uses theme's border color
  static Border? _defaultBorder(bool isDark) {
    return Border.all(
      color: AppTheme.borderColor.withValues(
        alpha: 0.3,
      ), // Theme border color with transparency
      width: 0.6,
    );
  }

  /// Default shadow configuration - uses theme's primary color for subtle glow
  static List<BoxShadow> get defaultShadow => [
    // Main shadow - uses theme primary color for subtle glow effect
    BoxShadow(
      color: AppTheme.primaryColor.withValues(alpha: 0.15),
      blurRadius: 15,
      spreadRadius: 6,
    ),
    // Secondary shadow for depth - standard black shadow
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 15,
      spreadRadius: 2,
    ),
  ];
}

/// Default navigation configuration
final defaultNavigationConfig = NavigationConfig(
  boxShadow: NavigationConfig.defaultShadow,
);
