import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/config/app_config.dart';
import '../dtos/auth_session_dto.dart';
import '../exceptions/auth_exceptions.dart';

/// Remote data source for authentication - Data Layer
///
/// Responsibilities:
/// - Interact with Google Sign-In SDK
/// - Interact with Firebase Auth
/// - Call backend API for token exchange
/// - Throw technical exceptions on failure
/// - Return DTOs on success
///
/// CRITICAL: All SDK and HTTP logic stays HERE.
/// Exceptions thrown here are caught by the repository.
abstract class AuthRemoteDataSource {
  /// Sign in with Google and get session from backend
  Future<AuthSessionDto> loginWithGoogle();

  /// Sign in with Apple and get session from backend
  Future<AuthSessionDto> loginWithApple();

  /// Sign in with email/password
  Future<AuthSessionDto> loginWithEmail(String email, String password);

  /// Register with email/password
  Future<AuthSessionDto> registerWithEmail(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  });

  /// Request password reset
  Future<void> forgotPassword(String email);

  /// Logout from backend
  Future<void> logout(String accessToken);

  /// Delete user account (soft delete with grace period)
  /// Returns the deletion status with recovery deadline
  Future<Map<String, dynamic>> deleteAccount(String accessToken);

  /// Restore account from pending deletion (within grace period)
  Future<void> restoreAccount(String accessToken);

  /// Permanently delete account (start afresh flow)
  Future<void> hardDeleteOnly(String accessToken);
}

/// Implementation of [AuthRemoteDataSource]
///
/// CRITICAL: Uses lazy initialization for Firebase services.
/// Firebase services are only accessed when methods are called,
/// ensuring Firebase.initializeApp() has completed first.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  // Lazy-initialized Firebase services
  // These are only accessed when login methods are called
  GoogleSignIn? _googleSignIn;
  firebase.FirebaseAuth? _firebaseAuth;

  AuthRemoteDataSourceImpl({
    required Dio dio,
    GoogleSignIn? googleSignIn,
    firebase.FirebaseAuth? firebaseAuth,
  }) : _dio = dio,
       _googleSignIn = googleSignIn,
       _firebaseAuth = firebaseAuth;

  /// Lazy getter for GoogleSignIn - only accessed when needed
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn();
    return _googleSignIn!;
  }

  /// Lazy getter for FirebaseAuth - only accessed when needed
  firebase.FirebaseAuth get firebaseAuth {
    _firebaseAuth ??= firebase.FirebaseAuth.instance;
    return _firebaseAuth!;
  }

  static const int _googleSignInMaxAttempts = 2;
  static const Duration _googleSignInRetryDelay = Duration(milliseconds: 600);

  /// Returns true if the error is likely transient (network, timeout, Play Services not ready).
  bool _isTransientGoogleError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('network') ||
        s.contains('connection') ||
        s.contains('timeout') ||
        s.contains('unreachable') ||
        s.contains('sign_in_failed') ||
        s.contains('api_not_available') ||
        s.contains('play services');
  }

  @override
  Future<AuthSessionDto> loginWithGoogle() async {
    Object? lastError;
    for (int attempt = 1; attempt <= _googleSignInMaxAttempts; attempt++) {
      try {
        if (attempt > 1 && kDebugMode) {
          debugPrint('🔄 [Auth] Google sign-in retry attempt $attempt/$_googleSignInMaxAttempts');
        }
        final dto = await _loginWithGoogleOnce();
        return dto;
      } on SignInCancelledException {
        rethrow;
      } on UnauthorizedException {
        rethrow;
      } on GoogleSignInException catch (e) {
        lastError = e;
        if (attempt == _googleSignInMaxAttempts || !_isTransientGoogleError(e)) rethrow;
        await Future.delayed(_googleSignInRetryDelay);
      } on FirebaseAuthException catch (e) {
        lastError = e;
        final isTransient = e.code == 'network-request-failed' || _isTransientGoogleError(e);
        if (attempt == _googleSignInMaxAttempts || !isTransient) rethrow;
        await Future.delayed(_googleSignInRetryDelay);
      } catch (e) {
        lastError = e;
        if (attempt == _googleSignInMaxAttempts || !_isTransientGoogleError(e)) rethrow;
        await Future.delayed(_googleSignInRetryDelay);
      }
    }
    if (lastError != null && lastError is Exception) throw lastError;
    throw GoogleSignInException('Google sign-in failed after $_googleSignInMaxAttempts attempts', lastError);
  }

  Future<AuthSessionDto> _loginWithGoogleOnce() async {
    // Step 1: Google Sign-In (lazy access)
    final GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.signIn();
    } catch (e) {
      throw GoogleSignInException('Failed to initiate Google Sign-In', e);
    }

    if (googleUser == null) {
      throw const SignInCancelledException();
    }

    // Step 2: Get Google auth credentials
    final GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } catch (e) {
      throw GoogleSignInException('Failed to get Google authentication', e);
    }

    // Step 3: Sign in to Firebase with Google credential
    try {
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await firebaseAuth.signInWithCredential(credential);
    } on firebase.FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        message: e.message ?? 'Firebase authentication failed',
        code: e.code,
        cause: e,
      );
    }

    // Step 4: Get Firebase ID token for backend verification
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw const UnauthorizedException('Failed to get Firebase user');
    }

    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw const UnauthorizedException('Failed to get Firebase ID token');
    }

    // Step 5: Exchange Firebase ID token with backend via /auth/session
    return _exchangeTokenWithBackend(firebaseIdToken);
  }

  @override
  Future<AuthSessionDto> loginWithApple() async {
    // Apple Sign-In only available on iOS/macOS
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw const AppleSignInException(
        'Apple Sign-In is only available on iOS/macOS',
      );
    }

    // Step 1: Apple Sign-In
    final AuthorizationCredentialAppleID? appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException) {
        if (e.code == AuthorizationErrorCode.canceled) {
          throw const SignInCancelledException();
        }
        throw AppleSignInException(
          'Failed to initiate Apple Sign-In: ${e.message}',
          e,
        );
      }
      throw AppleSignInException('Failed to initiate Apple Sign-In', e);
    }

    // Step 2: Sign in to Firebase with Apple credential
    // Note: For Apple Sign-In, only identityToken is required (accessToken is optional)
    try {
      final oauthCredential = firebase.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
      );
      await firebaseAuth.signInWithCredential(oauthCredential);
    } on firebase.FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        message: e.message ?? 'Firebase authentication failed',
        code: e.code,
        cause: e,
      );
    }

    // Step 3: Get Firebase ID token for backend verification
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw const UnauthorizedException('Failed to get Firebase user');
    }

    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw const UnauthorizedException('Failed to get Firebase ID token');
    }

    // Step 4: Exchange Firebase ID token with backend
    return _exchangeTokenWithBackend(firebaseIdToken);
  }

  @override
  Future<AuthSessionDto> loginWithEmail(String email, String password) async {
    try {
      // Step 1: Sign in to Firebase with email/password
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const UnauthorizedException('Failed to sign in with Firebase');
      }

      // Step 2: Get Firebase ID token for backend verification
      final firebaseIdToken = await firebaseUser.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw const UnauthorizedException('Failed to get Firebase ID token');
      }

      // Step 3: Exchange Firebase ID token with backend via /auth/session
      return _exchangeTokenWithBackend(firebaseIdToken);
    } on firebase.FirebaseAuthException catch (e) {
      // Map Firebase Auth errors to our exception types
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          throw UnauthorizedException(
            'Invalid email or password',
            e,
          );
        case 'user-disabled':
          throw UnauthorizedException(
            'This account has been disabled',
            e,
          );
        case 'too-many-requests':
          throw UnauthorizedException(
            'Too many failed attempts. Please try again later',
            e,
          );
        case 'network-request-failed':
          throw NetworkException('Network error. Please check your connection', e);
        default:
          throw FirebaseAuthException(
            message: e.message ?? 'Firebase authentication failed',
            code: e.code,
            cause: e,
          );
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw ServerException(
        message: 'Unexpected error during login',
        cause: e,
      );
    }
  }

  @override
  Future<AuthSessionDto> registerWithEmail(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      // Step 1: Create user in Firebase with email/password
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const UnauthorizedException('Failed to create Firebase user');
      }

      // Step 2: Update user profile with name if provided
      if (firstName != null || lastName != null) {
        try {
          final displayName = [
            if (firstName != null && firstName.isNotEmpty) firstName,
            if (lastName != null && lastName.isNotEmpty) lastName,
          ].join(' ');

          if (displayName.isNotEmpty) {
            await firebaseUser.updateDisplayName(displayName);
            await firebaseUser.reload();
          }
        } catch (e) {
          // Non-critical - continue even if profile update fails
          if (kDebugMode) {
            debugPrint('⚠️ [Auth] Failed to update user profile: $e');
          }
        }
      }

      // Step 3: Get Firebase ID token for backend verification
      final firebaseIdToken = await firebaseUser.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw const UnauthorizedException('Failed to get Firebase ID token');
      }

      // Step 4: Exchange Firebase ID token with backend via /auth/session
      // Backend will create user record with firstName/lastName from Firebase token
      return _exchangeTokenWithBackend(firebaseIdToken);
    } on firebase.FirebaseAuthException catch (e) {
      // Map Firebase Auth errors to our exception types
      switch (e.code) {
        case 'email-already-in-use':
          throw UnauthorizedException(
            'An account with this email already exists',
            e,
          );
        case 'weak-password':
          throw UnauthorizedException(
            'Password is too weak. Please choose a stronger password',
            e,
          );
        case 'invalid-email':
          throw UnauthorizedException(
            'Invalid email address',
            e,
          );
        case 'operation-not-allowed':
          throw UnauthorizedException(
            'Email/password authentication is not enabled',
            e,
          );
        case 'network-request-failed':
          throw NetworkException('Network error. Please check your connection', e);
        default:
          throw FirebaseAuthException(
            message: e.message ?? 'Firebase authentication failed',
            code: e.code,
            cause: e,
          );
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw ServerException(
        message: 'Unexpected error during registration',
        cause: e,
      );
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      // Use Firebase's password reset functionality
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (e) {
      // Map Firebase Auth errors to our exception types
      switch (e.code) {
        case 'user-not-found':
          // Don't reveal if user exists - just say email sent
          // Firebase will send email even if user doesn't exist (security best practice)
          return;
        case 'invalid-email':
          throw UnauthorizedException(
            'Invalid email address',
            e,
          );
        case 'network-request-failed':
          throw NetworkException('Network error. Please check your connection', e);
        default:
          throw FirebaseAuthException(
            message: e.message ?? 'Failed to send password reset email',
            code: e.code,
            cause: e,
          );
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw ServerException(
        message: 'Unexpected error sending password reset email',
        cause: e,
      );
    }
  }

  @override
  Future<void> logout(String accessToken) async {
    // CRITICAL: Logout is frontend-only. No backend calls.
    // Firebase sign-out is handled in AuthNotifier.
    // This method is kept for interface compatibility but does nothing.
    // All logout logic is in AuthNotifier.logout()
  }

  @override
  Future<Map<String, dynamic>> deleteAccount(String accessToken) async {
    try {
      if (kDebugMode) {
        debugPrint('🗑️ [Auth] Requesting account deletion...');
      }

      final response = await _dio.delete<Map<String, dynamic>>(
        '/users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.data == null) {
        throw const ServerException(message: 'Empty response from server');
      }

      final responseData = response.data!;

      // Extract data from response
      if (responseData.containsKey('data')) {
        final data = responseData['data'] as Map<String, dynamic>?;
        if (data != null) {
          if (kDebugMode) {
            debugPrint('✅ [Auth] Account deletion initiated');
            debugPrint('   Status: ${data['status']}');
            debugPrint('   Recovery deadline: ${data['recoveryDeadline']}');
          }
          return data;
        }
      }

      // Return the response data if no nested data
      return responseData;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Auth] Account deletion failed');
        debugPrint('   Error: ${e.message}');
        debugPrint('   Status: ${e.response?.statusCode}');
      }
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> restoreAccount(String accessToken) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 [Auth] Requesting account restore...');
      }

      await _dio.post<Map<String, dynamic>>(
        '/auth/account/restore',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ [Auth] Account restored');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Auth] Account restore failed: ${e.message}');
      }
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> hardDeleteOnly(String accessToken) async {
    try {
      if (kDebugMode) {
        debugPrint('🗑️ [Auth] Requesting hard delete (start afresh)...');
      }

      await _dio.post<Map<String, dynamic>>(
        '/auth/account/hard-delete',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ [Auth] Account hard deleted');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Auth] Hard delete failed: ${e.message}');
      }
      throw _mapDioException(e);
    }
  }

  /// Exchange Firebase ID token with backend for session
  ///
  /// CRITICAL: This method is used by ALL authentication methods (Google, Apple, Email/Password)
  /// to exchange Firebase ID token for backend JWT via /auth/session endpoint.
  /// This ensures unified authentication flow.
  Future<AuthSessionDto> _exchangeTokenWithBackend(String idToken) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 [Auth] Exchanging Firebase ID token with backend...');
        debugPrint('   Backend URL: ${AppConfig.backendBaseUrl}/auth/session');
      }

      // Use /auth/session endpoint (Dio baseUrl is already set to backendBaseUrl)
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/session',
        data: {'idToken': idToken},
      );

      if (response.data == null) {
        throw const ServerException(message: 'Empty response from server');
      }

      // Extract backend JWT from response
      // Response is wrapped in { data: {...}, statusCode: ... } format
      final responseData = response.data!;
      Map<String, dynamic> sessionData;

      if (responseData.containsKey('data')) {
        // New format: { data: { accessToken: ..., user: {...} } }
        final data = responseData['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw const ServerException(message: 'Backend did not return data');
        }
        sessionData = data;
      } else {
        // Legacy format: { access_token: ..., user: {...} }
        sessionData = responseData;
      }

      // Normalize accessToken field name
      if (sessionData.containsKey('accessToken')) {
        sessionData['access_token'] = sessionData['accessToken'];
      }

      if (kDebugMode) {
        debugPrint('✅ [Auth] Backend token exchange successful');
      }

      return AuthSessionDto.fromJson(sessionData);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Auth] Backend token exchange failed');
        debugPrint('   Error Type: ${e.type}');
        debugPrint('   Error Message: ${e.message}');
        debugPrint('   Status Code: ${e.response?.statusCode}');
        debugPrint('   Response Data: ${e.response?.data}');
        debugPrint(
          '   Request URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}',
        );
        if (e.error != null) {
          debugPrint('   Underlying Error: ${e.error}');
        }
      }
      throw _mapDioException(e);
    }
  }

  /// Map Dio exceptions to auth exceptions
  AuthException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException('Connection failed', e);

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        // Extract error message: NestJS may return message as string or object
        String? errorMessage;
        if (responseData is Map<String, dynamic>) {
          final msg = responseData['message'];
          if (msg is String) {
            errorMessage = msg;
          } else if (msg is Map) {
            final nested = msg['message'];
            if (nested is String) errorMessage = nested;
          }
          if (errorMessage == null) {
            errorMessage = responseData['error'] as String?;
          }
        }

        if (statusCode == 401 || statusCode == 403) {
          return UnauthorizedException(
            errorMessage ?? 'Invalid credentials',
            e,
          );
        }
        
        // Handle 409 Conflict (email already exists)
        if (statusCode == 409) {
          return UnauthorizedException(
            errorMessage ?? 'An account with this email already exists',
            e,
          );
        }
        
        // Handle 400 BadRequest (validation errors like weak password)
        if (statusCode == 400) {
          return UnauthorizedException(
            errorMessage ?? 'Invalid request. Please check your input and try again.',
            e,
          );
        }
        
        if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: errorMessage ?? 'Server error',
            statusCode: statusCode,
            cause: e,
          );
        }
        
        return ServerException(
          message: errorMessage ?? e.response?.statusMessage ?? 'Request failed',
          statusCode: statusCode,
          cause: e,
        );

      case DioExceptionType.cancel:
        return const SignInCancelledException('Request cancelled');

      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return NetworkException('No internet connection', e);
        }
        return ServerException(message: 'Unknown error', cause: e);

      default:
        return ServerException(message: 'Request failed', cause: e);
    }
  }
}
