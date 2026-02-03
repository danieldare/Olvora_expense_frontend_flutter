import '../../domain/core/either.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// Use case for deleting user account
///
/// Initiates account deletion with a grace period for recovery.
/// Returns the deletion status including recovery deadline.
class DeleteAccountUseCase {
  final AuthRepository _repository;

  DeleteAccountUseCase(this._repository);

  /// Execute the delete account operation
  ///
  /// Returns [AccountDeletionResult] with status and recovery deadline
  /// or [AuthFailure] if the operation fails.
  Future<Either<AuthFailure, AccountDeletionResult>> call() async {
    return _repository.deleteAccount();
  }
}
