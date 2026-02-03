import 'package:flutter/material.dart';

/// Color theme model for app theming system
/// Supports multiple world-class color schemes with complementary colors
class ColorTheme {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final bool isDark;

  // Core colors
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;

  // Complementary color for highlights (e.g., selected period tabs)
  final Color complementaryColor;

  // Status colors
  final Color successColor;
  final Color errorColor;
  final Color warningColor;

  // Card colors
  final Color cardBackground;

  // Wallet gradient
  final List<Color> walletGradient;

  // Navigation active color - color for active bottom navigation items
  final Color navigationActiveColor;

  // Navigation bar background (e.g. bottom nav bar)
  final Color navigationBarBackground;

  // Modal/sheet background (e.g. bottom sheet modals)
  final Color modalBackground;

  const ColorTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.complementaryColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.cardBackground,
    required this.walletGradient,
    required this.navigationActiveColor,
    required this.navigationBarBackground,
    required this.modalBackground,
  });

  /// Default Purple theme (Light) - Existing Olvora brand colors
  static const ColorTheme purple = ColorTheme(
    id: 'purple',
    name: 'Purple Bliss',
    description: 'Classic Olvora purple theme',
    emoji: '💜',
    isDark: false,
    primaryColor: Color(0xFF8B5CF6),
    secondaryColor: Color(0xFFA78BFA),
    accentColor: Color(0xFF6366F1),
    backgroundColor: Color(0xFFFCFBFF), // Lighter lavender
    surfaceColor: Colors.white,
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    borderColor: Color(0xFFE5E7EB),
    complementaryColor: Color(0xFFFFC000), // Golden yellow complement
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFFFC000),
    cardBackground: Colors.white,
    walletGradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED), Color(0xFF6D28D9)],
    navigationActiveColor: Color(0xFF8B5CF6), // Primary color
    navigationBarBackground: Colors.white,
    modalBackground: Colors.white,
  );

  /// Dark Purple theme (Dark) - Dark version of Olvora brand (Purple Night)
  static const ColorTheme purpleDark = ColorTheme(
    id: 'purple_dark',
    name: 'Purple Night',
    description: 'Dark purple for night owls',
    emoji: '🌙',
    isDark: true,
    primaryColor: Color(0xFF8B5CF6),
    secondaryColor: Color(0xFFA78BFA),
    accentColor: Color(0xFF6366F1),
    backgroundColor: Color(0xFF1A1A2E), // Solid purple night
    surfaceColor: Color(0xFF1E1E32),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF94A3B8),
    borderColor: Color(0xFF2D2D44),
    complementaryColor: Color(0xFFFFC000), // Golden yellow complement
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFFFC000),
    cardBackground: Color(0xFF252538), // Solid purple-tinted card
    walletGradient: [Color(0xFF6631EE), Color(0xFF7C3AED), Color(0xFF6631EE)],
    navigationActiveColor: Color(0xFFFFC000), // Yellow for Purple Night
    navigationBarBackground: Color(0xFF1E1E32),
    modalBackground: Color(0xFF252538),
  );

  /// Ocean Blue theme (Light) - Professional and calming
  static const ColorTheme oceanBlue = ColorTheme(
    id: 'ocean_blue',
    name: 'Ocean Blue',
    description: 'Professional and calming',
    emoji: '🌊',
    isDark: false,
    primaryColor: Color(0xFF0EA5E9),
    secondaryColor: Color(0xFF38BDF8),
    accentColor: Color(0xFF0284C7),
    backgroundColor: Color(0xFFFCFEFF), // Lighter blue tint
    surfaceColor: Colors.white,
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    borderColor: Color(0xFFE0F2FE),
    complementaryColor: Color(0xFFFB923C), // Coral orange complement
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFF59E0B),
    cardBackground: Colors.white,
    walletGradient: [Color(0xFF0EA5E9), Color(0xFF0284C7), Color(0xFF0369A1)],
    navigationActiveColor: Color(0xFF0EA5E9), // Primary color
    navigationBarBackground: Colors.white,
    modalBackground: Colors.white,
  );

  /// Ocean Blue Dark theme (Dark) - Ocean at night
  static const ColorTheme oceanBlueDark = ColorTheme(
    id: 'ocean_blue_dark',
    name: 'Ocean Night',
    description: 'Ocean blue for dark mode',
    emoji: '🌊',
    isDark: true,
    primaryColor: Color(0xFF0EA5E9),
    secondaryColor: Color(0xFF38BDF8),
    accentColor: Color(0xFF0284C7),
    backgroundColor: Color(0xFF0F172A),
    surfaceColor: Color(0xFF1E293B),
    textPrimary: Color(0xFFF0F9FF),
    textSecondary: Color(0xFF94A3B8),
    borderColor: Color(0xFF334155),
    complementaryColor: Color(0xFFFB923C), // Coral orange complement
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFF59E0B),
    cardBackground: Color(0xFF1E293B),
    walletGradient: [Color(0xFF0EA5E9), Color(0xFF0284C7), Color(0xFF0369A1)],
    navigationActiveColor: Color(0xFF0EA5E9), // Primary color
    navigationBarBackground: Color(0xFF1E293B),
    modalBackground: Color(0xFF1E293B),
  );

  /// Midnight Blue theme (Dark) - Deep dark professional
  static const ColorTheme midnightBlue = ColorTheme(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    description: 'Deep dark professional',
    emoji: '🌌',
    isDark: true,
    primaryColor: Color(0xFF3B82F6),
    secondaryColor: Color(0xFF60A5FA),
    accentColor: Color(0xFF2563EB),
    backgroundColor: Color(0xFF0F172A),
    surfaceColor: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    borderColor: Color(0xFF334155),
    complementaryColor: Color(0xFFFBBF24), // Amber yellow complement
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFFBBF24),
    cardBackground: Color(0xFF1E293B),
    walletGradient: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1E40AF)],
    navigationActiveColor: Color(0xFF3B82F6), // Primary color
    navigationBarBackground: Color(0xFF1E293B),
    modalBackground: Color(0xFF1E293B),
  );

  /// Vibrant Purple theme (Light) - Electric purple with analogous colors
  static const ColorTheme vibrantPurple = ColorTheme(
    id: 'vibrant_purple',
    name: 'Vibrant Purple',
    description: 'Electric purple with magenta and blue accents',
    emoji: '⚡',
    isDark: false,
    primaryColor: Color(0xFF6631EE),
    secondaryColor: Color(0xFFC431EE),
    accentColor: Color(0xFF315BEE),
    backgroundColor: Color(0xFFFCFBFF), // Lighter purple tint
    surfaceColor: Colors.white,
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    borderColor: Color(0xFFE5E7EB),
    complementaryColor: Color(0xFFFFD700), // Golden yellow complement
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFFFC000),
    cardBackground: Colors.white,
    walletGradient: [
      Color(0xFF6631EE), // Primary
      Color(0xFFC431EE), // Secondary (magenta-purple)
      Color(0xFF315BEE), // Accent (blue-purple)
    ],
    navigationActiveColor: Color(0xFF6631EE), // Primary color
    navigationBarBackground: Colors.white,
    modalBackground: Colors.white,
  );

  /// Vibrant Purple Dark theme (Dark) - Electric purple for dark mode
  static const ColorTheme vibrantPurpleDark = ColorTheme(
    id: 'vibrant_purple_dark',
    name: 'Vibrant Night',
    description: 'Electric purple for dark mode',
    emoji: '⚡',
    isDark: true,
    primaryColor: Color(0xFF6631EE),
    secondaryColor: Color(0xFFC431EE),
    accentColor: Color(0xFF315BEE),
    backgroundColor: Color(0xFF1A0F2E),
    surfaceColor: Color(0xFF241639),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF94A3B8),
    borderColor: Color(0xFF3D2A5C),
    complementaryColor: Color(0xFFFFD700), // Golden yellow complement
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFFFC000),
    cardBackground: Color(0xFF241639),
    walletGradient: [
      Color(0xFF6631EE), // Primary
      Color(0xFFC431EE), // Secondary (magenta-purple)
      Color(0xFF315BEE), // Accent (blue-purple)
    ],
    navigationActiveColor: Color(0xFF6631EE), // Primary color
    navigationBarBackground: Color(0xFF241639),
    modalBackground: Color(0xFF241639),
  );

  /// Indigo theme (Light) - Blue-purple accent (Request Feature modal style)
  static const ColorTheme indigo = ColorTheme(
    id: 'indigo',
    name: 'Indigo',
    description: 'Blue-purple accent, clean and modern',
    emoji: '💡',
    isDark: false,
    primaryColor: Color(
      0xFF6366F1,
    ), // Indigo-500, matches Request Feature accent
    secondaryColor: Color(0xFF818CF8),
    accentColor: Color(0xFF4F46E5),
    backgroundColor: Color(0xFFF8FAFC),
    surfaceColor: Colors.white,
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    borderColor: Color(0xFFE2E8F0),
    complementaryColor: Color(0xFFF59E0B), // Amber complement
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFF59E0B),
    cardBackground: Colors.white,
    walletGradient: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
    navigationActiveColor: Color(0xFF6366F1),
    navigationBarBackground: Colors.white,
    modalBackground: Colors.white,
  );

  /// Indigo Dark theme (Dark) - Blue-purple for dark mode
  static const ColorTheme indigoDark = ColorTheme(
    id: 'indigo_dark',
    name: 'Indigo Night',
    description: 'Blue-purple accent for dark mode',
    emoji: '💡',
    isDark: true,
    primaryColor: Color(0xFF6366F1),
    secondaryColor: Color(0xFF818CF8),
    accentColor: Color(0xFF818CF8),
    backgroundColor: Color(0xFF0F172A),
    surfaceColor: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    borderColor: Color(0xFF334155),
    complementaryColor: Color(0xFFF59E0B),
    successColor: Color(0xFF10B981),
    errorColor: Color(0xFFEF4444),
    warningColor: Color(0xFFF59E0B),
    cardBackground: Color.fromARGB(136, 30, 41, 59),
    navigationBarBackground: Color(0xFF1E293B),
    modalBackground: Color.fromARGB(255, 30, 36, 48),
    walletGradient: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
    navigationActiveColor: Color(0xFF6366F1),
  );

  /// Get all available color themes
  static List<ColorTheme> get allThemes => [
    purple,
    purpleDark,
    indigo,
    indigoDark,
    vibrantPurple,
    vibrantPurpleDark,
    oceanBlue,
    oceanBlueDark,
    midnightBlue,
  ];

  /// Get light themes only
  static List<ColorTheme> get lightThemes =>
      allThemes.where((theme) => !theme.isDark).toList();

  /// Get dark themes only
  static List<ColorTheme> get darkThemes =>
      allThemes.where((theme) => theme.isDark).toList();

  /// Find theme by ID
  static ColorTheme? findById(String id) {
    try {
      return allThemes.firstWhere((theme) => theme.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Default theme
  static const ColorTheme defaultTheme = purple;

  /// Default dark theme
  static const ColorTheme defaultDarkTheme = purpleDark;
}
