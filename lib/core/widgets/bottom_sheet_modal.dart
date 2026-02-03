import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';

/// A reusable bottom sheet modal widget that provides consistent styling
/// across the app for modals like category creation, feature requests, etc.
class BottomSheetModal extends StatelessWidget {
  /// The main content of the bottom sheet
  final Widget child;

  /// Optional title to display at the top
  final String? title;

  /// Optional subtitle to display below the title
  final String? subtitle;

  /// Whether to show the drag handle (default: true)
  final bool showHandle;

  /// Whether to show the close button (default: true)
  final bool showCloseButton;

  /// Custom padding for the content (default: EdgeInsets.symmetric(horizontal: 16))
  final EdgeInsets? padding;

  /// Maximum height as a fraction of screen height (default: 0.92)
  final double maxHeightFraction;

  /// Whether the content is scrollable (default: true)
  final bool isScrollable;

  /// Custom background color (defaults to theme-based color)
  final Color? backgroundColor;

  /// Whether to use gradient background (default: false)
  final bool useGradient;

  /// Custom border radius (default: 20)
  final double borderRadius;

  const BottomSheetModal({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.showHandle = true,
    this.showCloseButton = true,
    this.padding,
    this.maxHeightFraction = 0.92,
    this.isScrollable = true,
    this.backgroundColor,
    this.useGradient = false,
    this.borderRadius = 20,
  });

  /// Show a bottom sheet modal with the given content
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    bool showHandle = true,
    bool showCloseButton = true,
    EdgeInsets? padding,
    double maxHeightFraction = 0.92,
    bool isScrollable = true,
    Color? backgroundColor,
    bool useGradient = false,
    double borderRadius = 20,
    bool isScrollControlled = true,
    bool enableDrag = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => BottomSheetModal(
        title: title,
        subtitle: subtitle,
        showHandle: showHandle,
        showCloseButton: showCloseButton,
        padding: padding,
        maxHeightFraction: maxHeightFraction,
        isScrollable: isScrollable,
        backgroundColor: backgroundColor,
        useGradient: useGradient,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final viewPadding = MediaQuery.of(context).viewPadding;

    // Calculate safe max height accounting for keyboard and system UI
    final safeMaxHeight = (screenHeight - viewPadding.top) * maxHeightFraction;

    // Use theme's modal background; allow override via backgroundColor
    final bgColor = backgroundColor ?? AppTheme.modalBackground;
    final textColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );

    if (isScrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return SafeArea(
      minimum: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: safeMaxHeight),
        decoration: BoxDecoration(
          color: useGradient ? null : bgColor,
          gradient: useGradient
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bgColor, bgColor.withValues(alpha: 0.95)],
                )
              : null,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar (compact)
            if (showHandle) ...[
              SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 10),
            ] else
              SizedBox(height: 12),

            // Title and close button (compact)
            if (title != null || showCloseButton) ...[
              Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              style: AppFonts.textStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (subtitle != null) ...[
                              SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: AppFonts.textStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (showCloseButton) ...[
                      if (title != null) SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 6),
            ],

            // Content
            Flexible(child: content),
          ],
        ),
      ),
    );
  }
}
