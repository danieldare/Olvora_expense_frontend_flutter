import '../../domain/core/either.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../mappers/auth_failure_mapper.dart';
import '../mappers/auth_session_mapper.dart';
import '../../../../core/services/token_manager_service.dart';

/// Implementation of [AuthRepository] - Data Layer
///
/// Responsibilities:
/// - Coordinate remote and local data sources
/// - Convert DTOs to domain entities
/// - Map exceptions to domain failures
/// - Sync tokens with TokenManagerService for API requests
/// - Return Either<AuthFailure, T>
///
/// CRITICAL: All exceptions are caught HERE and mapped to failures.
/// No exceptions escape this class.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final TokenManagerService? _tokenManager;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    TokenManagerService? tokenManager,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _tokenManager = tokenManager;

  @override
  Future<Either<AuthFailure, AuthSession>> loginWithGoogle() async {
    try {
      // 1. Authenticate with Google via remote data source
      final dto = await _remoteDataSource.loginWithGoogle();

      // 2. Cache session locally
      await _localDataSource.saveSession(dto);

      // 3. Sync token with TokenManagerService for API requests
      // CRITICAL: TokenManagerService is used by ApiServiceV2 to attach tokens to requests
      final tokenManager = _tokenManager;
      if (tokenManager != null) {
        try {
          await tokenManager.save(dto.accessToken);
        } catch (e) {
          // Log but don't fail - session is saved, token sync is best-effort
        }
      }

      // 4. Convert to domain entity and return success
      final session = AuthSessionMapper.toDomain(dto);
      return Right(session);
    } catch (e) {
      // Map exception to domain failure
      return Left(AuthFailureMapper.mapException(e));
    }
  }

  @override
  Future<Either<AuthFailure, AuthSession>> loginWithApple() async {
    try {
      final dto = await _remoteDataSource.loginWithApple();
      await _localDataSource.saveSession(dto);

      // Sync token with TokenManagerService
      final tokenManager = _tokenManager;
      if (tokenManager != null) {
        try {
          await tokenManager.save(dto.accessToken);
        } catch (e) {
          // Log but don't fail
        }
      }

      final session = AuthSessionMapper.toDomain(dto);
      return Right(session);
    } catch (e) {
      return Left(AuthFailureMapper.mapException(e));
    }
  }

  @override
  Future<Either<AuthFailure, AuthSession>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final dto = await _remoteDataSource.loginWithEmail(email, password);
      await _localDataSource.saveSession(dto);

      // Sync token with TokenManagerService
      final tokenManager = _tokenManager;
      if (tokenManager != null) {
        try {
          await tokenManager.save(dto.accessToken);
        } catch (e) {
          // Log but don't fail
        }
      }

      final session = AuthSessionMapper.toDomain(dto);
      return Right(session);
    } catch (e) {
      return Left(AuthFailureMapper.mapException(e));
    }
  }

  @override
  Future<Either<AuthFailure, AuthSession>> registerWithEmail(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      final dto = await _remoteDataSource.registerWithEmail(
        email,
        password,
        firstName: firstName,
        lastName: lastName,
      );
      await _localDataSource.saveSession(dto);

      // Sync token with TokenManagerService
      final tokenManager = _tokenManager;
      if (tokenManager != null) {
        try {
          await tokenManager.save(dto.accessToken);
        } catch (e) {
          // Log but don't fail
        }
      }

      final session = AuthSessionMapper.toDomain(dto);
      return Right(session);
    } catch (e) {
      return Left(AuthFailureMapper.mapException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> forgotPassword(String email) async {
    try {
      await _remoteDataSource.forgotPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailureMapper.mapException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> logout() async {
    try {
      // CRITICAL: Logout is frontend-only. No backend calls.
      // Just clear local session storage.
      await _localDataSource.clearSession();

      return const Right(null);
    } catch (e) {
      // Even if clear fails, try to clear anyway
      try {
        await _localDataSource.clearSession();
      } catch (_) {}
      // Don't fail logout - always succeed
      return const Right(null);
    }
  }

  @override
  Future<Either<AuthFailure, AuthSession?>> getCachedSession() async {
    try {
      final dto = await _localDataSource.getSession();

      if (dto == null) {
        return const Right(null);
      }

      final session = AuthSessionMapper.toDomain(dto);

      // Check if session is expired
      if (session.isExpired) {
        await _localDataSource.clearSession();
        // Also clear token from TokenManagerService
        final tokenManager = _tokenManager;
        if (tokenManager != null) {
          try {
            await tokenManager.clear();
          } catch (_) {}
        }
        return const Right(null);
      }

      // Sync token with TokenManagerService if not already synced
      // This ensures API requests work after app restart
      final tokenManager = _tokenManager;
      if (tokenManager != null) {
        try {
          final currentToken = await tokenManager.get();
          if (currentToken != dto.accessToken) {
            await tokenManager.save(dto.accessToken);
          }
        } catch (e) {
          // Log but don't fail - session is valid
        }
      }

      return Right(session);
    } catch (e) {
      return Left(AuthFailureMapper.mapException(e));
    }
  }

  @override
  Future<Either<AuthFailure, AccountDeletionResult>> deleteAccount() async {
    try {
      // Get current session to get the access token
      final dto = await _localDataSource.getSession();
      if (dto == null) {
        return const Left(UnauthorizedFailure());
      }

      // Call delete account API
      final responseData = await _remoteDataSource.deleteAccount(dto.accessToken);

      // Parse the result
      final result = AccountDeletionResult.fromJson(responseData);

      return Right(result);
    } catch (e) {
      return Left(AuthFailureMapper.mapException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> restoreAccount() async {
    try {
      // Use TokenManager first (same token ApiServiceV2 uses) so we're consistent
      // with the token that was valid when user was redirected to grace period.
      final tokenManager = _tokenManager;
      String? token = tokenManager != null ? await tokenManager.get() : null;
      if (token == null || token.isEmpty) {
        final dto = await _localDataSource.getSession();
        if (dto == null || dto.accessToken.isEmpty) {
          return const Left(UnauthorizedFailure());
        }
        token = dto.accessToken;
      }
      await _remoteDataSource.restoreAccount(token);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailureMapper.mapException(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> hardDeleteOnly() async {
    try {
      // Use TokenManager first (same token ApiServiceV2 uses) so we're consistent
      final tokenManager = _tokenManager;
      String? token = tokenManager != null ? await tokenManager.get() : null;
      if (token == null || token.isEmpty) {
        final dto = await _localDataSource.getSession();
        if (dto == null || dto.accessToken.isEmpty) {
          return const Left(UnauthorizedFailure());
        }
        token = dto.accessToken;
      }
      await _remoteDataSource.hardDeleteOnly(token);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailureMapper.mapException(e));
    }
  }
}
