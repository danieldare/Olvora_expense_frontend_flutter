import '../../domain/core/either.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for password reset - Application Layer
///
/// Single responsibility: Request password reset email.
///
/// No Flutter dependencies.
class ForgotPasswordUseCase {
  final AuthRepository _repository;

  const ForgotPasswordUseCase(this._repository);

  /// Request password reset for email
  ///
  /// Returns [Either<AuthFailure, void>] unchanged from repository.
  Future<Either<AuthFailure, void>> call(String email) {
    return _repository.forgotPassword(email);
  }
}
