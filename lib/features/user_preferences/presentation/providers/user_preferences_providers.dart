import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../data/services/user_preferences_service.dart';
import '../../domain/entities/user_preferences_entity.dart';

/// Provider for UserPreferencesService
final userPreferencesServiceProvider = Provider<UserPreferencesService>((ref) {
  final apiService = ref.watch(apiServiceV2Provider);
  return UserPreferencesService(apiService);
});

/// Provider for user preferences (fetches from backend)
final userPreferencesProvider =
    FutureProvider<UserPreferencesEntity>((ref) async {
  final service = ref.watch(userPreferencesServiceProvider);
  return await service.getPreferences();
});

/// StateNotifier for managing user preferences
final userPreferencesNotifierProvider =
    StateNotifierProvider<UserPreferencesNotifier, AsyncValue<UserPreferencesEntity>>((ref) {
  final service = ref.watch(userPreferencesServiceProvider);
  return UserPreferencesNotifier(service);
});

class UserPreferencesNotifier
    extends StateNotifier<AsyncValue<UserPreferencesEntity>> {
  final UserPreferencesService _service;

  UserPreferencesNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _service.getPreferences();
      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePreferences({
    WeekStartDay? weekStartDay,
    String? timezone,
    String? locale,
    String? currency,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _service.updatePreferences(
        weekStartDay: weekStartDay,
        timezone: timezone,
        locale: locale,
        currency: currency,
      );
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh preferences from backend
  Future<void> refresh() async {
    await _loadPreferences();
  }
}
