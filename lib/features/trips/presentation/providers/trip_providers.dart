import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/trip_service.dart';
import '../../domain/entities/trip_entity.dart';

/// Provider for TripService
final tripServiceProvider = Provider<TripService>((ref) {
  final apiService = ref.watch(apiServiceV2Provider);
  return TripService(apiService);
});

/// Provider for active trip (single trip or null - only one active trip allowed)
final activeTripProvider = FutureProvider<TripEntity?>((ref) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only fetch when user is authenticated
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return null;
  }

  final service = ref.watch(tripServiceProvider);
  return service.getActiveTrip();
});

/// Provider for active trips (deprecated - use activeTripProvider instead)
@Deprecated('Use activeTripProvider instead. Only one active trip is allowed.')
final activeTripsProvider = FutureProvider<List<TripEntity>>((ref) async {
  final service = ref.watch(tripServiceProvider);
  return service.getActiveTrips();
});

/// Provider for all trips
final tripsProvider = FutureProvider.family<List<TripEntity>, TripStatus?>((ref, status) async {
  final service = ref.watch(tripServiceProvider);
  return service.getTrips(status: status);
});

/// Provider for a specific trip
final tripProvider = FutureProvider.family<TripEntity, String>((ref, tripId) async {
  final service = ref.watch(tripServiceProvider);
  return service.getTrip(tripId);
});

/// StateNotifier for managing trip operations
final tripNotifierProvider =
    StateNotifierProvider<TripNotifier, AsyncValue<List<TripEntity>>>((ref) {
  final service = ref.watch(tripServiceProvider);
  return TripNotifier(service, ref);
});

class TripNotifier extends StateNotifier<AsyncValue<List<TripEntity>>> {
  final TripService _service;
  final Ref _ref;

  TripNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final activeTrip = await _service.getActiveTrip();
      state = AsyncValue.data(activeTrip != null ? [activeTrip] : []);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createTrip({
    required String name,
    String? currency,
    TripVisibility? visibility,
  }) async {
    try {
      await _service.createTrip(
        name: name,
        currency: currency,
        visibility: visibility,
      );
      // Refresh trips list
      await _loadTrips();
      // Invalidate active trip provider
      _ref.invalidate(activeTripProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadTrips();
    _ref.invalidate(activeTripProvider);
  }
}
