import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

/// Service for managing language preferences
class LanguageService {
  static const String _languageKey = 'selected_language';

  /// Get the currently selected language
  Future<Language> getSelectedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      if (languageCode != null) {
        final language = Language.findByCode(languageCode);
        if (language != null) {
          return language;
        }
      }
    } catch (e) {
      // If there's an error, return default language
    }
    return Language.defaultLanguage;
  }

  /// Set the selected language
  Future<void> setSelectedLanguage(Language language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clear the selected language (reset to default)
  Future<void> clearLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
