import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../data/services/weekly_summary_service.dart';
import '../../domain/entities/weekly_summary_entity.dart';
import '../../domain/entities/detailed_weekly_summary_entity.dart';

/// Weekly summary service provider
final weeklySummaryServiceProvider = Provider<WeeklySummaryService>((ref) {
  final apiService = ref.watch(apiServiceV2Provider);
  return WeeklySummaryService(apiService);
});

/// Current week's summary provider
final currentWeekSummaryProvider = FutureProvider<WeeklySummaryEntity>((
  ref,
) async {
  final service = ref.watch(weeklySummaryServiceProvider);
  return service.getCurrentWeekSummary();
});

/// Provider for generating weekly summary
final generateWeeklySummaryProvider =
    FutureProvider.family<WeeklySummaryEntity, void>((ref, _) async {
      final service = ref.watch(weeklySummaryServiceProvider);
      return service.generateSummary();
    });

/// Push notification message provider
final weeklySummaryPushMessageProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(weeklySummaryServiceProvider);
  return service.getPushNotificationMessage();
});

/// Detailed weekly summary provider (with all analytics)
final detailedWeeklySummaryProvider =
    FutureProvider<DetailedWeeklySummaryEntity>((ref) async {
  final service = ref.watch(weeklySummaryServiceProvider);
  return service.getDetailedWeeklySummary();
});

/// Detailed weekly summary for specific week
final detailedWeeklySummaryForWeekProvider =
    FutureProvider.family<DetailedWeeklySummaryEntity, DateTime>((ref, weekStartDate) async {
  final service = ref.watch(weeklySummaryServiceProvider);
  return service.getDetailedWeeklySummary(weekStartDate: weekStartDate);
});
