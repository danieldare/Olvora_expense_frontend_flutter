import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/language.dart';
import '../services/language_service.dart';

/// Language service provider
final languageServiceProvider = Provider<LanguageService>((ref) {
  return LanguageService();
});

/// Selected language provider
final selectedLanguageProvider = FutureProvider<Language>((ref) async {
  final service = ref.watch(languageServiceProvider);
  return await service.getSelectedLanguage();
});

/// Notifier for language changes
class LanguageNotifier extends StateNotifier<AsyncValue<Language>> {
  final LanguageService _service;

  LanguageNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final language = await _service.getSelectedLanguage();
      state = AsyncValue.data(language);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setLanguage(Language language) async {
    await _service.setSelectedLanguage(language);
    state = AsyncValue.data(language);
  }
}

/// Language notifier provider
final languageNotifierProvider =
    StateNotifierProvider<LanguageNotifier, AsyncValue<Language>>((ref) {
  final service = ref.watch(languageServiceProvider);
  return LanguageNotifier(service);
});
