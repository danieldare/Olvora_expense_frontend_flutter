import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:frontend_flutter_main/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend_flutter_main/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:frontend_flutter_main/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:frontend_flutter_main/features/auth/data/dtos/auth_session_dto.dart';
import 'package:frontend_flutter_main/features/auth/data/exceptions/auth_exceptions.dart';
import 'package:frontend_flutter_main/features/auth/domain/core/either.dart';
import 'package:frontend_flutter_main/features/auth/domain/failures/auth_failure.dart';
import 'package:frontend_flutter_main/core/services/token_manager_service.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([
  AuthRemoteDataSource,
  AuthLocalDataSource,
  TokenManagerService,
])
void main() {
  group('AuthRepositoryImpl', () {
    late AuthRepositoryImpl repository;
    late MockAuthRemoteDataSource mockRemoteDataSource;
    late MockAuthLocalDataSource mockLocalDataSource;
    late MockTokenManagerService mockTokenManager;

    final testDto = AuthSessionDto(
      userId: 'test-user-id',
      email: 'test@example.com',
      accessToken: 'test-access-token',
    );

    setUp(() {
      mockRemoteDataSource = MockAuthRemoteDataSource();
      mockLocalDataSource = MockAuthLocalDataSource();
      mockTokenManager = MockTokenManagerService();

      repository = AuthRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
        tokenManager: mockTokenManager,
      );
    });

    group('loginWithGoogle', () {
      test('should return Right with session on success', () async {
        // Arrange
        when(mockRemoteDataSource.loginWithGoogle())
            .thenAnswer((_) async => testDto);
        when(mockLocalDataSource.saveSession(any))
            .thenAnswer((_) async => Future.value());
        when(mockTokenManager.save(any))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.loginWithGoogle();

        // Assert
        expect(result.isRight, isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (session) {
            expect(session.email, equals('test@example.com'));
            expect(session.userId, equals('test-user-id'));
            expect(session.accessToken, equals('test-access-token'));
          },
        );
        verify(mockRemoteDataSource.loginWithGoogle()).called(1);
        verify(mockLocalDataSource.saveSession(testDto)).called(1);
        verify(mockTokenManager.save('test-access-token')).called(1);
      });

      test('should return Left with failure on exception', () async {
        // Arrange
        when(mockRemoteDataSource.loginWithGoogle())
            .thenThrow(NetworkException('Network error', null));

        // Act
        final result = await repository.loginWithGoogle();

        // Assert
        expect(result.isLeft, isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (session) => fail('Should not return session'),
        );
      });
    });

    group('loginWithEmail', () {
      test('should return Right with session on success', () async {
        // Arrange
        when(mockRemoteDataSource.loginWithEmail(any, any))
            .thenAnswer((_) async => testDto);
        when(mockLocalDataSource.saveSession(any))
            .thenAnswer((_) async => Future.value());
        when(mockTokenManager.save(any))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.loginWithEmail(
          'test@example.com',
          'password123',
        );

        // Assert
        expect(result.isRight, isTrue);
        verify(mockRemoteDataSource.loginWithEmail(
          'test@example.com',
          'password123',
        )).called(1);
      });

      test('should handle Firebase Auth errors', () async {
        // Arrange
        when(mockRemoteDataSource.loginWithEmail(any, any)).thenThrow(
          UnauthorizedException('Invalid credentials', null),
        );

        // Act
        final result = await repository.loginWithEmail(
          'test@example.com',
          'wrong',
        );

        // Assert
        expect(result.isLeft, isTrue);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('Should not return session'),
        );
      });
    });

    group('registerWithEmail', () {
      test('should return Right with session on success', () async {
        // Arrange
        when(mockRemoteDataSource.registerWithEmail(
          any,
          any,
          firstName: anyNamed('firstName'),
          lastName: anyNamed('lastName'),
        )).thenAnswer((_) async => testDto);
        when(mockLocalDataSource.saveSession(any))
            .thenAnswer((_) async => Future.value());
        when(mockTokenManager.save(any))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.registerWithEmail(
          'new@example.com',
          'password123',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Assert
        expect(result.isRight, isTrue);
        verify(mockRemoteDataSource.registerWithEmail(
          'new@example.com',
          'password123',
          firstName: 'John',
          lastName: 'Doe',
        )).called(1);
      });
    });

    group('getCachedSession', () {
      test('should return Right with session if valid', () async {
        // Arrange
        when(mockLocalDataSource.getSession())
            .thenAnswer((_) async => testDto);
        when(mockTokenManager.get())
            .thenAnswer((_) async => 'test-access-token');

        // Act
        final result = await repository.getCachedSession();

        // Assert
        expect(result.isRight, isTrue);
        result.fold(
          (_) => fail('Should not return failure'),
          (session) {
            expect(session, isNotNull);
            expect(session!.email, equals('test@example.com'));
          },
        );
      });

      test('should return Right with null if no cached session', () async {
        // Arrange
        when(mockLocalDataSource.getSession())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getCachedSession();

        // Assert
        expect(result.isRight, isTrue);
        result.fold(
          (_) => fail('Should not return failure'),
          (session) => expect(session, isNull),
        );
      });

      test('should clear session if expired', () async {
        // Arrange
        // Create a DTO with negative expiresIn (expired 1 hour ago)
        // The mapper will convert this to a past expiresAt DateTime
        final expiredDto = AuthSessionDto(
          userId: 'test-user-id',
          email: 'test@example.com',
          accessToken: 'test-token',
          expiresIn: -3600, // Expired 1 hour ago (negative = past)
        );
        when(mockLocalDataSource.getSession())
            .thenAnswer((_) async => expiredDto);
        when(mockLocalDataSource.clearSession())
            .thenAnswer((_) async => Future.value());
        when(mockTokenManager.clear())
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.getCachedSession();

        // Assert
        expect(result.isRight, isTrue);
        result.fold(
          (_) => fail('Should not return failure'),
          (session) => expect(session, isNull),
        );
        verify(mockLocalDataSource.clearSession()).called(1);
        verify(mockTokenManager.clear()).called(1);
      });
    });

    group('logout', () {
      test('should clear session and return Right', () async {
        // Arrange
        when(mockLocalDataSource.clearSession())
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.logout();

        // Assert
        expect(result.isRight, isTrue);
        verify(mockLocalDataSource.clearSession()).called(1);
      });

      test('should return Right even if clear fails', () async {
        // Arrange
        when(mockLocalDataSource.clearSession())
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.logout();

        // Assert
        expect(result.isRight, isTrue);
        // Should try to clear again
        verify(mockLocalDataSource.clearSession()).called(greaterThan(1));
      });
    });
  });
}
