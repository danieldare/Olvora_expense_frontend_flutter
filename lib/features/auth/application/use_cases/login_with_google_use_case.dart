import '../../domain/core/either.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for Google Sign-In authentication - Application Layer
///
/// Single responsibility: Orchestrate Google login flow.
///
/// This use case:
/// - Has NO try/catch (repository handles errors)
/// - Has NO mapping (returns result unchanged)
/// - Has NO business logic beyond delegation
///
/// No Flutter dependencies.
class LoginWithGoogleUseCase {
  final AuthRepository _repository;

  const LoginWithGoogleUseCase(this._repository);

  /// Execute Google Sign-In
  ///
  /// Returns [Either<AuthFailure, AuthSession>] unchanged from repository.
  /// All error handling is done at the repository level.
  Future<Either<AuthFailure, AuthSession>> call() {
    return _repository.loginWithGoogle();
  }
}
