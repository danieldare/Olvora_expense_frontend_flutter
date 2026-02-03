import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/utils/auth_error_handler.dart';
import '../../domain/entities/feature_request_entity.dart';
import '../models/feature_request_model.dart';
import '../dto/create_feature_request_dto.dart';

/// Repository interface for feature request operations
abstract class FeatureRequestRepository {
  /// Submit a new feature request
  Future<FeatureRequestEntity> createFeatureRequest(
    CreateFeatureRequestDto dto,
  );

  /// Get all feature requests for the current user
  Future<List<FeatureRequestEntity>> getAllFeatureRequests();
}

/// Implementation of FeatureRequestRepository
class FeatureRequestRepositoryImpl implements FeatureRequestRepository {
  final ApiServiceV2 _apiService;

  FeatureRequestRepositoryImpl(this._apiService);

  @override
  Future<FeatureRequestEntity> createFeatureRequest(
    CreateFeatureRequestDto dto,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/feature-requests',
        data: dto.toJson(),
      );

      // Handle TransformInterceptor response wrapping
      dynamic actualData = response.data;
      if (response.data is Map && response.data['data'] != null) {
        actualData = response.data['data'];
      }

      if (actualData is Map<String, dynamic>) {
        return FeatureRequestModel.fromJson(actualData).toEntity();
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid request';
        throw Exception(message);
      } else if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      } else {
        throw Exception(
          'Failed to submit feature request: ${e.message ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to submit feature request: $e');
    }
  }

  @override
  Future<List<FeatureRequestEntity>> getAllFeatureRequests() async {
    try {
      final response = await _apiService.dio.get('/feature-requests');

      // Handle TransformInterceptor response wrapping
      dynamic actualData = response.data;
      if (response.data is Map && response.data['data'] != null) {
        actualData = response.data['data'];
      }

      if (actualData is List) {
        return actualData
            .map(
              (json) => FeatureRequestModel.fromJson(
                json as Map<String, dynamic>,
              ).toEntity(),
            )
            .toList();
      } else {
        throw Exception('Invalid response format: expected List');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please sign in again.');
      } else {
        throw Exception(
          'Failed to fetch feature requests: ${e.message ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch feature requests: $e');
    }
  }
}
