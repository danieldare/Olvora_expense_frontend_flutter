import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../domain/entities/user_preferences_entity.dart';

/// Service for managing user preferences via backend API
/// Backend is the single source of truth
class UserPreferencesService {
  final ApiServiceV2 _apiService;

  UserPreferencesService(this._apiService);

  /// Get user preferences from backend
  /// Creates default preferences if they don't exist
  Future<UserPreferencesEntity> getPreferences() async {
    try {
      final response = await _apiService.dio.get('/user/preferences');

      // Handle response wrapper
      dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        data = data['data'];
      }

      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Invalid user preferences response format');
      }

      return UserPreferencesEntity.fromJson(data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch user preferences: ${e.message}');
    }
  }

  /// Update user preferences (partial update)
  Future<UserPreferencesEntity> updatePreferences({
    WeekStartDay? weekStartDay,
    String? timezone,
    String? locale,
    String? currency,
    bool? onboardingCompleted,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (weekStartDay != null) {
        updateData['weekStartDay'] = weekStartDay.value;
      }
      if (timezone != null) {
        updateData['timezone'] = timezone;
      }
      if (locale != null) {
        updateData['locale'] = locale;
      }
      if (currency != null) {
        updateData['currency'] = currency;
      }
      if (onboardingCompleted != null) {
        updateData['onboardingCompleted'] = onboardingCompleted;
      }

      final response = await _apiService.dio.patch(
        '/user/preferences',
        data: updateData,
      );

      // Handle response wrapper
      dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        data = data['data'];
      }

      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Invalid user preferences response format');
      }

      return UserPreferencesEntity.fromJson(data);
    } on DioException catch (e) {
      throw Exception('Failed to update user preferences: ${e.message}');
    }
  }

  /// Mark onboarding as completed on the server
  Future<void> markOnboardingCompleted() async {
    await updatePreferences(onboardingCompleted: true);
  }

  /// Get week start day as number (for backward compatibility)
  /// @deprecated Use getPreferences().weekStartDay instead
  Future<int> getWeekStartDayNumber() async {
    final preferences = await getPreferences();
    return preferences.weekStartDay.toNumber();
  }
}
