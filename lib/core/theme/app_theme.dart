import 'package:flutter/material.dart';
import 'app_fonts.dart';
import '../models/color_theme.dart';
import 'dynamic_theme_colors.dart';

class AppTheme {
  // Dynamic colors that automatically update based on selected theme
  // These getters delegate to DynamicThemeColors which is updated when theme changes
  static Color get primaryColor => DynamicThemeColors.primaryColor;
  static Color get secondaryColor => DynamicThemeColors.secondaryColor;
  static Color get accentColor => DynamicThemeColors.accentColor;
  static Color get successColor => DynamicThemeColors.successColor;
  static Color get errorColor => DynamicThemeColors.errorColor;
  static Color get warningColor => DynamicThemeColors.warningColor;
  static Color get backgroundColor => DynamicThemeColors.backgroundColor;
  static Color get surfaceColor => DynamicThemeColors.surfaceColor;
  static Color get textPrimary => DynamicThemeColors.textPrimary;
  static Color get textSecondary => DynamicThemeColors.textSecondary;
  static Color get borderColor => DynamicThemeColors.borderColor;
  static Color get complementaryColor => DynamicThemeColors.complementaryColor;
  static Color get cardBackground => DynamicThemeColors.cardBackground;
  static Color get darkCardBackground => DynamicThemeColors.darkCardBackground;

  // Screen background color - uses theme's backgroundColor as single source of truth
  static Color get screenBackgroundColor => DynamicThemeColors.backgroundColor;

  // Wallet gradient colors - now dynamic based on theme
  static List<Color> get walletGradient => DynamicThemeColors.walletGradient;

  // Navigation active color - color for active bottom navigation items
  static Color get navigationActiveColor =>
      DynamicThemeColors.navigationActiveColor;

  // Navigation bar background (e.g. bottom nav bar)
  static Color get navigationBarBackground =>
      DynamicThemeColors.navigationBarBackground;

  // Modal/sheet background (e.g. bottom sheet modals)
  static Color get modalBackground => DynamicThemeColors.modalBackground;

  // Purple gradient - single source of truth for purple theme
  // Used by splash screen, auth screen, and spending summary card
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5F34E5),
      Color.fromARGB(255, 136, 96, 248),
      Color.fromARGB(255, 120, 82, 233),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Light auth gradient - vibrant purple for light mode
  static const LinearGradient lightAuthGradient = purpleGradient;

  // Dark auth gradient - deeper, more muted tones for dark mode
  static const LinearGradient darkAuthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E), // Deep purple-navy
      Color(0xFF2D1B4E), // Dark purple
      Color(0xFF1E1E32), // Purple night surface
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Auth screen gradient - dynamically switches based on theme
  static LinearGradient get authGradient {
    return DynamicThemeColors.isDark ? darkAuthGradient : lightAuthGradient;
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: AppFonts.textTheme.copyWith(
        displayLarge: AppFonts.textStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
          height: 1.1,
          color: textPrimary,
        ),
        displayMedium: AppFonts.textStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
          height: 1.1,
          color: textPrimary,
        ),
        displaySmall: AppFonts.textStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.1,
          color: textPrimary,
        ),
        headlineLarge: AppFonts.textStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: textPrimary,
        ),
        headlineMedium: AppFonts.textStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: textPrimary,
        ),
        headlineSmall: AppFonts.textStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: textPrimary,
        ),
        titleLarge: AppFonts.textStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: textPrimary,
        ),
        titleMedium: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        titleSmall: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        bodyLarge: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        bodyMedium: AppFonts.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: textPrimary,
        ),
        bodySmall: AppFonts.textStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: textSecondary,
        ),
        labelLarge: AppFonts.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        labelMedium: AppFonts.textStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: textPrimary,
        ),
        labelSmall: AppFonts.textStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: AppFonts.textStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        errorStyle: TextStyle(color: errorColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppFonts.textStyle(
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        unselectedLabelStyle: AppFonts.textStyle(
          fontWeight: FontWeight.normal,
          color: Colors.grey[600],
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: primaryColor.withValues(alpha: 1.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppFonts.textStyle(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return AppFonts.textStyle(
            fontWeight: FontWeight.normal,
            color: Colors.grey[600],
          );
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF1E293B);
    const darkCard = Color(0xFF1E293B);
    const darkBorder = Color(0xFF334155);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      surface: darkCard,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      dividerColor: darkBorder,
      textTheme: AppFonts.textTheme.copyWith(
        displayLarge: AppFonts.textStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
          color: Colors.white,
        ),
        displayMedium: AppFonts.textStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
          color: Colors.white,
        ),
        headlineMedium: AppFonts.textStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Colors.white,
        ),
        titleLarge: AppFonts.textStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Colors.white,
        ),
        titleMedium: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: Colors.white,
        ),
        titleSmall: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: Colors.white,
        ),
        bodyLarge: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.1,
          color: Colors.white,
        ),
        bodyMedium: AppFonts.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: Colors.grey[300],
        ),
        bodySmall: AppFonts.textStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: Colors.grey[400],
        ),
        labelLarge: AppFonts.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: Colors.white,
        ),
        labelMedium: AppFonts.textStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
        labelSmall: AppFonts.textStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: Colors.grey[300],
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: AppFonts.textStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: darkCard,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        errorStyle: TextStyle(color: errorColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[400],
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppFonts.textStyle(
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        unselectedLabelStyle: AppFonts.textStyle(
          fontWeight: FontWeight.normal,
          color: Colors.grey[400],
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        elevation: 8,
        indicatorColor: primaryColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppFonts.textStyle(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            );
          }
          return AppFonts.textStyle(
            fontWeight: FontWeight.normal,
            color: Colors.grey[400],
          );
        }),
      ),
    );
  }

  /// Generate ThemeData from a ColorTheme
  static ThemeData fromColorTheme(ColorTheme colorTheme) {
    final brightness = colorTheme.isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colorTheme.primaryColor,
      brightness: brightness,
      primary: colorTheme.primaryColor,
      secondary: colorTheme.secondaryColor,
      tertiary: colorTheme.accentColor,
      error: colorTheme.errorColor,
      surface: colorTheme.surfaceColor,
    );

    final textPrimary = colorTheme.textPrimary;
    final textSecondary = colorTheme.textSecondary;
    final borderColorValue = colorTheme.borderColor;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorTheme.backgroundColor,
      dividerColor: colorTheme.isDark ? borderColorValue : null,
      textTheme: AppFonts.textTheme.copyWith(
        displayLarge: AppFonts.textStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
          height: 1.1,
          color: textPrimary,
        ),
        displayMedium: AppFonts.textStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
          height: 1.1,
          color: textPrimary,
        ),
        displaySmall: AppFonts.textStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.1,
          color: textPrimary,
        ),
        headlineLarge: AppFonts.textStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: textPrimary,
        ),
        headlineMedium: AppFonts.textStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: textPrimary,
        ),
        headlineSmall: AppFonts.textStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: textPrimary,
        ),
        titleLarge: AppFonts.textStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: textPrimary,
        ),
        titleMedium: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        titleSmall: AppFonts.textStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        bodyLarge: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        bodyMedium: AppFonts.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: textPrimary,
        ),
        bodySmall: AppFonts.textStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: textSecondary,
        ),
        labelLarge: AppFonts.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textPrimary,
        ),
        labelMedium: AppFonts.textStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: textPrimary,
        ),
        labelSmall: AppFonts.textStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: AppFonts.textStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: colorTheme.cardBackground,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorTheme.isDark
            ? colorTheme.cardBackground
            : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorTheme.isDark ? borderColorValue : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorTheme.errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorTheme.errorColor, width: 2),
        ),
        errorStyle: TextStyle(color: colorTheme.errorColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorTheme.cardBackground,
        selectedItemColor: colorTheme.primaryColor,
        unselectedItemColor: colorTheme.isDark
            ? Colors.grey[400]
            : Colors.grey[600],
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppFonts.textStyle(
          fontWeight: FontWeight.w600,
          color: colorTheme.primaryColor,
        ),
        unselectedLabelStyle: AppFonts.textStyle(
          fontWeight: FontWeight.normal,
          color: colorTheme.isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorTheme.cardBackground,
        elevation: 8,
        indicatorColor: colorTheme.primaryColor.withValues(
          alpha: colorTheme.isDark ? 0.2 : 0.1,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppFonts.textStyle(
              fontWeight: FontWeight.w600,
              color: colorTheme.primaryColor,
            );
          }
          return AppFonts.textStyle(
            fontWeight: FontWeight.normal,
            color: colorTheme.isDark ? Colors.grey[400] : Colors.grey[600],
          );
        }),
      ),
    );
  }
}
