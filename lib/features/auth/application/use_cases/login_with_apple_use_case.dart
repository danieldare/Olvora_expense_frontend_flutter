import '../../domain/core/either.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for Apple Sign-In authentication - Application Layer
///
/// Single responsibility: Orchestrate Apple login flow.
///
/// No Flutter dependencies.
class LoginWithAppleUseCase {
  final AuthRepository _repository;

  const LoginWithAppleUseCase(this._repository);

  /// Execute Apple Sign-In
  ///
  /// Returns [Either<AuthFailure, AuthSession>] unchanged from repository.
  Future<Either<AuthFailure, AuthSession>> call() {
    return _repository.loginWithApple();
  }
}
