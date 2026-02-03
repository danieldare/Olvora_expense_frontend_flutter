/// Responsive service for device-agnostic scaling
/// Based on Olvora Mobile Responsiveness Guide
/// 
/// Uses continuous scaling factor based on reference device (390dp width)
/// rather than arbitrary breakpoints
library;

import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

class ResponsiveService {
  static const double _referenceWidth = 390.0;
  static const double _referenceHeight = 844.0;
  
  // Clamp factors to prevent extreme scaling
  static const double _minScaleFactor = 0.85;
  static const double _maxScaleFactor = 1.25;
  static const double _minTextScale = 0.9;
  static const double _maxTextScale = 1.15;

  final double screenWidth;
  final double screenHeight;
  final double devicePixelRatio;
  final EdgeInsets padding;
  final EdgeInsets viewInsets;
  final EdgeInsets viewPadding;
  final DeviceCategory category;
  final Orientation orientation;

  ResponsiveService._({
    required this.screenWidth,
    required this.screenHeight,
    required this.devicePixelRatio,
    required this.padding,
    required this.viewInsets,
    required this.viewPadding,
    required this.category,
    required this.orientation,
  });

  factory ResponsiveService.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    return ResponsiveService._(
      screenWidth: width,
      screenHeight: mediaQuery.size.height,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      padding: mediaQuery.padding,
      viewInsets: mediaQuery.viewInsets,
      viewPadding: mediaQuery.viewPadding,
      category: Breakpoints.categorize(width),
      orientation: mediaQuery.orientation,
    );
  }

  // ===== SCALING FACTORS =====

  /// Primary scaling factor for general UI elements
  /// Based on screen width relative to reference (390dp)
  double get scaleFactor {
    final raw = screenWidth / _referenceWidth;
    return raw.clamp(_minScaleFactor, _maxScaleFactor);
  }

  /// Text-specific scaling (more conservative)
  /// Prevents text from becoming too large or too small
  double get textScaleFactor {
    final raw = screenWidth / _referenceWidth;
    return raw.clamp(_minTextScale, _maxTextScale);
  }

  /// Height-aware scaling for vertical layouts
  /// Based on screen height relative to reference (844dp)
  double get verticalScaleFactor {
    final raw = screenHeight / _referenceHeight;
    return raw.clamp(_minScaleFactor, _maxScaleFactor);
  }

  // ===== SCALING METHODS =====

  /// Scale a dimension value
  double scale(double value) => value * scaleFactor;

  /// Scale for text (more conservative)
  double scaleText(double value) => value * textScaleFactor;

  /// Scale for vertical spacing
  double scaleVertical(double value) => value * verticalScaleFactor;

  /// Scale with custom min/max clamps
  double scaleConstrained(double value, {double? min, double? max}) {
    final scaled = scale(value);
    if (min != null && scaled < min) return min;
    if (max != null && scaled > max) return max;
    return scaled;
  }

  // ===== SAFE AREA HELPERS =====

  double get safeTop => padding.top;
  double get safeBottom => padding.bottom;
  double get safeLeft => padding.left;
  double get safeRight => padding.right;

  EdgeInsets get safePadding => padding;

  // ===== KEYBOARD HELPERS =====

  bool get isKeyboardVisible => viewInsets.bottom > 0;
  double get keyboardHeight => viewInsets.bottom;

  // ===== CONTENT DIMENSIONS =====

  double get contentWidth => screenWidth - safeLeft - safeRight;
  double get contentHeight => screenHeight - safeTop - safeBottom;
  double get availableHeight => contentHeight - (isKeyboardVisible ? keyboardHeight : 0);

  // ===== DEVICE CHECKS =====

  bool get isCompact => category == DeviceCategory.compact;
  bool get isSmall => category == DeviceCategory.small;
  bool get isMedium => category == DeviceCategory.medium;
  bool get isLarge => category == DeviceCategory.large;
  bool get isXLarge => category == DeviceCategory.xlarge;
  bool get isTablet => category == DeviceCategory.tablet;
  bool get isPhone => Breakpoints.isPhone(screenWidth);
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  // ===== RESPONSIVE VALUE SELECTION =====

  /// Select a value based on device category
  T select<T>({
    required T base,
    T? compact,
    T? small,
    T? medium,
    T? large,
    T? xlarge,
    T? tablet,
  }) {
    return switch (category) {
      DeviceCategory.compact => compact ?? base,
      DeviceCategory.small => small ?? base,
      DeviceCategory.medium => medium ?? base,
      DeviceCategory.large => large ?? base,
      DeviceCategory.xlarge => xlarge ?? base,
      DeviceCategory.tablet => tablet ?? base,
    };
  }

  /// Select between phone and tablet values
  T selectPhoneOrTablet<T>({
    required T phone,
    required T tablet,
  }) {
    return isTablet ? tablet : phone;
  }

  @override
  String toString() {
    return 'ResponsiveService('
        'width: $screenWidth, '
        'height: $screenHeight, '
        'category: $category, '
        'scaleFactor: ${scaleFactor.toStringAsFixed(2)}'
        ')';
  }
}
