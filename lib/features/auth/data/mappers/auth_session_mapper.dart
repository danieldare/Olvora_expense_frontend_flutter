import '../../../../core/utils/jwt_decoder.dart';
import '../../domain/entities/auth_session.dart';
import '../dtos/auth_session_dto.dart';

/// Maps between DTOs and domain entities - Data Layer
///
/// Keeps domain layer pure by handling all conversion logic here.
class AuthSessionMapper {
  const AuthSessionMapper._();

  /// Convert DTO to domain entity
  ///
  /// Extracts expiration from JWT token if not provided in DTO.
  static AuthSession toDomain(AuthSessionDto dto) {
    // Try to extract expiration from JWT token if expiresIn is not provided
    DateTime? expiresAt;
    
    if (dto.expiresIn != null) {
      // Use expiresIn from DTO if available
      expiresAt = DateTime.now().add(Duration(seconds: dto.expiresIn!));
    } else if (dto.accessToken.isNotEmpty) {
      // Decode JWT to extract expiration from token
      expiresAt = JwtDecoder.getExpiration(dto.accessToken);
    }

    return AuthSession(
      userId: dto.userId,
      email: dto.email,
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      expiresAt: expiresAt,
    );
  }

  /// Convert domain entity to DTO (for caching)
  static AuthSessionDto toDto(AuthSession session) {
    final secondsUntilExpiry = session.expiresAt?.difference(DateTime.now()).inSeconds;

    return AuthSessionDto(
      userId: session.userId,
      email: session.email,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresIn: secondsUntilExpiry != null && secondsUntilExpiry > 0
          ? secondsUntilExpiry
          : null,
    );
  }
}
