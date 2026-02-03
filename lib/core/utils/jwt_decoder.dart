import 'dart:convert';

/// JWT decoder utility
///
/// Decodes JWT tokens without verification (for extracting claims like expiration).
/// CRITICAL: This does NOT verify the token signature - it only decodes the payload.
/// Token verification is handled by the backend.
class JwtDecoder {
  const JwtDecoder._();

  /// Decode JWT payload without verification
  ///
  /// Returns the payload as a Map, or null if decoding fails.
  /// The payload contains claims like `exp`, `iat`, `sub`, `email`, etc.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null; // Invalid JWT format
      }

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed (base64url may not have padding)
      final normalized = _normalizeBase64(payload);
      
      // Decode base64
      final decoded = utf8.decode(base64Decode(normalized));
      
      // Parse JSON
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      // Decoding failed - token may be invalid or malformed
      return null;
    }
  }

  /// Extract expiration timestamp from JWT
  ///
  /// Returns the expiration as DateTime, or null if:
  /// - Token cannot be decoded
  /// - `exp` claim is missing
  /// - `exp` claim is invalid
  static DateTime? getExpiration(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp == null) return null;

    // `exp` is a Unix timestamp (seconds since epoch)
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } else if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch((exp * 1000).toInt());
    }

    return null;
  }

  /// Check if JWT token is expired
  ///
  /// Returns true if:
  /// - Token is expired (current time > exp)
  /// - Token cannot be decoded
  /// - `exp` claim is missing
  static bool isExpired(String token) {
    final expiration = getExpiration(token);
    if (expiration == null) return false; // Can't determine, assume valid
    
    return DateTime.now().isAfter(expiration);
  }

  /// Normalize base64url to base64 (add padding if needed)
  static String _normalizeBase64(String base64url) {
    // Base64url uses - and _ instead of + and /
    String normalized = base64url.replaceAll('-', '+').replaceAll('_', '/');
    
    // Add padding if needed
    switch (normalized.length % 4) {
      case 1:
        normalized += '===';
        break;
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
    }
    
    return normalized;
  }
}
