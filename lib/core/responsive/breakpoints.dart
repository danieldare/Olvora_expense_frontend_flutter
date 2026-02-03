/// Device breakpoints and categorization
/// Based on Olvora Mobile Responsiveness Guide
library;

enum DeviceCategory {
  compact,  // < 360dp
  small,    // 360-389dp
  medium,   // 390-413dp
  large,    // 414-479dp
  xlarge,   // 480-599dp
  tablet,   // >= 600dp
}

class Breakpoints {
  static const double compact = 0;
  static const double small = 360;
  static const double medium = 390;
  static const double large = 414;
  static const double xlarge = 480;
  static const double tablet = 600;

  /// Returns the device category based on screen width
  static DeviceCategory categorize(double width) {
    if (width >= tablet) return DeviceCategory.tablet;
    if (width >= xlarge) return DeviceCategory.xlarge;
    if (width >= large) return DeviceCategory.large;
    if (width >= medium) return DeviceCategory.medium;
    if (width >= small) return DeviceCategory.small;
    return DeviceCategory.compact;
  }

  /// Check if device is considered "phone-sized"
  static bool isPhone(double width) => width < tablet;

  /// Check if device supports multi-column layouts
  static bool supportsMultiColumn(double width) => width >= xlarge;
}
