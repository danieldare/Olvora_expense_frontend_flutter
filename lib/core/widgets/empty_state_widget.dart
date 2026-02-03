import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../constants/app_spacing.dart';
import '../responsive/responsive_extensions.dart';

/// A world-class, reusable empty state widget for displaying "no data" states
/// throughout the application.
///
/// Features:
/// - Consistent design language across the app
/// - Dark mode support
/// - Flexible customization (icon, title, description, action)
/// - Multiple size variants
/// - Optional container styling
class EmptyStateWidget extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// The main title text
  final String title;

  /// Optional subtitle/description text
  final String? subtitle;

  /// Optional action button
  final Widget? action;

  /// Icon size (default: 64)
  final double iconSize;

  /// Whether to show the icon in a circular container
  final bool showIconContainer;

  /// Custom icon color (defaults to theme-aware color)
  final Color? iconColor;

  /// Custom container background color
  final Color? containerColor;

  /// Custom container border color
  final Color? containerBorderColor;

  /// Padding around the content
  final EdgeInsets padding;

  /// Whether to wrap in a styled container
  final bool useContainer;

  /// Container border radius
  final double borderRadius;

  /// Size variant for different contexts
  final EmptyStateSize size;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 64,
    this.showIconContainer = false,
    this.iconColor,
    this.containerColor,
    this.containerBorderColor,
    this.padding = const EdgeInsets.all(40),
    this.useContainer = false,
    this.borderRadius = 20,
    this.size = EmptyStateSize.medium,
  });

  /// Factory constructor for compact empty states (used in cards/modals)
  factory EmptyStateWidget.compact({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
    Color? iconColor,
    Color? containerColor,
    Color? containerBorderColor,
    EdgeInsets? padding,
    bool useContainer = false,
  }) {
    return EmptyStateWidget(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: action,
      iconSize: 36,
      size: EmptyStateSize.compact,
      iconColor: iconColor,
      containerColor: containerColor,
      containerBorderColor: containerBorderColor,
      padding: padding ?? const EdgeInsets.all(40),
      useContainer: useContainer,
    );
  }

  /// Factory constructor for large empty states (used in full screens)
  factory EmptyStateWidget.large({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
    bool showIconContainer = true,
    Color? iconColor,
  }) {
    return EmptyStateWidget(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: action,
      iconSize: 80,
      size: EmptyStateSize.large,
      showIconContainer: showIconContainer,
      iconColor: iconColor,
      padding: const EdgeInsets.all(40),
      useContainer: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor =
        iconColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.3)
            : AppTheme.textSecondary.withValues(alpha: 0.5));

    final effectiveContainerColor =
        containerColor ?? (isDark ? AppTheme.darkCardBackground : Colors.white);

    final effectiveBorderColor =
        containerBorderColor ??
        (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderColor);

    final titleStyle = _getTitleStyle(isDark, context);
    final subtitleStyle = _getSubtitleStyle(isDark, context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        if (showIconContainer)
          Container(
            width: (iconSize + 16).scaled(context),
            height: (iconSize + 16).scaled(context),
            decoration: BoxDecoration(
              // Enhanced contrast: increased from 0.1 to 0.25-0.35
              color: effectiveIconColor.withValues(alpha: isDark ? 0.35 : 0.25),
              shape: BoxShape.circle,
              // Add subtle shadow for depth
              boxShadow: [
                BoxShadow(
                  color: effectiveIconColor.withValues(alpha: isDark ? 0.2 : 0.15),
                  blurRadius: 6.scaled(context),
                  offset: Offset(0, 2.scaled(context)),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(icon, size: iconSize.scaled(context), color: effectiveIconColor),
          )
        else
          Icon(icon, size: iconSize.scaled(context), color: effectiveIconColor),

        SizedBox(height: _getSpacing().scaled(context)),

        // Title
        Text(title, style: titleStyle, textAlign: TextAlign.center),

        // Subtitle
        if (subtitle != null) ...[
          SizedBox(height: _getSubtitleSpacing().scaled(context)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: Text(
              subtitle!,
              style: subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],

        // Action button
        if (action != null) ...[SizedBox(height: _getActionSpacing().scaled(context)), action!],
      ],
    );

    if (useContainer) {
      return Padding(
        padding: padding.scaled(context),
        child: Container(
          padding: EdgeInsets.all(40.scaled(context)),
          decoration: BoxDecoration(
            color: effectiveContainerColor,
            borderRadius: BorderRadius.circular(borderRadius.scaled(context)),
            border: Border.all(color: effectiveBorderColor, width: 1),
          ),
          child: Center(child: content),
        ),
      );
    }

    return Padding(
      padding: padding.scaled(context),
      child: Center(child: content),
    );
  }

  TextStyle _getTitleStyle(bool isDark, BuildContext context) {
    switch (size) {
      case EmptyStateSize.compact:
        return AppFonts.textStyle(
          fontSize: 14.scaledText(context),
          fontWeight: FontWeight.w700,
          color: isDark
              ? Colors.white.withValues(alpha: 0.9)
              : AppTheme.textPrimary,
        );
      case EmptyStateSize.medium:
        return AppFonts.textStyle(
          fontSize: 18.scaledText(context),
          fontWeight: FontWeight.w700, // Increased from w600
          color: isDark ? Colors.white : AppTheme.textPrimary,
        );
      case EmptyStateSize.large:
        return AppFonts.textStyle(
          fontSize: 20.scaledText(context),
          fontWeight: FontWeight.w800, // Increased from w700
          color: isDark ? Colors.white : AppTheme.textPrimary,
          letterSpacing: -0.3,
        );
    }
  }

  TextStyle _getSubtitleStyle(bool isDark, BuildContext context) {
    switch (size) {
      case EmptyStateSize.compact:
        return AppFonts.textStyle(
          fontSize: 13.scaledText(context),
          fontWeight: FontWeight.w500, // Added weight
          color: isDark
              ? Colors.grey[300]! // Enhanced contrast
              : AppTheme.textSecondary.withValues(alpha: 0.9), // Enhanced contrast
        );
      case EmptyStateSize.medium:
        return AppFonts.textStyle(
          fontSize: 14.scaledText(context),
          fontWeight: FontWeight.w500, // Added weight
          color: isDark
              ? Colors.grey[300]! // Enhanced contrast
              : AppTheme.textSecondary.withValues(alpha: 0.9), // Enhanced contrast
        );
      case EmptyStateSize.large:
        return AppFonts.textStyle(
          fontSize: 14.scaledText(context),
          fontWeight: FontWeight.w500, // Increased from w400
          color: isDark
              ? Colors.grey[300]! // Enhanced contrast
              : AppTheme.textSecondary.withValues(alpha: 0.9), // Enhanced contrast
          height: 1.5,
        );
    }
  }

  double _getSpacing() {
    switch (size) {
      case EmptyStateSize.compact:
        return 16;
      case EmptyStateSize.medium:
        return 16;
      case EmptyStateSize.large:
        return 24;
    }
  }

  double _getSubtitleSpacing() {
    switch (size) {
      case EmptyStateSize.compact:
        return 8;
      case EmptyStateSize.medium:
        return 8;
      case EmptyStateSize.large:
        return 12;
    }
  }

  double _getActionSpacing() {
    switch (size) {
      case EmptyStateSize.compact:
        return 20;
      case EmptyStateSize.medium:
        return 24;
      case EmptyStateSize.large:
        return 32;
    }
  }
}

/// Size variants for empty state widget
enum EmptyStateSize {
  /// Compact size for cards and modals (icon: 36, title: 14)
  compact,

  /// Medium size for standard screens (icon: 64, title: 18)
  medium,

  /// Large size for prominent empty states (icon: 80, title: 20)
  large,
}
