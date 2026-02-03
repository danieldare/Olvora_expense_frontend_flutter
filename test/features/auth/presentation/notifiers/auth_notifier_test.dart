import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:frontend_flutter_main/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:frontend_flutter_main/features/auth/application/use_cases/login_with_google_use_case.dart';
import 'package:frontend_flutter_main/features/auth/application/use_cases/login_with_apple_use_case.dart';
import 'package:frontend_flutter_main/features/auth/application/use_cases/login_with_email_use_case.dart';
import 'package:frontend_flutter_main/features/auth/application/use_cases/register_with_email_use_case.dart';
import 'package:frontend_flutter_main/features/auth/application/use_cases/forgot_password_use_case.dart';
import 'package:frontend_flutter_main/features/auth/application/use_cases/get_cached_session_use_case.dart';
import 'package:frontend_flutter_main/features/auth/application/use_cases/logout_use_case.dart';
import 'package:frontend_flutter_main/features/auth/domain/core/either.dart';
import 'package:frontend_flutter_main/features/auth/domain/entities/auth_session.dart';
import 'package:frontend_flutter_main/features/auth/domain/failures/auth_failure.dart';
import 'package:frontend_flutter_main/features/auth/presentation/state/auth_state.dart';
import 'package:frontend_flutter_main/core/services/token_manager_service.dart';
import 'package:frontend_flutter_main/core/services/api_service_v2.dart';
import 'package:dio/dio.dart';

import 'auth_notifier_test.mocks.dart';

@GenerateMocks([
  LoginWithGoogleUseCase,
  LoginWithAppleUseCase,
  LoginWithEmailUseCase,
  RegisterWithEmailUseCase,
  ForgotPasswordUseCase,
  GetCachedSessionUseCase,
  LogoutUseCase,
  TokenManagerService,
  ApiServiceV2,
])
void main() {
  group('AuthNotifier', () {
    late AuthNotifier authNotifier;
    late MockLoginWithGoogleUseCase mockLoginWithGoogleUseCase;
    late MockLoginWithAppleUseCase mockLoginWithAppleUseCase;
    late MockLoginWithEmailUseCase mockLoginWithEmailUseCase;
    late MockRegisterWithEmailUseCase mockRegisterWithEmailUseCase;
    late MockForgotPasswordUseCase mockForgotPasswordUseCase;
    late MockGetCachedSessionUseCase mockGetCachedSessionUseCase;
    late MockLogoutUseCase mockLogoutUseCase;
    late MockTokenManagerService mockTokenManagerService;
    late MockApiServiceV2 mockApiService;

    final testSession = AuthSession(
      userId: 'test-user-id',
      email: 'test@example.com',
      accessToken: 'test-access-token',
    );

    setUp(() {
      mockLoginWithGoogleUseCase = MockLoginWithGoogleUseCase();
      mockLoginWithAppleUseCase = MockLoginWithAppleUseCase();
      mockLoginWithEmailUseCase = MockLoginWithEmailUseCase();
      mockRegisterWithEmailUseCase = MockRegisterWithEmailUseCase();
      mockForgotPasswordUseCase = MockForgotPasswordUseCase();
      mockGetCachedSessionUseCase = MockGetCachedSessionUseCase();
      mockLogoutUseCase = MockLogoutUseCase();
      mockTokenManagerService = MockTokenManagerService();
      mockApiService = MockApiServiceV2();

      authNotifier = AuthNotifier(
        loginWithGoogleUseCase: mockLoginWithGoogleUseCase,
        loginWithAppleUseCase: mockLoginWithAppleUseCase,
        loginWithEmailUseCase: mockLoginWithEmailUseCase,
        registerWithEmailUseCase: mockRegisterWithEmailUseCase,
        forgotPasswordUseCase: mockForgotPasswordUseCase,
        getCachedSessionUseCase: mockGetCachedSessionUseCase,
        logoutUseCase: mockLogoutUseCase,
        tokenManager: mockTokenManagerService,
        apiService: mockApiService,
      );
    });

    group('Initial State', () {
      test('should start in Initializing state', () {
        expect(authNotifier.state, isA<AuthStateInitializing>());
        expect(authNotifier.isStartupPhase, isTrue);
      });
    });

    group('loginWithGoogle', () {
      test('should transition to Authenticated on success', () async {
        // Arrange
        when(mockTokenManagerService.resetLogoutState()).thenReturn(null);
        when(mockTokenManagerService.get())
            .thenAnswer((_) async => 'test-token');
        when(mockLoginWithGoogleUseCase())
            .thenAnswer((_) async => Right(testSession));

        // Act
        await authNotifier.loginWithGoogle();

        // Assert
        expect(authNotifier.state, isA<AuthStateAuthenticated>());
        expect(authNotifier.isStartupPhase, isFalse);
        final authenticatedState = authNotifier.state as AuthStateAuthenticated;
        expect(authenticatedState.session.email, equals('test@example.com'));
        verify(mockTokenManagerService.resetLogoutState()).called(1);
      });

      test('should handle failure and set error state', () async {
        // Arrange
        when(mockTokenManagerService.resetLogoutState()).thenReturn(null);
        when(mockLoginWithGoogleUseCase())
            .thenAnswer((_) async => const Left(NetworkFailure()));

        // Act
        await authNotifier.loginWithGoogle();

        // Assert
        expect(authNotifier.state, isA<AuthStateError>());
        expect(authNotifier.isStartupPhase, isFalse);
      });

      test('should handle missing token after login', () async {
        // Arrange
        when(mockTokenManagerService.resetLogoutState()).thenReturn(null);
        when(mockTokenManagerService.get()).thenAnswer((_) async => null);
        when(mockLoginWithGoogleUseCase())
            .thenAnswer((_) async => Right(testSession));

        // Act
        await authNotifier.loginWithGoogle();

        // Assert
        expect(authNotifier.state, isA<AuthStateError>());
      });
    });

    group('loginWithEmail', () {
      test('should transition to Authenticated on success', () async {
        // Arrange
        when(mockTokenManagerService.resetLogoutState()).thenReturn(null);
        when(mockTokenManagerService.get())
            .thenAnswer((_) async => 'test-token');
        when(mockLoginWithEmailUseCase(any, any))
            .thenAnswer((_) async => Right(testSession));

        // Act
        await authNotifier.loginWithEmail('test@example.com', 'password123');

        // Assert
        expect(authNotifier.state, isA<AuthStateAuthenticated>());
        verify(mockLoginWithEmailUseCase('test@example.com', 'password123'))
            .called(1);
      });

      test('should handle invalid credentials', () async {
        // Arrange
        when(mockTokenManagerService.resetLogoutState()).thenReturn(null);
        when(mockLoginWithEmailUseCase(any, any))
            .thenAnswer((_) async => const Left(UnauthorizedFailure()));

        // Act
        await authNotifier.loginWithEmail('test@example.com', 'wrong');

        // Assert
        expect(authNotifier.state, isA<AuthStateError>());
        final errorState = authNotifier.state as AuthStateError;
        expect(errorState.failure, isA<UnauthorizedFailure>());
      });
    });

    group('registerWithEmail', () {
      test('should transition to Authenticated on success', () async {
        // Arrange
        when(mockTokenManagerService.resetLogoutState()).thenReturn(null);
        when(mockTokenManagerService.get())
            .thenAnswer((_) async => 'test-token');
        when(mockRegisterWithEmailUseCase(any, any,
                firstName: anyNamed('firstName'),
                lastName: anyNamed('lastName')))
            .thenAnswer((_) async => Right(testSession));

        // Act
        await authNotifier.registerWithEmail(
          'new@example.com',
          'password123',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Assert
        expect(authNotifier.state, isA<AuthStateAuthenticated>());
        verify(mockRegisterWithEmailUseCase(
          'new@example.com',
          'password123',
          firstName: 'John',
          lastName: 'Doe',
        )).called(1);
      });
    });

    group('forgotPassword', () {
      test('should return true on success', () async {
        // Arrange
        when(mockForgotPasswordUseCase(any))
            .thenAnswer((_) async => const Right(null));

        // Act
        final result = await authNotifier.forgotPassword('test@example.com');

        // Assert
        expect(result, isTrue);
        verify(mockForgotPasswordUseCase('test@example.com')).called(1);
      });

      test('should return false on failure', () async {
        // Arrange
        when(mockForgotPasswordUseCase(any))
            .thenAnswer((_) async => const Left(NetworkFailure()));

        // Act
        final result = await authNotifier.forgotPassword('test@example.com');

        // Assert
        expect(result, isFalse);
      });
    });

    group('logout', () {
      test('should clear state and transition to Unauthenticated', () async {
        // Arrange
        when(mockTokenManagerService.logout())
            .thenAnswer((_) async => Future.value());
        when(mockLogoutUseCase())
            .thenAnswer((_) async => const Right(null));

        // Act
        await authNotifier.logout();

        // Assert
        expect(authNotifier.state, isA<AuthStateUnauthenticated>());
        verify(mockTokenManagerService.logout()).called(1);
        verify(mockLogoutUseCase()).called(1);
      });
    });

    group('clearError', () {
      test('should clear error state and return to Unauthenticated', () {
        // Arrange
        authNotifier.state = AuthStateError(
          failure: const NetworkFailure(),
          message: 'Network error',
        );

        // Act
        authNotifier.clearError();

        // Assert
        expect(authNotifier.state, isA<AuthStateUnauthenticated>());
      });

      test('should not change state if not in error', () {
        // Arrange
        authNotifier.state = const AuthStateUnauthenticated();

        // Act
        authNotifier.clearError();

        // Assert
        expect(authNotifier.state, isA<AuthStateUnauthenticated>());
      });
    });
  });
}
