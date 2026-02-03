import 'dart:convert';

/// Data Transfer Object for auth session - Data Layer
///
/// Used for:
/// - Parsing API responses
/// - Storing in secure storage
/// - Converting to/from JSON
///
/// Contains serialization logic that doesn't belong in domain.
class AuthSessionDto {
  final String userId;
  final String email;
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn; // Seconds until expiration

  const AuthSessionDto({
    required this.userId,
    required this.email,
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  /// Parse from API response JSON
  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    // Handle different API response formats
    final user = json['user'] as Map<String, dynamic>?;

    return AuthSessionDto(
      userId: user?['id'] as String? ?? json['userId'] as String? ?? '',
      email: user?['email'] as String? ?? json['email'] as String? ?? '',
      accessToken:
          json['access_token'] as String? ??
          json['accessToken'] as String? ??
          '',
      refreshToken:
          json['refresh_token'] as String? ?? json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int? ?? json['expires_in'] as int?,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (expiresIn != null) 'expiresIn': expiresIn,
    };
  }

  /// Serialize to JSON string for secure storage
  String toJsonString() => jsonEncode(toJson());

  /// Parse from JSON string (secure storage)
  factory AuthSessionDto.fromJsonString(String jsonString) {
    return AuthSessionDto.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  @override
  String toString() => 'AuthSessionDto(userId: $userId, email: $email)';
}
