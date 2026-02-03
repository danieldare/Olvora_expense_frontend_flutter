import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';

import '../../application/use_cases/forgot_password_use_case.dart';
import '../../application/use_cases/get_cached_session_use_case.dart';
import '../../application/use_cases/login_with_apple_use_case.dart';
import '../../application/use_cases/login_with_email_use_case.dart';
import '../../application/use_cases/login_with_google_use_case.dart';
import '../../application/use_cases/logout_use_case.dart';
import '../../application/use_cases/register_with_email_use_case.dart';
import '../../domain/core/either.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../data/mappers/auth_failure_mapper.dart';
import '../mappers/auth_failure_message_mapper.dart';
import '../state/auth_state.dart';
import '../../../../core/services/token_manager_service.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/jwt_decoder.dart';

/// Helper function to get Firebase ID token
///
/// CRITICAL: This must be called after Firebase sign-in completes.
Future<String> getIdTokenOnce() async {
  final user = firebase.FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No Firebase user - authentication required');
  }

  // Force refresh to ensure we get a fresh token
  // This is important after sign-in to avoid cached/invalid tokens
  final token = await user.getIdToken(true); // true = force refresh
  if (token == null || token.isEmpty) {
    throw Exception('Unable to retrieve auth token');
  }

  return token;
}

/// Authentication state notifier - Presentation Layer
///
/// State Machine:
/// - Initializing → (Unauthenticated | EstablishingSession → Authenticated)
/// - Unauthenticated → Authenticating → EstablishingSession → Authenticated
///
/// CRITICAL: User is only marked authenticated when token is available.
/// This prevents race conditions where API calls happen before token is ready.
///
/// CRITICAL: Startup phase is tracked to ensure SplashScreen is shown during
/// app initialization, not during user-initiated login.
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final LoginWithAppleUseCase _loginWithAppleUseCase;
  final LoginWithEmailUseCase _loginWithEmailUseCase;
  final RegisterWithEmailUseCase _registerWithEmailUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final GetCachedSessionUseCase _getCachedSessionUseCase;
  final LogoutUseCase _logoutUseCase;
  final TokenManagerService? _tokenManager;
  final ApiServiceV2? _apiService;

  /// Flag to track if we're in startup phase (app initialization)
  /// This ensures SplashScreen is shown during startup, not during user login
  bool _isStartupPhase = true;

  /// Getter to check if we're in startup phase
  /// Used by navigation provider to determine if SplashScreen should be shown
  bool get isStartupPhase => _isStartupPhase;

  AuthNotifier({
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required LoginWithAppleUseCase loginWithAppleUseCase,
    required LoginWithEmailUseCase loginWithEmailUseCase,
    required RegisterWithEmailUseCase registerWithEmailUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required GetCachedSessionUseCase getCachedSessionUseCase,
    required LogoutUseCase logoutUseCase,
    TokenManagerService? tokenManager,
    ApiServiceV2? apiService,
  }) : _loginWithGoogleUseCase = loginWithGoogleUseCase,
       _loginWithAppleUseCase = loginWithAppleUseCase,
       _loginWithEmailUseCase = loginWithEmailUseCase,
       _registerWithEmailUseCase = registerWithEmailUseCase,
       _forgotPasswordUseCase = forgotPasswordUseCase,
       _getCachedSessionUseCase = getCachedSessionUseCase,
       _logoutUseCase = logoutUseCase,
       _tokenManager = tokenManager,
       _apiService = apiService,
       super(const AuthStateInitializing()) {
    if (kDebugMode) {
      debugPrint('🔐 [AuthNotifier] Initialized in Initializing state');
    }
  }

  /// Wait for Firebase Auth state to restore
  ///
  /// Firebase Auth state restoration is asynchronous. This method waits for
  /// the auth state to be restored, with a timeout to prevent indefinite waiting.
  Future<firebase.User?> _waitForFirebaseAuthState({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final auth = firebase.FirebaseAuth.instance;
    
    // Check if user is already available
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      return currentUser;
    }

    // Wait for auth state changes with timeout
    try {
      final completer = Completer<firebase.User?>();
      late StreamSubscription<firebase.User?> subscription;
      
      subscription = auth.authStateChanges().listen((user) {
        if (!completer.isCompleted) {
          completer.complete(user);
        }
      });

      // Also check periodically in case authStateChanges doesn't fire
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        final user = auth.currentUser;
        if (user != null && !completer.isCompleted) {
          timer.cancel();
          subscription.cancel();
          completer.complete(user);
        }
      });

      final result = await completer.future.timeout(
        timeout,
        onTimeout: () {
          subscription.cancel();
          return auth.currentUser; // Return whatever we have after timeout
        },
      );

      await subscription.cancel();
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Auth] Error waiting for Firebase Auth state: $e');
      }
      return auth.currentUser; // Return whatever we have
    }
  }

  /// Retry a network operation with exponential backoff
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        // Don't retry on non-network errors
        if (e is! DioException) {
          rethrow;
        }

        final isNetworkError = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.error is SocketException;

        // Don't retry on auth errors (401, 403)
        final isAuthError = e.response?.statusCode == 401 ||
            e.response?.statusCode == 403;

        if (!isNetworkError || isAuthError || attempt >= maxRetries) {
          rethrow;
        }

        if (kDebugMode) {
          debugPrint(
            '🔄 [Auth] Retry attempt $attempt/$maxRetries after ${delay.inMilliseconds}ms',
          );
        }

        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 2).clamp(500, 5000));
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// Check for existing cached session on app startup
  ///
  /// CRITICAL: This follows a robust flow that handles Firebase Auth state
  /// restoration, token validation, and network retries.
  ///
  /// Flow:
  /// 1. Start in Initializing state (SplashScreen shown)
  /// 2. Load token from storage
  /// 3. Check token expiration
  /// 4. Wait for Firebase Auth state to restore
  /// 5. Try to restore session from cache first (fast path)
  /// 6. If cache fails, establish session via /auth/session (with retries)
  /// 7. If all fails → Unauthenticated
  ///
  /// This ensures SplashScreen is always shown first, preventing flicker.
  Future<void> checkAuthStatus() async {
    // CRITICAL: Ensure we're in Initializing state before starting checks
    // This guarantees SplashScreen is shown during startup
    if (state is! AuthStateInitializing) {
      if (kDebugMode) {
        debugPrint(
          '🔐 [Auth] checkAuthStatus() called but not in Initializing state - ignoring',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('🔐 [Auth] Checking auth status from Initializing state...');
    }

    // Load token from storage into cache
    final tokenManager = _tokenManager;
    if (tokenManager != null) {
      await tokenManager.loadFromStorage();
    }

    // Check if token exists
    if (tokenManager == null || !tokenManager.hasToken) {
      if (kDebugMode) {
        debugPrint(
          '🔐 [Auth] No token found - transitioning to Unauthenticated',
        );
      }
      _isStartupPhase = false; // Startup phase complete
      state = const AuthStateUnauthenticated();
      return;
    }

    // Get token and check expiration
    final token = await tokenManager.get();
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint('🔐 [Auth] Token is empty - transitioning to Unauthenticated');
      }
      _isStartupPhase = false;
      state = const AuthStateUnauthenticated();
      return;
    }

    // Check if token is expired
    if (JwtDecoder.isExpired(token)) {
      if (kDebugMode) {
        debugPrint('🔐 [Auth] Token is expired - clearing and transitioning to Unauthenticated');
      }
      await tokenManager.clear();
      _isStartupPhase = false;
      state = const AuthStateUnauthenticated();
      return;
    }

    // Token exists and is valid - try fast path: restore from cache
    if (kDebugMode) {
      debugPrint('🔐 [Auth] Token found and valid - attempting session restoration...');
    }

    // Stay in startup phase during EstablishingSession if this is startup
    state = const AuthStateEstablishingSession();

    try {
      // STRICT MODE: Backend validation is REQUIRED for authentication.
      // We don't use cached sessions as fallback - backend must confirm the session is valid.
      // This prevents users from seeing home screen when backend is unreachable.

      // Wait for Firebase Auth state to restore
      if (kDebugMode) {
        debugPrint('🔐 [Auth] Waiting for Firebase Auth state...');
      }

      final firebaseUser = await _waitForFirebaseAuthState();

      if (firebaseUser == null) {
        // No Firebase user - clear token and go to unauthenticated
        if (kDebugMode) {
          debugPrint('🔐 [Auth] No Firebase user found - clearing token');
        }
        await tokenManager.clear();
        _isStartupPhase = false;
        state = const AuthStateUnauthenticated();
        return;
      }

      // Firebase user exists - MUST establish backend session
      // This is the ONLY way to reach AuthStateAuthenticated on startup
      if (kDebugMode) {
        debugPrint('🔑 [Auth] Firebase user found - establishing backend session...');
      }

      await _refreshBackendSession(firebaseUser);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Auth] Failed to establish session (startup): $e');
        if (e is DioException) {
          debugPrint('   Dio Error: ${e.type} - ${e.message}');
          debugPrint('   Dio Response: ${e.response?.statusCode} - ${e.response?.data}');
          debugPrint('   Dio Request: ${e.requestOptions.method} ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        }
      }

      // STRICT MODE: Any failure during session establishment → show error
      // Don't silently fall back to cached session - user needs to know what's wrong

      final isNetworkError = e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.error is SocketException);

      _isStartupPhase = false;

      if (isNetworkError) {
        // Network error - show specific error so user knows to check connection
        if (kDebugMode) {
          debugPrint('🔐 [Auth] Network error - showing connection error to user');
        }
        state = const AuthStateError(
          failure: NetworkFailure(),
          message: 'Unable to connect. Please check your internet connection and try again.',
        );
      } else {
        // Other errors (401, 403, server error, etc.) - clear token and go to auth
        if (kDebugMode) {
          debugPrint('🔐 [Auth] Backend validation failed - clearing token');
        }
        await tokenManager.clear();
        state = const AuthStateUnauthenticated();
      }
    }
  }

  /// Set authenticated state after session establishment.
  /// If account is pending_deletion, set AuthStateGracePeriod so we show grace period instead of HOME.
  Future<void> _setAuthenticatedState(AuthSession session) async {
    final apiService = _apiService;
    if (apiService == null) {
      _isStartupPhase = false;
      state = AuthStateAuthenticated(session);
      return;
    }
    try {
      final response = await apiService.dio.post<Map<String, dynamic>>(
        '/auth/account/deletion-status',
      );
      final data = response.data;
      final body = data is Map<String, dynamic>
          ? ((data['data'] ?? data) as Map<String, dynamic>?)
          : null;
      final status = body?['status'] as String?;
      if (status == 'pending_deletion' && body != null) {
        final daysRemaining =
            (body['daysRemaining'] as num?)?.toInt() ??
            (body['recoveryDeadline'] != null ? 30 : 0);
        final canRestore = body['canRestore'] as bool? ?? (daysRemaining > 0);
        final canStartAfresh = body['canStartAfresh'] as bool? ?? true;
        DateTime? recoveryDeadline;
        if (body['recoveryDeadline'] != null) {
          recoveryDeadline = DateTime.tryParse(body['recoveryDeadline'].toString());
        }
        DateTime? deletedAt;
        if (body['deletedAt'] != null) {
          deletedAt = DateTime.tryParse(body['deletedAt'].toString());
        }
        if (kDebugMode) {
          debugPrint('🔐 [Auth] Account pending deletion - showing grace period (days: $daysRemaining)');
        }
        _isStartupPhase = false;
        state = AuthStateGracePeriod(
          session: session,
          daysRemaining: daysRemaining,
          canRestore: canRestore,
          canStartAfresh: canStartAfresh,
          recoveryDeadline: recoveryDeadline,
          deletedAt: deletedAt,
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔐 [Auth] Deletion status check failed (non-fatal): $e');
      }
    }
    _isStartupPhase = false;
    state = AuthStateAuthenticated(session);
  }

  /// Refresh backend session by calling /auth/session
  ///
  /// This is used both during app startup and when refreshing tokens.
  /// Includes retry logic for network errors.
  Future<void> _refreshBackendSession(firebase.User firebaseUser) async {
    final tokenManager = _tokenManager;
    if (tokenManager == null) {
      throw Exception('TokenManager not available');
    }

    final apiService = _apiService;
    if (apiService == null) {
      throw Exception('ApiService not available - cannot establish backend session');
    }

    // Get fresh Firebase ID token
    if (kDebugMode) {
      debugPrint('🔑 [Auth] Fetching Firebase ID token...');
    }
    final firebaseToken = await firebaseUser.getIdToken(true);

    if (kDebugMode) {
      debugPrint('📡 [Auth] Establishing backend session with retry logic...');
    }

    // Call /auth/session with retry logic (Dio baseUrl is already set)
    final response = await _retryWithBackoff(() async {
      return await apiService.dio.post<Map<String, dynamic>>(
        '/auth/session',
        data: {'idToken': firebaseToken},
      );
    });

    // Extract backend JWT from response
    final responseData = response.data;
    if (responseData == null || !responseData.containsKey('data')) {
      throw Exception('Backend did not return data in expected format');
    }

    final data = responseData['data'] as Map<String, dynamic>?;
    if (data == null || !data.containsKey('accessToken')) {
      throw Exception('Backend did not return accessToken');
    }

    final backendJwt = data['accessToken'] as String;
    if (backendJwt.isEmpty) {
      throw Exception('Backend returned empty accessToken');
    }

    if (kDebugMode) {
      debugPrint('💾 [Auth] Backend JWT received - saving...');
    }

    // Store backend JWT
    await tokenManager.save(backendJwt);

    // Get session from cache (should exist if token was valid)
    final result = await _getCachedSessionUseCase().timeout(
      const Duration(seconds: 10), // Increased timeout
      onTimeout: () {
        if (kDebugMode) {
          debugPrint('⏱️ [Auth] Session cache read timeout after /auth/session');
        }
        return const Right(null);
      },
    );

    await result.fold(
      (failure) async {
        if (kDebugMode) {
          debugPrint(
            '🔐 [Auth] Failed to get session after /auth/session: $failure',
          );
        }
        // /auth/session succeeded but can't read session - this is unusual
        // Don't clear token - might be a storage issue
        // Create a minimal session from the token we have
        final payload = JwtDecoder.decodePayload(backendJwt);
        if (payload != null) {
          final email = payload['email'] as String? ?? '';
          final userId = payload['sub'] as String? ?? '';
          if (email.isNotEmpty && userId.isNotEmpty) {
            final session = AuthSession(
              userId: userId,
              email: email,
              accessToken: backendJwt,
            );
            await _setAuthenticatedState(session);
            return;
          }
        }
        // Can't create session - go to unauthenticated
        _isStartupPhase = false;
        state = const AuthStateUnauthenticated();
      },
      (session) async {
        if (session != null) {
          if (kDebugMode) {
            debugPrint('✅ [Auth] Session established with backend JWT');
          }
          await _setAuthenticatedState(session);
        } else {
          // /auth/session succeeded but no cached session
          // Create session from token
          final payload = JwtDecoder.decodePayload(backendJwt);
          if (payload != null) {
            final email = payload['email'] as String? ?? '';
            final userId = payload['sub'] as String? ?? '';
            if (email.isNotEmpty && userId.isNotEmpty) {
              final newSession = AuthSession(
                userId: userId,
                email: email,
                accessToken: backendJwt,
              );
              await _setAuthenticatedState(newSession);
              return;
            }
          }
          // Can't create session - clear token
          if (kDebugMode) {
            debugPrint('🔐 [Auth] No session after /auth/session - clearing token');
          }
          await tokenManager.clear();
          _isStartupPhase = false;
          state = const AuthStateUnauthenticated();
        }
      },
    );
  }

  /// Login with Google - Three-Phase Flow
  ///
  /// Phase 1: Authenticating - Firebase sign-in in progress
  /// Phase 2: EstablishingSession - Session already established by use case
  /// Phase 3: Authenticated - Token is available, user is fully authenticated
  Future<void> loginWithGoogle() async {
    if (kDebugMode) {
      debugPrint('🔐 [Auth] Authenticating...');
    }

    // CRITICAL: Reset logout state immediately to allow login flow
    // This ensures /auth/session requests are not blocked
    final tokenManager = _tokenManager;
    tokenManager?.resetLogoutState();

    // User-initiated login - not startup phase
    _isStartupPhase = false;

    // PHASE 1: Authenticating
    state = const AuthStateAuthenticating();

    try {
      final result = await _loginWithGoogleUseCase();

      await result.fold(
        (failure) async => _handleFailure(failure),
        (session) async {
          if (kDebugMode) {
            debugPrint('🔐 [Auth] Google sign-in successful: ${session.email}');
          }

          // Use session.accessToken directly (single source of truth). Ensure TokenManager has it for API calls.
          if (session.accessToken.isEmpty) {
            if (kDebugMode) {
              debugPrint('⚠️ [Auth] Session has no access token');
            }
            _handleFailure(const UnknownAuthFailure());
            return;
          }
          try {
            await tokenManager?.save(session.accessToken);
          } catch (_) {
            // Non-fatal: session is valid, token sync is best-effort for API interceptor
          }

          if (kDebugMode) {
            debugPrint('✅ [Auth] Session established - checking deletion status');
          }
          await _setAuthenticatedState(session);
        },
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('🔐 [Auth] Google sign-in error (caught): $e');
        debugPrint('Stack: $stack');
      }
      _handleFailure(const UnknownAuthFailure());
    }
  }

  /// Login with Apple
  Future<void> loginWithApple() async {
    if (kDebugMode) {
      debugPrint('🔐 [Auth] Starting Apple login...');
    }

    // CRITICAL: Reset logout state immediately to allow login flow
    // This ensures /auth/session requests are not blocked
    final tokenManager = _tokenManager;
    tokenManager?.resetLogoutState();

    // User-initiated login - not startup phase
    _isStartupPhase = false;

    state = const AuthStateAuthenticating();

    try {
      final result = await _loginWithAppleUseCase();

      await result.fold(
        (failure) async => _handleFailure(failure),
        (session) async {
          if (session.accessToken.isEmpty) {
            if (kDebugMode) {
              debugPrint('⚠️ [Auth] Session has no access token');
            }
            _handleFailure(const UnknownAuthFailure());
            return;
          }
          try {
            await tokenManager?.save(session.accessToken);
          } catch (_) {}

          if (kDebugMode) {
            debugPrint('✅ [Auth] Session established - checking deletion status');
          }
          await _setAuthenticatedState(session);
        },
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('🔐 [Auth] Apple sign-in error (caught): $e');
        debugPrint('Stack: $stack');
      }
      _handleFailure(const UnknownAuthFailure());
    }
  }

  /// Login with email and password
  Future<void> loginWithEmail(String email, String password) async {
    if (kDebugMode) {
      debugPrint('🔐 [Auth] Starting email login...');
    }

    // CRITICAL: Reset logout state immediately to allow login flow
    // This ensures /auth/session requests are not blocked
    final tokenManager = _tokenManager;
    tokenManager?.resetLogoutState();

    // User-initiated login - not startup phase
    _isStartupPhase = false;

    state = const AuthStateAuthenticating();

    final result = await _loginWithEmailUseCase(email, password);

    result.fold(
      (failure) => _handleFailure(failure),
      (session) async {
        final token = await tokenManager?.get();
        if (token == null || token.isEmpty) {
          if (kDebugMode) {
            debugPrint('⚠️ [Auth] Token not found after login - this should not happen');
          }
          _handleFailure(const UnknownAuthFailure());
          return;
        }

        if (kDebugMode) {
          debugPrint('✅ [Auth] Session established - checking deletion status');
        }
        await _setAuthenticatedState(session);
      },
    );
  }

  /// Register with email and password
  Future<void> registerWithEmail(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) async {
    if (kDebugMode) {
      debugPrint('🔐 [Auth] Starting email registration...');
    }

    // CRITICAL: Reset logout state immediately to allow registration flow
    final tokenManager = _tokenManager;
    tokenManager?.resetLogoutState();

    // User-initiated registration - not startup phase
    _isStartupPhase = false;

    state = const AuthStateAuthenticating();

    final result = await _registerWithEmailUseCase(
      email,
      password,
      firstName: firstName,
      lastName: lastName,
    );

    result.fold(
      (failure) => _handleFailure(failure),
      (session) async {
        final token = await tokenManager?.get();
        if (token == null || token.isEmpty) {
          if (kDebugMode) {
            debugPrint('⚠️ [Auth] Token not found after registration - this should not happen');
          }
          _handleFailure(const UnknownAuthFailure());
          return;
        }

        if (kDebugMode) {
          debugPrint('✅ [Auth] Session established - checking deletion status');
        }
        await _setAuthenticatedState(session);
      },
    );
  }

  /// Request password reset
  Future<bool> forgotPassword(String email) async {
    if (kDebugMode) {
      debugPrint('🔐 [Auth] Requesting password reset for: $email');
    }

    final result = await _forgotPasswordUseCase(email);

    return result.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint('🔐 [Auth] Password reset failed: $failure');
        }
        return false;
      },
      (_) {
        if (kDebugMode) {
          debugPrint('🔐 [Auth] Password reset email sent');
        }
        return true;
      },
    );
  }

  /// Logout current user - SINGLE POINT OF LOGOUT
  ///
  /// CRITICAL: This is the ONLY place where logout happens.
  /// All logout logic must be here. No shortcuts, no backend calls.
  /// Call after account restore succeeds so the app shows HOME instead of grace period.
  void setAuthenticatedAfterRestore() {
    final current = state;
    if (current is AuthStateGracePeriod) {
      if (kDebugMode) {
        debugPrint('🔐 [Auth] Restore complete - switching to authenticated');
      }
      state = AuthStateAuthenticated(current.session);
    }
  }

  ///
  /// Flow (MANDATORY ORDER):
  /// 1. AuthStateLoggingOut (blocks API requests)
  /// 2. Clear token (memory + secure storage)
  /// 3. Clear in-memory session state
  /// 4. FirebaseAuth.signOut()
  /// 5. AuthStateUnauthenticated
  /// 6. Navigation handled by authNavigationProvider
  Future<void> logout() async {
    if (kDebugMode) {
      debugPrint('🚪 [Auth] Logout initiated');
    }

    // STEP 1: Set logging out state (blocks API requests)
    state = const AuthStateLoggingOut();

    try {
      // STEP 2: Clear token (memory + secure storage)
      if (kDebugMode) {
        debugPrint('🧹 [Auth] Clearing token');
      }
      final tokenManager = _tokenManager;
      if (tokenManager != null) {
        await tokenManager.logout();
      }

      // STEP 3: Clear in-memory session state
      if (kDebugMode) {
        debugPrint('🧼 [Auth] Clearing session state');
      }
      // Clear local session via logout use case (clears local storage)
      await _logoutUseCase();

      // STEP 4: Firebase sign-out (REQUIRED)
      if (kDebugMode) {
        debugPrint('🔥 [Auth] Firebase signOut');
      }
      await firebase.FirebaseAuth.instance.signOut();

      // Also sign out and disconnect from Google Sign-In if it was used.
      // disconnect() clears cached credentials so the next sign-in works.
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
        await googleSignIn.disconnect();
      } catch (e) {
        // Ignore Google Sign-In errors - Firebase sign-out is sufficient
        if (kDebugMode) {
          debugPrint(
            '⚠️ [Auth] Google Sign-In sign-out failed (non-critical): $e',
          );
        }
      }

      // STEP 5: Set unauthenticated state
      if (kDebugMode) {
        debugPrint('✅ [Auth] Logout complete → Unauthenticated');
      }
      state = const AuthStateUnauthenticated();
    } catch (e) {
      // Even on error, ensure we're logged out
      if (kDebugMode) {
        debugPrint('❌ [Auth] Logout error (forcing complete): $e');
      }
      // Force clear everything
      try {
        await firebase.FirebaseAuth.instance.signOut();
      } catch (_) {}
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
        await googleSignIn.disconnect();
      } catch (_) {}
      try {
        await _tokenManager?.logout();
      } catch (_) {}
      state = const AuthStateUnauthenticated();
    }
  }

  /// Clear error state and return to unauthenticated
  void clearError() {
    if (state is AuthStateError) {
      state = const AuthStateUnauthenticated();
    }
  }

  /// Establish backend session - SINGLE POINT OF AUTHENTICATION
  ///
  /// CRITICAL: This is the ONLY place where AuthStateAuthenticated is set.
  /// All authentication paths (login, app start, etc.) must call this method
  /// after successfully calling POST /auth/session.
  ///
  /// Flow:
  /// 1. Fetch Firebase ID token
  /// 2. Save token
  /// 3. POST /auth/session
  /// 4. If success → AuthStateAuthenticated
  /// 5. If failure → logout + Unauthenticated
  Future<void> _establishBackendSession(AuthSession session) async {
    if (kDebugMode) {
      debugPrint('🔑 [Auth] Fetching Firebase ID token...');
    }

    final tokenManager = _tokenManager;
    if (tokenManager == null) {
      if (kDebugMode) {
        debugPrint('❌ [Auth] TokenManager not available');
      }
      _handleFailure(const UnknownAuthFailure());
      return;
    }

    // CRITICAL: Reset logout state before making API calls
    // This ensures /auth/session is never blocked by stale logout flag
    tokenManager.resetLogoutState();

    try {
      // STEP 1: Fetch Firebase ID token (for /auth/session only)
      final firebaseToken = await getIdTokenOnce();

      // CRITICAL: /auth/session MUST succeed before marking user as authenticated
      // This ensures backend has the user record and issues backend JWT
      final apiService = _apiService;
      if (apiService == null) {
        throw Exception(
          'ApiService not available - cannot establish backend session',
        );
      }

      if (kDebugMode) {
        debugPrint('📡 [Auth] Establishing backend session...');
      }

      // STEP 2: Call /auth/session with Firebase ID token (Dio baseUrl is already set)
      // Backend verifies Firebase token and returns backend JWT
      final response = await apiService.dio.post<Map<String, dynamic>>(
        '/auth/session',
        data: {'idToken': firebaseToken},
      );

      // STEP 3: Extract backend JWT from response
      // Response is wrapped in { data: {...}, statusCode: ... } format
      final responseData = response.data;
      if (responseData == null || !responseData.containsKey('data')) {
        throw Exception('Backend did not return data in expected format');
      }

      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null || !data.containsKey('accessToken')) {
        throw Exception('Backend did not return accessToken');
      }

      final backendJwt = data['accessToken'] as String;
      if (backendJwt.isEmpty) {
        throw Exception('Backend returned empty accessToken');
      }

      if (kDebugMode) {
        debugPrint('💾 [Auth] Backend JWT received - saving...');
      }

      // STEP 4: Store backend JWT (this is the only token used for API calls)
      await tokenManager.save(backendJwt);

      // Verify token is available
      if (!tokenManager.hasToken) {
        throw Exception('Backend JWT was stored but not available');
      }

      if (kDebugMode) {
        debugPrint('✅ [Auth] Session established with backend JWT - checking deletion status');
      }

      // PHASE 3: Set authenticated state (or grace period if pending_deletion)
      final sessionWithJwt = AuthSession(
        userId: session.userId,
        email: session.email,
        accessToken: backendJwt,
      );
      await _setAuthenticatedState(sessionWithJwt);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Auth] Failed to establish session (login): $e');
        if (e is DioException) {
          debugPrint('   Dio Error: ${e.type} - ${e.message}');
          debugPrint('   Dio Response: ${e.response?.statusCode} - ${e.response?.data}');
          debugPrint('   Dio Request: ${e.requestOptions.method} ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        }
      }
      // Clear token on failure
      await tokenManager.clear();
      
      // Map exception to appropriate failure
      final failure = _mapExceptionToFailure(e);
      _handleFailure(failure);
    }
  }
  
  /// Map exceptions to domain failures
  AuthFailure _mapExceptionToFailure(Object e) {
    // Check for network-related errors
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return const NetworkFailure();
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode != null && statusCode >= 500) {
            return const ServerFailure();
          }
          if (statusCode == 401 || statusCode == 403) {
            return const UnauthorizedFailure();
          }
          return const ServerFailure();
        default:
          // Check if underlying error is network-related
          if (e.error is SocketException || 
              e.error is HttpException ||
              e.message?.toLowerCase().contains('network') == true ||
              e.message?.toLowerCase().contains('connection') == true) {
            return const NetworkFailure();
          }
          return const UnknownAuthFailure();
      }
    }
    
    // Check for SocketException (network connectivity)
    if (e is SocketException) {
      return const NetworkFailure();
    }
    
    // Check for HttpException (network-related)
    if (e is HttpException) {
      return const NetworkFailure();
    }
    
    // Check error message for network-related keywords
    final errorString = e.toString().toLowerCase();
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('failed host lookup')) {
      return const NetworkFailure();
    }
    
    // Default to unknown failure
    return const UnknownAuthFailure();
  }

  /// Handle authentication failure
  void _handleFailure(AuthFailure failure) {
    if (kDebugMode) {
      debugPrint('🔐 [Auth] Auth failure: $failure');
      debugPrint('   Failure Type: ${failure.runtimeType}');
      
      // Log additional context if available
      if (failure is ServerFailure) {
        debugPrint('   ⚠️ Server error - Backend may be down or unreachable');
        debugPrint('   Check: Is backend running? Is URL correct?');
        debugPrint('   Backend URL: ${AppConfig.backendBaseUrl}');
      } else if (failure is NetworkFailure) {
        debugPrint('   ⚠️ Network error - Check internet connection');
      } else if (failure is UnauthorizedFailure) {
        debugPrint('   ⚠️ Authentication failed - Invalid credentials');
      }
    }

    // Check if this failure should be shown to user
    if (!AuthFailureMessageMapper.shouldShowError(failure)) {
      // User cancelled - just return to unauthenticated
      state = const AuthStateUnauthenticated();
      return;
    }

    // Get exception message if available (extracted during mapping)
    final exceptionMessage = AuthFailureMapper.getLastExceptionMessage();
    
    // Map failure to user-friendly message, using exception message if available
    final message = exceptionMessage != null && 
            (failure is UnauthorizedFailure || failure is ServerFailure)
        ? exceptionMessage
        : AuthFailureMessageMapper.mapToMessage(failure);

    state = AuthStateError(failure: failure, message: message);
  }
}
