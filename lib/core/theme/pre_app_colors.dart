import 'package:flutter/material.dart';

/// Fixed color palette for splash, auth, and onboarding screens.
///
/// These screens are shown before the user has chosen an app theme, so they
/// use a consistent brand look and are NOT affected by the app's color theme.
/// Use [PreAppColors] only for: SplashScreen, AuthScreen, OnboardingScreen,
/// WelcomeScreen, and related auth/onboarding flows (currency selection,
/// notification permission, signup success, first expense onboarding).
class PreAppColors {
  PreAppColors._();

  // --- Brand gradient (purple) ---
  static const Color _primary = Color(0xFF5F34E5);
  static const Color _primaryMid = Color.fromARGB(255, 136, 96, 248);
  static const Color _primaryEnd = Color.fromARGB(255, 120, 82, 233);

  /// Gradient for splash, auth, onboarding backgrounds. Always the same.
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_primary, _primaryMid, _primaryEnd],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gradient used on splash (same as auth for consistency).
  static const List<Color> walletGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF7C3AED),
    Color(0xFF6D28D9),
  ];

  /// Primary purple for logos, icons, loading indicators.
  static const Color primaryColor = Color(0xFF8B5CF6);

  /// Lighter purple for WalletAppIcon shimmer (e.g. 0xFF8B7AFF).
  static const Color primaryLight = Color(0xFF8B7AFF);

  /// Accent/warning (gold) for "expense" text, CTAs, highlights.
  static const Color warningColor = Color(0xFFFFC000);

  /// Success green for success states.
  static const Color successColor = Color(0xFF10B981);

  /// Error red for error states.
  static const Color errorColor = Color(0xFFEF4444);
}
