/// Extension methods for clean responsive API
/// Based on Olvora Mobile Responsiveness Guide
library;

import 'package:flutter/widgets.dart';
import 'responsive_service.dart';
import 'breakpoints.dart';

// ===== NUM EXTENSIONS =====

extension ResponsiveNum on num {
  /// Scale by general factor: 16.scaled(context)
  double scaled(BuildContext context) {
    return ResponsiveService.of(context).scale(toDouble());
  }

  /// Scale for text: 14.scaledText(context)
  double scaledText(BuildContext context) {
    return ResponsiveService.of(context).scaleText(toDouble());
  }

  /// Scale vertically: 24.scaledVertical(context)
  double scaledVertical(BuildContext context) {
    return ResponsiveService.of(context).scaleVertical(toDouble());
  }

  /// Scale with minimum value constraint (useful for touch targets)
  /// Example: 40.scaledMin(context, 44) ensures minimum 44px
  double scaledMin(BuildContext context, double min) {
    return ResponsiveService.of(context).scale(toDouble()).clamp(min, double.infinity);
  }

  /// Scale with maximum value constraint
  double scaledMax(BuildContext context, double max) {
    return ResponsiveService.of(context).scale(toDouble()).clamp(0, max);
  }

  /// Scale with both min and max constraints
  double scaledClamped(BuildContext context, double min, double max) {
    return ResponsiveService.of(context).scale(toDouble()).clamp(min, max);
  }
}

// ===== CONTEXT EXTENSIONS =====

extension ResponsiveContext on BuildContext {
  ResponsiveService get responsive => ResponsiveService.of(this);

  double get screenWidth => responsive.screenWidth;
  double get screenHeight => responsive.screenHeight;
  double get contentWidth => responsive.contentWidth;
  double get contentHeight => responsive.contentHeight;

  DeviceCategory get deviceCategory => responsive.category;

  bool get isPhone => responsive.isPhone;
  bool get isTablet => responsive.isTablet;
  bool get isCompactDevice => responsive.isCompact;
  bool get isLandscape => responsive.isLandscape;
  bool get isKeyboardVisible => responsive.isKeyboardVisible;

  EdgeInsets get safePadding => responsive.padding;
  double get safeTop => responsive.safeTop;
  double get safeBottom => responsive.safeBottom;

  /// Select value based on device category
  T responsiveValue<T>({
    required T base,
    T? compact,
    T? small,
    T? tablet,
  }) {
    return responsive.select(
      base: base,
      compact: compact,
      small: small,
      tablet: tablet,
    );
  }
}

// ===== EDGE INSETS EXTENSIONS =====

extension ResponsiveEdgeInsets on EdgeInsets {
  /// Scale all EdgeInsets values
  EdgeInsets scaled(BuildContext context) {
    final r = ResponsiveService.of(context);
    return EdgeInsets.only(
      left: r.scale(left),
      top: r.scaleVertical(top),
      right: r.scale(right),
      bottom: r.scaleVertical(bottom),
    );
  }
}
