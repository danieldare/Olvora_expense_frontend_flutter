import '../../domain/core/either.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for permanently deleting an account (start afresh).
///
/// Permanently deletes the current account. User should then sign up again.
class HardDeleteAccountUseCase {
  final AuthRepository _repository;

  HardDeleteAccountUseCase(this._repository);

  Future<Either<AuthFailure, void>> call() async {
    return _repository.hardDeleteOnly();
  }
}
