import 'package:dio/dio.dart';
import 'secure_storage_service.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';

class ApiService {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  ApiService({required SecureStorageService secureStorage, String? baseUrl})
    : _secureStorage = secureStorage,
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? AppConfig.backendBaseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
        ),
      ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip adding token for auth endpoints (except refresh which needs no token)
          if (!options.path.contains('/auth')) {
            final token = await _secureStorage.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              // Don't log warning for every request - only log once per session
              // The request will fail with 401 and trigger refresh logic
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - attempt token refresh
          if (error.response?.statusCode == 401) {
            AppLogger.w('401 Unauthorized error for ${error.requestOptions.path}', tag: 'API');

            // Don't retry refresh endpoint itself
            if (error.requestOptions.path.contains('/auth/refresh')) {
              AppLogger.w('Refresh endpoint failed, clearing tokens', tag: 'API');
              await _secureStorage.clearTokens();
              return handler.next(error);
            }

            // If already refreshing, queue this request
            if (_isRefreshing) {
              AppLogger.d('Token refresh already in progress, queueing request', tag: 'API');
              _pendingRequests.add(
                _PendingRequest(
                  options: error.requestOptions,
                  handler: handler,
                ),
              );
              return;
            }

            // Attempt to refresh token
            _isRefreshing = true;
            try {
              final refreshToken = await _secureStorage.getRefreshToken();
              if (refreshToken != null && refreshToken.isNotEmpty) {
                // Try to refresh the token (without auth header)
                final refreshDio = Dio(_dio.options);
                final refreshResponse = await refreshDio.post(
                  AppConfig.authRefreshEndpoint,
                  data: {'refresh_token': refreshToken},
                );

                if (refreshResponse.data['access_token'] != null) {
                  // Store new tokens
                  await _secureStorage.setToken(
                    refreshResponse.data['access_token'],
                  );
                  if (refreshResponse.data['refresh_token'] != null) {
                    await _secureStorage.setRefreshToken(
                      refreshResponse.data['refresh_token'],
                    );
                  }

                  // Get the new token
                  final newToken = refreshResponse.data['access_token'];

                  // Retry all pending requests with new token
                  for (final pending in _pendingRequests) {
                    pending.options.headers['Authorization'] =
                        'Bearer $newToken';
                    try {
                      final response = await _dio.fetch(pending.options);
                      pending.handler.resolve(response);
                    } catch (e) {
                      pending.handler.reject(e as DioException);
                    }
                  }
                  _pendingRequests.clear();

                  // Retry original request with new token
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  try {
                    final response = await _dio.fetch(error.requestOptions);
                    _isRefreshing = false;
                    return handler.resolve(response);
                  } catch (e) {
                    _isRefreshing = false;
                    return handler.reject(e as DioException);
                  }
                } else {
                  throw Exception('Refresh response missing access_token');
                }
              } else {
                throw Exception('No refresh token available');
              }
            } catch (refreshError) {
              // Refresh failed - clear tokens and reject
              await _secureStorage.clearTokens();
              _isRefreshing = false;

              // Reject all pending requests with a clear error
              final authError = DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: DioExceptionType.badResponse,
                error: 'Authentication required. Please sign in again.',
              );

              for (final pending in _pendingRequests) {
                pending.handler.reject(authError);
              }
              _pendingRequests.clear();

              // Reject the original error with clear message
              return handler.reject(authError);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _PendingRequest({required this.options, required this.handler});
}
