import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/use_cases/delete_account_use_case.dart';
import '../../application/use_cases/forgot_password_use_case.dart';
import '../../application/use_cases/hard_delete_account_use_case.dart';
import '../../application/use_cases/restore_account_use_case.dart';
import '../../application/use_cases/get_cached_session_use_case.dart';
import '../../application/use_cases/login_with_apple_use_case.dart';
import '../../application/use_cases/login_with_email_use_case.dart';
import '../../application/use_cases/login_with_google_use_case.dart';
import '../../application/use_cases/logout_use_case.dart';
import '../../application/use_cases/register_with_email_use_case.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../notifiers/auth_notifier.dart';
import '../state/auth_state.dart';

// =============================================================================
// Infrastructure Providers (Data Layer)
// =============================================================================

/// Dio HTTP client provider
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.backendBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
});

/// Auth remote data source provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(dio: ref.watch(dioProvider));
});

/// Auth local data source provider
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});

// =============================================================================
// Repository Provider
// =============================================================================

/// Auth repository provider
/// CRITICAL: Injects TokenManagerService to sync tokens for API requests
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    tokenManager: ref.watch(tokenManagerServiceProvider),
  );
});

// =============================================================================
// Use Case Providers (Application Layer)
// =============================================================================

/// Login with Google use case provider
final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>((ref) {
  return LoginWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

/// Login with Apple use case provider
final loginWithAppleUseCaseProvider = Provider<LoginWithAppleUseCase>((ref) {
  return LoginWithAppleUseCase(ref.watch(authRepositoryProvider));
});

/// Login with email use case provider
final loginWithEmailUseCaseProvider = Provider<LoginWithEmailUseCase>((ref) {
  return LoginWithEmailUseCase(ref.watch(authRepositoryProvider));
});

/// Register with email use case provider
final registerWithEmailUseCaseProvider = Provider<RegisterWithEmailUseCase>((ref) {
  return RegisterWithEmailUseCase(ref.watch(authRepositoryProvider));
});

/// Forgot password use case provider
final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  return ForgotPasswordUseCase(ref.watch(authRepositoryProvider));
});

/// Get cached session use case provider
final getCachedSessionUseCaseProvider = Provider<GetCachedSessionUseCase>((
  ref,
) {
  return GetCachedSessionUseCase(ref.watch(authRepositoryProvider));
});

/// Logout use case provider
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

/// Delete account use case provider
final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.watch(authRepositoryProvider));
});

/// Restore account use case provider (grace period)
final restoreAccountUseCaseProvider = Provider<RestoreAccountUseCase>((ref) {
  return RestoreAccountUseCase(ref.watch(authRepositoryProvider));
});

/// Hard delete account use case provider (start afresh)
final hardDeleteAccountUseCaseProvider = Provider<HardDeleteAccountUseCase>((ref) {
  return HardDeleteAccountUseCase(ref.watch(authRepositoryProvider));
});

// =============================================================================
// Presentation Layer Providers
// =============================================================================

/// Auth notifier provider - main auth state management
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(
    loginWithGoogleUseCase: ref.watch(loginWithGoogleUseCaseProvider),
    loginWithAppleUseCase: ref.watch(loginWithAppleUseCaseProvider),
    loginWithEmailUseCase: ref.watch(loginWithEmailUseCaseProvider),
    registerWithEmailUseCase: ref.watch(registerWithEmailUseCaseProvider),
    forgotPasswordUseCase: ref.watch(forgotPasswordUseCaseProvider),
    getCachedSessionUseCase: ref.watch(getCachedSessionUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    tokenManager: ref.watch(tokenManagerServiceProvider),
    apiService: ref.watch(apiServiceV2Provider),
  );
});

// =============================================================================
// Convenience Providers (for UI consumption)
// =============================================================================

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthStateAuthenticated;
});

/// Provider to get current session (if authenticated)
final currentSessionProvider = Provider<AuthSession?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthStateAuthenticated) {
    return authState.session;
  }
  return null;
});

/// Provider to get current user email (if authenticated)
final currentUserEmailProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.email;
});

/// Provider to get current user ID (if authenticated)
///
/// CRITICAL: Use this in data providers instead of watching authNotifierProvider directly.
/// This provider only emits when the user ID actually changes, preventing unnecessary
/// refetches when auth state updates for other reasons (token refresh, etc.)
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.userId;
});

// =============================================================================
// Auto-Initialization Provider
// =============================================================================

/// Provider that automatically triggers auth check when Firebase is ready
///
/// CRITICAL: This is the ONLY place that calls checkAuthStatus().
/// It watches Firebase initialization and auth state, and automatically
/// triggers checkAuthStatus() when:
/// - Firebase is ready (hasValue == true)
/// - Auth state is Initializing (startup/boot state)
///
/// This ensures auth check happens reactively, not imperatively.
/// Uses a ref-based flag to prevent multiple calls.
///
/// CRITICAL: Only triggers when state is Initializing to ensure
/// SplashScreen is shown first before any checks begin.
final authInitializationProvider = Provider<void>((ref) {
  final firebaseState = ref.watch(firebaseInitializationProvider);
  final authState = ref.watch(authNotifierProvider);

  // Only check auth when:
  // 1. Firebase is ready (hasValue == true)
  // 2. Auth state is Initializing (startup/boot state, not already checked)
  // This ensures SplashScreen is shown first, then checks happen
  if (firebaseState.hasValue &&
      firebaseState.value == true &&
      authState is AuthStateInitializing) {
    // Trigger auth check reactively
    // Use Future.microtask to avoid calling during build
    // This ensures the check happens after the current build cycle
    Future.microtask(() {
      // Double-check state hasn't changed (race condition protection)
      final currentState = ref.read(authNotifierProvider);
      if (currentState is AuthStateInitializing) {
        ref.read(authNotifierProvider.notifier).checkAuthStatus();
      }
    });
  }
});
