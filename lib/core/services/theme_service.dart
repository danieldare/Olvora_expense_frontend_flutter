import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/color_theme.dart';

/// Service for managing theme preferences
class ThemeService {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorThemeIdKey = 'color_theme_id';

  /// Get the saved theme mode
  Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);

      if (themeModeString != null) {
        switch (themeModeString) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          case 'system':
            return ThemeMode.system;
        }
      }
    } catch (e) {
      // If there's an error, return system default
    }
    return ThemeMode.system;
  }

  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeString;
      switch (mode) {
        case ThemeMode.light:
          modeString = 'light';
          break;
        case ThemeMode.dark:
          modeString = 'dark';
          break;
        case ThemeMode.system:
          modeString = 'system';
          break;
      }
      await prefs.setString(_themeModeKey, modeString);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clear the saved theme mode (reset to system)
  Future<void> clearThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeModeKey);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get the saved color theme
  Future<ColorTheme> getColorTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeId = prefs.getString(_colorThemeIdKey);

      if (themeId != null) {
        final theme = ColorTheme.findById(themeId);
        if (theme != null) {
          return theme;
        }
      }
    } catch (e) {
      // If there's an error, return default theme
    }
    return ColorTheme.defaultTheme;
  }

  /// Set the color theme
  Future<void> setColorTheme(ColorTheme theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_colorThemeIdKey, theme.id);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clear the saved color theme (reset to default)
  Future<void> clearColorTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_colorThemeIdKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
