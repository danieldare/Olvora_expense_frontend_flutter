import '../../domain/core/either.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for logout - Application Layer
///
/// Single responsibility: End current session.
///
/// No Flutter dependencies.
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  /// Execute logout
  ///
  /// Returns [Either<AuthFailure, void>] unchanged from repository.
  Future<Either<AuthFailure, void>> call() {
    return _repository.logout();
  }
}
