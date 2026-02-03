/// Authenticated session entity - Domain Layer
///
/// Represents a successfully authenticated user session.
/// Contains all tokens and user identification needed for API calls.
///
/// INVARIANTS:
/// - userId is never empty
/// - email is a valid email format
/// - accessToken is never empty
///
/// No Flutter dependencies. No infrastructure details.
class AuthSession {
  final String userId;
  final String email;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  /// Check if the session has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if the session is still valid
  bool get isValid => !isExpired && accessToken.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          email == other.email &&
          accessToken == other.accessToken;

  @override
  int get hashCode => userId.hashCode ^ email.hashCode ^ accessToken.hashCode;

  @override
  String toString() => 'AuthSession(userId: $userId, email: $email)';
}
