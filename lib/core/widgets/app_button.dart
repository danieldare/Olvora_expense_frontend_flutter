import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../constants/app_spacing.dart';
import '../responsive/responsive_extensions.dart';
import 'loading_spinner.dart';

/// Reusable button component with consistent styling across the app
///
/// Supports multiple sizes and variants:
/// - Primary: Large, prominent button (for main CTAs like "Create free account")
/// - Secondary: Medium button (for secondary actions)
/// - Tertiary: Small button (for less important actions)
class AppButton extends StatelessWidget {
  /// Button label text
  final String label;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button size variant
  final AppButtonSize size;

  /// Button style variant
  final AppButtonVariant variant;

  /// Whether button is in loading state
  final bool isLoading;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Optional image icon path (for OAuth buttons like Google)
  final String? imageIcon;

  /// Custom background color (overrides variant default)
  final Color? backgroundColor;

  /// Custom text color (overrides variant default)
  final Color? textColor;

  /// Whether button should expand to full width
  final bool isFullWidth;

  /// Custom padding (overrides size default)
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.secondary,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.imageIcon,
    this.backgroundColor,
    this.textColor,
    this.isFullWidth = true,
    this.padding,
  });

  /// Primary button - Large, prominent (for main CTAs)
  factory AppButton.primary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool isFullWidth = true,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      size: AppButtonSize.primary,
      variant: AppButtonVariant.primary,
      isLoading: isLoading,
      icon: icon,
      isFullWidth: isFullWidth,
    );
  }

  /// Secondary button - Medium size
  factory AppButton.secondary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    bool isFullWidth = true,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      size: AppButtonSize.secondary,
      variant: AppButtonVariant.secondary,
      isLoading: isLoading,
      icon: icon,
      isFullWidth: isFullWidth,
    );
  }

  /// Outlined button variant
  factory AppButton.outlined({
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    String? imageIcon,
    bool isFullWidth = true,
    Color? borderColor,
    Color? textColor,
    Color? backgroundColor,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      size: AppButtonSize.secondary,
      variant: AppButtonVariant.outlined,
      isLoading: isLoading,
      icon: icon,
      imageIcon: imageIcon,
      isFullWidth: isFullWidth,
      textColor: textColor,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get size-specific properties
    final sizeProps = _getSizeProperties(context);

    // Get variant-specific colors
    final colors = _getVariantColors(isDark);

    // Determine spinner color based on button background
    // For OAuth buttons with custom backgrounds, use appropriate spinner color
    final spinnerColor = backgroundColor != null
        ? (backgroundColor == Colors.white
              ? LoadingSpinnerVariants.black(size: sizeProps.loadingSpinnerSize)
              : LoadingSpinnerVariants.white(
                  size: sizeProps.loadingSpinnerSize,
                ))
        : (variant == AppButtonVariant.primary
              ? LoadingSpinnerVariants.black(size: sizeProps.loadingSpinnerSize)
              : LoadingSpinnerVariants.white(
                  size: sizeProps.loadingSpinnerSize,
                ));

    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: isLoading
          ? [
              SizedBox(
                height: sizeProps.loadingSpinnerSize,
                width: sizeProps.loadingSpinnerSize,
                child: spinnerColor,
              ),
            ]
          : [
              if (imageIcon != null) ...[
                Image.asset(
                  imageIcon!,
                  width: sizeProps.iconSize,
                  height: sizeProps.iconSize,
                  errorBuilder: (context, error, stackTrace) {
                    return icon != null
                        ? Icon(
                            icon,
                            size: sizeProps.iconSize,
                            color: textColor ?? colors.textColor,
                          )
                        : const SizedBox.shrink();
                  },
                ),
                SizedBox(width: AppSpacing.spacingSmall.scaled(context)),
              ] else if (icon != null) ...[
                Icon(
                  icon,
                  size: sizeProps.iconSize,
                  color: textColor ?? colors.textColor,
                ),
                SizedBox(width: AppSpacing.spacingSmall.scaled(context)),
              ],
              Text(
                label,
                style: AppFonts.textStyle(
                  fontSize: sizeProps.fontSize,
                  fontWeight: sizeProps.fontWeight,
                  color: textColor ?? colors.textColor,
                ),
              ),
            ],
    );

    // For OAuth buttons with custom background, use the provided backgroundColor
    final outlinedBgColor =
        variant == AppButtonVariant.outlined && backgroundColor != null
        ? backgroundColor
        : Colors.transparent;

    final effectiveOnPressed = onPressed;
    final button = variant == AppButtonVariant.outlined
        ? OutlinedButton(
            onPressed: effectiveOnPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: outlinedBgColor,
              foregroundColor: textColor ?? colors.textColor,
              disabledBackgroundColor: outlinedBgColor,
              disabledForegroundColor: textColor ?? colors.textColor,
              side: BorderSide(
                color: backgroundColor != null
                    ? Colors
                          .transparent // Hide border if custom background is provided
                    : (colors.borderColor ??
                          (isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppTheme.borderColor)),
                width: backgroundColor != null
                    ? 0
                    : 1.5, // No border for custom backgrounds
              ),
              padding: padding ?? sizeProps.padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  sizeProps.borderRadius.scaled(context),
                ),
              ),
            ),
            child: buttonContent,
          )
        : ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? colors.backgroundColor,
              foregroundColor: textColor ?? colors.textColor,
              disabledBackgroundColor:
                  backgroundColor ?? colors.backgroundColor,
              disabledForegroundColor: textColor ?? colors.textColor,
              padding: padding ?? sizeProps.padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  sizeProps.borderRadius.scaled(context),
                ),
              ),
              elevation: variant == AppButtonVariant.primary ? 2 : 0,
            ),
            child: buttonContent,
          );

    final wrappedButton = isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;

    return isLoading ? IgnorePointer(child: wrappedButton) : wrappedButton;
  }

  _SizeProperties _getSizeProperties(BuildContext context) {
    switch (size) {
      case AppButtonSize.primary:
        return _SizeProperties(
          fontSize: 16.scaledText(context),
          fontWeight: FontWeight.w700,
          padding: EdgeInsets.symmetric(vertical: 16.scaledVertical(context)),
          borderRadius: AppSpacing.radiusSmall,
          iconSize: 20.scaled(context),
          loadingSpinnerSize: 20.scaled(context),
        );
      case AppButtonSize.secondary:
        return _SizeProperties(
          fontSize: 14.scaledText(context),
          fontWeight: FontWeight.w600,
          padding: EdgeInsets.symmetric(vertical: 12.scaledVertical(context)),
          borderRadius: AppSpacing.radiusSmall,
          iconSize: 18.scaled(context),
          loadingSpinnerSize: 18.scaled(context),
        );
      case AppButtonSize.tertiary:
        return _SizeProperties(
          fontSize: 13.scaledText(context),
          fontWeight: FontWeight.w600,
          padding: EdgeInsets.symmetric(vertical: 10.scaledVertical(context)),
          borderRadius: AppSpacing.radiusSmall,
          iconSize: 16.scaled(context),
          loadingSpinnerSize: 16.scaled(context),
        );
    }
  }

  _ButtonColors _getVariantColors(bool isDark) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(
          backgroundColor: AppTheme.warningColor,
          textColor: Colors.black,
        );
      case AppButtonVariant.secondary:
        return _ButtonColors(
          backgroundColor: AppTheme.primaryColor,
          textColor: Colors.white,
        );
      case AppButtonVariant.outlined:
        return _ButtonColors(
          backgroundColor: Colors.transparent,
          textColor: Colors.white, // For auth screen gradient background
          borderColor: Colors.white.withValues(alpha: 0.4),
        );
    }
  }
}

/// Button size variants
enum AppButtonSize {
  /// Primary - Largest button (for main CTAs)
  primary,

  /// Secondary - Medium button (for secondary actions)
  secondary,

  /// Tertiary - Small button (for less important actions)
  tertiary,
}

/// Button style variants
enum AppButtonVariant {
  /// Primary - Filled button with warning color (yellow/black)
  primary,

  /// Secondary - Filled button with primary color (purple/white)
  secondary,

  /// Outlined - Outlined button with transparent background
  outlined,
}

/// Internal class for size-specific properties
class _SizeProperties {
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsets padding;
  final double borderRadius;
  final double iconSize;
  final double loadingSpinnerSize;

  _SizeProperties({
    required this.fontSize,
    required this.fontWeight,
    required this.padding,
    required this.borderRadius,
    required this.iconSize,
    required this.loadingSpinnerSize,
  });
}

/// Internal class for variant-specific colors
class _ButtonColors {
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  _ButtonColors({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });
}
