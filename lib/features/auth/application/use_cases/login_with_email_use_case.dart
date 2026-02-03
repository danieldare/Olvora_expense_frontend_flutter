import '../../domain/core/either.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for email/password authentication - Application Layer
///
/// Single responsibility: Orchestrate email login flow.
///
/// No Flutter dependencies.
class LoginWithEmailUseCase {
  final AuthRepository _repository;

  const LoginWithEmailUseCase(this._repository);

  /// Execute email/password login
  ///
  /// Returns [Either<AuthFailure, AuthSession>] unchanged from repository.
  Future<Either<AuthFailure, AuthSession>> call(String email, String password) {
    return _repository.loginWithEmail(email, password);
  }
}
