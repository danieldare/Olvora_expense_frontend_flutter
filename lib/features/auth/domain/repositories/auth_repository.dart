import '../core/either.dart';
import '../entities/auth_session.dart';
import '../failures/auth_failure.dart';

/// Authentication repository contract - Domain Layer
///
/// Defines the interface for all authentication operations.
/// Implementations handle infrastructure concerns (APIs, SDKs, storage).
///
/// Returns Either<AuthFailure, T> for explicit error handling.
/// Never throws exceptions - all errors are domain failures.
///
/// No Flutter dependencies. No infrastructure details.
abstract class AuthRepository {
  /// Authenticate using Google Sign-In
  ///
  /// Flow:
  /// 1. Opens Google Sign-In dialog
  /// 2. Retrieves Google ID token
  /// 3. Exchanges token with backend
  /// 4. Returns authenticated session
  ///
  /// Possible failures:
  /// - [UserCancelledFailure] if user dismisses dialog
  /// - [NetworkFailure] if no connectivity
  /// - [UnauthorizedFailure] if token rejected
  /// - [ServerFailure] if backend error
  /// - [UnknownAuthFailure] for unexpected errors
  Future<Either<AuthFailure, AuthSession>> loginWithGoogle();

  /// Authenticate using Apple Sign-In
  ///
  /// Only available on iOS/macOS.
  /// Similar flow to Google Sign-In.
  Future<Either<AuthFailure, AuthSession>> loginWithApple();

  /// Authenticate using email and password
  Future<Either<AuthFailure, AuthSession>> loginWithEmail(
    String email,
    String password,
  );

  /// Register with email and password
  Future<Either<AuthFailure, AuthSession>> registerWithEmail(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  });

  /// Request password reset email
  Future<Either<AuthFailure, void>> forgotPassword(String email);

  /// End current session
  Future<Either<AuthFailure, void>> logout();

  /// Retrieve cached session from secure storage
  ///
  /// Returns null in Right if no cached session exists.
  Future<Either<AuthFailure, AuthSession?>> getCachedSession();

  /// Delete user account (soft delete with grace period)
  ///
  /// Initiates account deletion. User has a grace period to recover.
  /// Returns account deletion status with recovery deadline.
  ///
  /// Possible failures:
  /// - [UnauthorizedFailure] if not authenticated
  /// - [NetworkFailure] if no connectivity
  /// - [ServerFailure] if backend error
  Future<Either<AuthFailure, AccountDeletionResult>> deleteAccount();

  /// Restore account from pending deletion (within grace period).
  Future<Either<AuthFailure, void>> restoreAccount();

  /// Permanently delete account (start afresh – no new account created).
  Future<Either<AuthFailure, void>> hardDeleteOnly();
}

/// Result of account deletion request
class AccountDeletionResult {
  final String status;
  final DateTime? recoveryDeadline;
  final int? daysRemaining;
  final String message;

  const AccountDeletionResult({
    required this.status,
    this.recoveryDeadline,
    this.daysRemaining,
    required this.message,
  });

  factory AccountDeletionResult.fromJson(Map<String, dynamic> json) {
    DateTime? deadline;
    if (json['recoveryDeadline'] != null) {
      deadline = DateTime.tryParse(json['recoveryDeadline'].toString());
    }

    int? days;
    if (json['daysRemaining'] != null) {
      days = json['daysRemaining'] as int?;
    } else if (deadline != null) {
      days = deadline.difference(DateTime.now()).inDays;
    }

    return AccountDeletionResult(
      status: json['status'] as String? ?? 'pending_deletion',
      recoveryDeadline: deadline,
      daysRemaining: days,
      message: json['message'] as String? ?? 'Account scheduled for deletion',
    );
  }
}
