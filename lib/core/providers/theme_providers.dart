import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_service.dart';
import '../models/color_theme.dart';

/// Provider for theme service
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

/// Provider for theme mode state
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeModeNotifier(themeService);
});

/// Provider for color theme state
final colorThemeProvider =
    StateNotifierProvider<ColorThemeNotifier, ColorTheme>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ColorThemeNotifier(themeService);
});

/// Notifier for managing theme mode
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;

  ThemeModeNotifier(this._themeService) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load theme mode from storage
  Future<void> _loadThemeMode() async {
    final savedMode = await _themeService.getThemeMode();
    state = savedMode;
  }

  /// Set theme mode and persist it
  Future<void> setThemeMode(ThemeMode mode) async {
    await _themeService.setThemeMode(mode);
    state = mode;
  }

  /// Toggle between light and dark (ignoring system)
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Check if dark mode is enabled (considering system preference)
  bool isDarkMode(BuildContext context) {
    switch (state) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
}

/// Notifier for managing color theme
class ColorThemeNotifier extends StateNotifier<ColorTheme> {
  final ThemeService _themeService;

  ColorThemeNotifier(this._themeService) : super(ColorTheme.defaultTheme) {
    _loadColorTheme();
  }

  /// Load color theme from storage
  Future<void> _loadColorTheme() async {
    final savedTheme = await _themeService.getColorTheme();
    state = savedTheme;
  }

  /// Set color theme and persist it
  Future<void> setColorTheme(ColorTheme theme) async {
    if (kDebugMode) {
      debugPrint('🎨 Setting color theme: ${theme.name} (${theme.id})');
      debugPrint('🎨 Primary Color: ${theme.primaryColor}');
    }
    await _themeService.setColorTheme(theme);
    state = theme;
    if (kDebugMode) {
      debugPrint('🎨 Color theme state updated to: ${state.name}');
    }
  }
}
