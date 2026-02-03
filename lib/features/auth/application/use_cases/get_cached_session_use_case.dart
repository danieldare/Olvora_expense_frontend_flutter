import '../../domain/core/either.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for retrieving cached session - Application Layer
///
/// Single responsibility: Check for existing authenticated session.
/// Used on app startup to restore login state.
///
/// No Flutter dependencies.
class GetCachedSessionUseCase {
  final AuthRepository _repository;

  const GetCachedSessionUseCase(this._repository);

  /// Get cached session from secure storage
  ///
  /// Returns:
  /// - Right(AuthSession) if valid session exists
  /// - Right(null) if no cached session
  /// - Left(AuthFailure) if storage error
  Future<Either<AuthFailure, AuthSession?>> call() {
    return _repository.getCachedSession();
  }
}
