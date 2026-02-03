import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable loading spinner widget with consistent styling across the app.
///
/// Provides predefined sizes and colors that match the app's design system.
/// Can be used in buttons, inline loading states, or full-screen loading.
///
/// Example usage:
/// ```dart
/// // Small spinner for buttons
/// LoadingSpinner.small(color: Colors.white)
///
/// // Medium spinner for inline loading
/// LoadingSpinner.medium()
///
/// // Large spinner for full-screen loading
/// LoadingSpinner.large()
/// ```
class LoadingSpinner extends StatelessWidget {
  /// The size of the spinner
  final double size;

  /// The color of the spinner
  final Color? color;

  /// The stroke width of the spinner
  final double strokeWidth;

  /// Small spinner (typically 16-20px) for buttons and compact spaces
  const LoadingSpinner.small({
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 2,
  });

  /// Medium spinner (typically 24-32px) for inline loading states
  const LoadingSpinner.medium({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
  });

  /// Large spinner (typically 40-48px) for full-screen loading
  const LoadingSpinner.large({
    super.key,
    this.size = 48,
    this.color,
    this.strokeWidth = 3,
  });

  /// Custom spinner with full control over size, color, and stroke width
  const LoadingSpinner({
    super.key,
    required this.size,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? AppTheme.primaryColor;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(defaultColor),
      ),
    );
  }
}

/// Predefined loading spinner variants for common use cases
class LoadingSpinnerVariants {
  /// White spinner (for dark backgrounds)
  static Widget white({
    double size = 20,
    double strokeWidth = 2,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  /// Primary color spinner
  static Widget primary({
    double size = 24,
    double strokeWidth = 2.5,
  }) {
    return LoadingSpinner(
      size: size,
      color: AppTheme.primaryColor,
      strokeWidth: strokeWidth,
    );
  }

  /// Warning color spinner
  static Widget warning({
    double size = 24,
    double strokeWidth = 2.5,
  }) {
    return LoadingSpinner(
      size: size,
      color: AppTheme.warningColor,
      strokeWidth: strokeWidth,
    );
  }

  /// Black spinner (for light backgrounds)
  static Widget black({
    double size = 20,
    double strokeWidth = 2,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
      ),
    );
  }
}

