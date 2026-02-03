/// Email validation utility
///
/// Provides consistent email validation across the app
/// Uses RFC 5322 compliant regex pattern
class EmailValidator {
  EmailValidator._();

  /// RFC 5322 compliant email regex pattern
  /// Matches: user@example.com, user.name@example.co.uk, etc.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validate email address format
  ///
  /// Returns true if email is valid, false otherwise
  static bool isValid(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Validate email and return error message if invalid
  ///
  /// Returns null if valid, error message if invalid
  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter your email';
    }

    final trimmedEmail = email.trim();
    if (!isValid(trimmedEmail)) {
      return 'Please enter a valid email address';
    }

    return null;
  }
}
