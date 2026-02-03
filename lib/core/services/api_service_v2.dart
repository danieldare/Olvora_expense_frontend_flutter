import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_manager_service.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';
import '../utils/jwt_decoder.dart';
import '../navigation/navigator_service.dart';
import '../../features/auth/presentation/screens/account_grace_period_screen.dart';

/// Simple API service with long-lived token management
///
/// CRITICAL PRINCIPLES:
/// - Tokens are long-lived (~30 days)
/// - No refresh logic
/// - No retry logic
/// - If token invalid → logout
/// - Simple and predictable
class ApiServiceV2 {
  final Dio _dio;
  final TokenManagerService _tokenManager;
  final FlutterSecureStorage? _authStorage;

  ApiServiceV2({
    required TokenManagerService tokenManager,
    String? baseUrl,
    FlutterSecureStorage? authStorage,
  }) : _tokenManager = tokenManager,
       _authStorage = authStorage,
       _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl ?? AppConfig.backendBaseUrl,
           headers: {'Content-Type': 'application/json'},
           connectTimeout: AppConfig.connectTimeout,
           receiveTimeout: AppConfig.receiveTimeout,
         ),
       ) {
    // Log the base URL being used for debugging
    final finalBaseUrl = baseUrl ?? AppConfig.backendBaseUrl;
    AppLogger.i(
      'API Service initialized with base URL: $finalBaseUrl',
      tag: 'API',
    );
    _setupInterceptors();
  }

  /// Setup request and error interceptors
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _handleRequest, onError: _handleError),
    );
  }

  /// Handle outgoing requests
  ///
  /// - Block all requests during logout
  /// - Attach authorization header if token exists
  /// - Skip token for public auth endpoints
  Future<void> _handleRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // CRITICAL: Block all API requests during logout
    if (_tokenManager.isLoggingOut) {
      AppLogger.w(
        'API request blocked during logout: ${options.path}',
        tag: 'API',
      );
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Request blocked: logout in progress',
          type: DioExceptionType.cancel,
        ),
      );
    }

    // Skip token for public auth endpoints
    final publicAuthPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/google',
      '/auth/session',
    ];
    if (publicAuthPaths.any((path) => options.path.contains(path))) {
      return handler.next(options);
    }

    // Ensure token is loaded from storage if cache isn't loaded
    // This handles cases where token exists but cache hasn't been populated yet
    if (!_tokenManager.hasToken) {
      await _tokenManager.loadFromStorage();
    }

    // Attach authorization header if token exists
    final token = await _tokenManager.get();
    if (token != null && token.isNotEmpty) {
      // Check if token is expired before making request
      if (JwtDecoder.isExpired(token)) {
        AppLogger.w(
          'Token expired for endpoint: ${options.path} - clearing token',
          tag: 'API',
        );
        
        // Clear expired token
        await _tokenManager.clear();
        
        // Clear auth session
        if (_authStorage != null) {
          try {
            await _authStorage.delete(key: 'auth_session');
            AppLogger.d('Auth session cleared due to expired token', tag: 'API');
          } catch (e) {
            AppLogger.w('Failed to clear auth session: $e', tag: 'API');
          }
        }
        
        // Reject with auth error
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            error: 'Token expired. Please sign in again.',
            response: Response(
              requestOptions: options,
              statusCode: 401,
              statusMessage: 'Unauthorized',
            ),
          ),
        );
      }
      
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      AppLogger.w(
        'No token available for protected endpoint: ${options.path}',
        tag: 'API',
      );
    }

    // Handle multipart requests
    if (options.data is FormData) {
      options.headers.remove('Content-Type');
    }

    return handler.next(options);
  }

  /// Handle API errors
  ///
  /// - 401: Clear tokens and logout
  /// - 403: Check for account lifecycle status
  Future<void> _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Log connection errors for debugging
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      AppLogger.e(
        'Network error: ${error.type} - ${error.message}',
        tag: 'API',
      );
      AppLogger.d(
        'Base URL: ${_dio.options.baseUrl}, Path: ${error.requestOptions.path}',
        tag: 'API',
      );
    }

    // Handle 401 Unauthorized
    if (error.response?.statusCode == 401) {
      await _handleUnauthorizedError(error, handler);
      return;
    }

    // Handle 403 Forbidden (account lifecycle)
    if (error.response?.statusCode == 403) {
      await _handleForbiddenError(error, handler);
      return;
    }

    // Pass through other errors
    return handler.next(error);
  }

  /// Handle 401 Unauthorized errors
  ///
  /// CRITICAL: No refresh, no retry.
  /// Just clear tokens and logout.
  /// This will trigger auth navigation to show login screen.
  Future<void> _handleUnauthorizedError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    AppLogger.w('❌ [API] 401 received – clearing tokens and session', tag: 'API');

    // Clear tokens
    await _tokenManager.clear();

    // Clear auth session
    final authStorage = _authStorage;
    if (authStorage != null) {
      try {
        await authStorage.delete(key: 'auth_session');
        AppLogger.d('Auth session cleared due to 401', tag: 'API');
      } catch (e) {
        AppLogger.w('Failed to clear auth session: $e', tag: 'API');
      }
    }

    // Reject with clear auth error message
    // This error will propagate to the UI layer
    final authError = DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: DioExceptionType.badResponse,
      error: 'Your session has expired. Please sign in again.',
    );

    return handler.reject(authError);
  }

  /// Handle 403 Forbidden errors (account lifecycle)
  Future<void> _handleForbiddenError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final responseData = error.response?.data;
    final accountStatusData = _extractAccountStatusData(responseData);

    if (accountStatusData != null) {
      _navigateToGracePeriodScreen(accountStatusData);

      return handler.reject(
        DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: DioExceptionType.badResponse,
          error: 'Account is scheduled for deletion',
        ),
      );
    }

    // Not account lifecycle related, pass through
    return handler.next(error);
  }

  /// Extract account status data from response
  Map<dynamic, dynamic>? _extractAccountStatusData(dynamic responseData) {
    if (responseData is! Map) return null;

    // Check nested message field (NestJS format)
    final message = responseData['message'];
    if (message is Map) {
      final status = message['status'];
      if (status == 'pending_deletion') {
        return message;
      }
    }

    // Check direct status field
    if (responseData['status'] == 'pending_deletion') {
      return responseData;
    }

    return null;
  }

  /// Last time we navigated to grace period (avoid duplicate navigations)
  static DateTime? _lastGracePeriodNavigationAt;

  /// Navigate to grace period screen (once per burst of 403s)
  void _navigateToGracePeriodScreen(Map<dynamic, dynamic> accountStatusData) {
    try {
      // Only navigate once per 5 seconds so we don't push 7 times when
      // multiple in-flight requests return 403 pending_deletion.
      final now = DateTime.now();
      if (_lastGracePeriodNavigationAt != null &&
          now.difference(_lastGracePeriodNavigationAt!).inSeconds < 5) {
        return;
      }
      _lastGracePeriodNavigationAt = now;

      final daysRemaining =
          accountStatusData['daysRemaining'] as int? ??
          (accountStatusData['daysRemaining'] as num?)?.toInt();

      final deletionStatus = AccountDeletionStatus(
        status: 'pendingDeletion',
        deletedAt: accountStatusData['deletedAt'] != null
            ? DateTime.tryParse(accountStatusData['deletedAt'].toString())
            : null,
        recoveryDeadline: accountStatusData['recoveryDeadline'] != null
            ? DateTime.tryParse(
                accountStatusData['recoveryDeadline'].toString(),
              )
            : null,
        daysRemaining: daysRemaining ?? 0,
        canRestore: accountStatusData['canRestore'] as bool? ?? false,
        canStartAfresh: accountStatusData['canStartAfresh'] as bool? ?? true,
      );

      AppLogger.i(
        'Navigating to grace period screen. Days remaining: $daysRemaining',
        tag: 'API',
      );

      Future.microtask(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = NavigatorService.navigator;
          final context = NavigatorService.context;

          if (navigator != null && context != null) {
            try {
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) =>
                      AccountGracePeriodScreen(deletionStatus: deletionStatus),
                ),
                (route) => false,
              );
              AppLogger.i('Navigated to grace period screen', tag: 'API');
            } catch (navError) {
              AppLogger.e('Navigation error', tag: 'API', error: navError);
            }
          } else {
            // Retry after delay (once)
            Future.delayed(const Duration(milliseconds: 500), () {
              final retryNavigator = NavigatorService.navigator;
              final retryContext = NavigatorService.context;
              if (retryNavigator != null && retryContext != null) {
                retryNavigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => AccountGracePeriodScreen(
                      deletionStatus: deletionStatus,
                    ),
                  ),
                  (route) => false,
                );
              }
            });
          }
        });
      });
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to navigate to grace period screen',
        tag: 'API',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Public API

  /// Get Dio instance
  Dio get dio => _dio;
}
