import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../data/repositories/feature_request_repository.dart';
import '../../data/dto/create_feature_request_dto.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/state/auth_state.dart';

/// Feature request repository provider
final featureRequestRepositoryProvider = Provider<FeatureRequestRepository>((
  ref,
) {
  final apiService = ref.watch(apiServiceV2Provider);
  return FeatureRequestRepositoryImpl(apiService);
});

/// Provider for creating a feature request
final createFeatureRequestProvider =
    FutureProvider.family<dynamic, CreateFeatureRequestDto>((ref, dto) async {
      final repository = ref.watch(featureRequestRepositoryProvider);
      return await repository.createFeatureRequest(dto);
    });

/// Provider for fetching all feature requests
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final featureRequestsProvider = FutureProvider((ref) async {
  // Watch auth state - if user is not authenticated, return empty list immediately
  final authState = ref.watch(authNotifierProvider);

  if (authState is! AuthStateAuthenticated) {
    return [];
  }

  final repository = ref.watch(featureRequestRepositoryProvider);
  return await repository.getAllFeatureRequests();
});
