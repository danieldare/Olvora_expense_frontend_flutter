import '../../domain/core/either.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for email/password registration - Application Layer
///
/// Single responsibility: Orchestrate email registration flow.
///
/// No Flutter dependencies.
class RegisterWithEmailUseCase {
  final AuthRepository _repository;

  const RegisterWithEmailUseCase(this._repository);

  /// Execute email/password registration
  ///
  /// Returns [Either<AuthFailure, AuthSession>] unchanged from repository.
  Future<Either<AuthFailure, AuthSession>> call(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) {
    return _repository.registerWithEmail(
      email,
      password,
      firstName: firstName,
      lastName: lastName,
    );
  }
}
