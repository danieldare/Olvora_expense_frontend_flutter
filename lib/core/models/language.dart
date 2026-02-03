/// Language model for app localization
class Language {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  /// Get all supported languages
  static List<Language> get supportedLanguages => [
    const Language(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    const Language(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    const Language(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    const Language(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
    const Language(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
    ),
    const Language(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
    const Language(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
    ),
    const Language(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
    const Language(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
    ),
    const Language(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
    ),
  ];

  /// Find language by code
  static Language? findByCode(String code) {
    try {
      return supportedLanguages.firstWhere(
        (lang) => lang.code == code.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Default language (English)
  static Language get defaultLanguage => supportedLanguages.first;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
