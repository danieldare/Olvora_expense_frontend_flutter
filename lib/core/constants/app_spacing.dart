/// Centralized spacing constants for consistent layout throughout the app.
///
/// This file defines all spacing values used in the application to ensure
/// visual consistency and make it easier to maintain and adjust spacing globally.
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // ==================== Horizontal Padding ====================

  /// Standard horizontal padding for screen edges (16px)
  /// Reduced from 20px for a more compact layout
  static const double screenHorizontal = 16.0;

  // ==================== Card Padding ====================

  /// Standard padding for cards (18px)
  /// Reduced from 24px for a more compact appearance
  static const double cardPadding = 18.0;

  /// Small padding for compact cards (14px)
  static const double cardPaddingSmall = 14.0;

  // ==================== Vertical Spacing (Between Sections) ====================

  /// Large spacing between major sections (20px)
  /// Reduced from 28-32px
  static const double sectionLarge = 20.0;

  /// Medium spacing between sections (16px)
  /// Reduced from 24px
  static const double sectionMedium = 16.0;

  /// Small spacing between sections (12px)
  /// Reduced from 16px
  static const double sectionSmall = 12.0;

  // ==================== Internal Spacing ====================

  /// Large internal spacing (16px)
  static const double spacingLarge = 16.0;

  /// Medium internal spacing (12px)
  static const double spacingMedium = 12.0;

  /// Small internal spacing (8px)
  static const double spacingSmall = 8.0;

  /// Extra small spacing (6px)
  static const double spacingXSmall = 6.0;

  /// Extra extra small spacing (4px)
  static const double spacingXXSmall = 4.0;

  /// Padding for compact message rows (no weekly budget set, active trip banner)
  static const double messageRowPaddingHorizontal = 9.0;
  static const double messageRowPaddingVertical = 8.0;

  // ==================== UI Element Sizes ====================

  /// Avatar size (44px)
  /// Reduced from 52px for a more compact header
  static const double avatarSize = 44.0;

  /// Large icon container size (40px)
  /// Reduced from 48px
  static const double iconContainerLarge = 40.0;

  /// Medium icon container size (36px)
  /// Reduced from 44px
  static const double iconContainerMedium = 36.0;

  /// Standard icon size (20px)
  static const double iconSize = 20.0;

  /// Small icon size (18px)
  static const double iconSizeSmall = 18.0;

  // ==================== App Logo (Auth Screens) ====================

  /// App logo container size for auth screens (70px)
  /// Used consistently across welcome, auth, register, and splash screens
  static const double authLogoSize = 70.0;

  /// App logo icon size for auth screens (42px)
  /// Used consistently across welcome, auth, register, and splash screens
  static const double authLogoIconSize = 42.0;

  // ==================== Chart ====================

  /// Standard chart height (180px)
  /// Reduced from 220px for better content density
  static const double chartHeight = 180.0;

  // ==================== Action Card (Home & More) ====================

  /// Fixed height for action cards so Home and More use the same card height (88px base).
  static const double actionCardHeight = 88.0;

  // ==================== Transaction Item ====================

  /// Horizontal padding for transaction items (16px)
  /// Reduced from 20px
  static const double transactionHorizontal = 16.0;

  /// Vertical padding for transaction items (10px)
  static const double transactionVertical = 10.0;

  // ==================== Bottom Navigation ====================

  /// Bottom padding to account for navigation bar (140px)
  /// Ensures content never gets blocked by the floating navigation bar
  /// Navigation bar total height: ~90px (70px min height + 20px margin)
  /// Extra 50px padding provides generous scrolling space
  static const double bottomNavPadding = 140.0;

  // ==================== Border Radius ====================

  /// Large border radius for cards (20px)
  static const double radiusLarge = 20.0;

  /// Medium border radius (16px)
  static const double radiusMedium = 16.0;

  /// Small border radius (12px)
  static const double radiusSmall = 12.0;

  /// Extra small border radius (8px)
  static const double radiusXSmall = 8.0;
}
