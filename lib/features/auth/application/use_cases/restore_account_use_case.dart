import '../../domain/core/either.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for restoring an account from pending deletion.
///
/// Only works within the grace period. Account returns to active state.
class RestoreAccountUseCase {
  final AuthRepository _repository;

  RestoreAccountUseCase(this._repository);

  Future<Either<AuthFailure, void>> call() async {
    return _repository.restoreAccount();
  }
}
