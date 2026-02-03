/// Password validation utility
///
/// Provides consistent password validation across the app
/// Matches backend requirements for security
class PasswordValidator {
  PasswordValidator._();

  /// Minimum password length (matches backend requirement)
  static const int minLength = 12;

  /// Common passwords that should be rejected
  static const List<String> commonPasswords = [
    'password',
    'password123',
    '12345678',
    'qwerty123',
    'abc123456',
    'password1',
    'password!',
    'Password123',
    'Password123!',
  ];

  /// Validate password strength
  ///
  /// Returns true if password meets all requirements, false otherwise
  static bool isValid(String password) {
    if (password.length < minLength) return false;

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;

    // Check for number
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;

    // Check for special character
    // Pattern matches: !@#$%^&*()_+-=[]{};:"|,.<>/?
    final specialCharPattern = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?]');
    if (!specialCharPattern.hasMatch(password)) {
      return false;
    }

    // Check against common passwords
    if (commonPasswords.any((common) =>
        password.toLowerCase().contains(common.toLowerCase()))) {
      return false;
    }

    return true;
  }

  /// Validate password and return error message if invalid
  ///
  /// Returns null if valid, error message if invalid
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter a password';
    }

    if (password.length < minLength) {
      return 'Password must be at least $minLength characters long';
    }

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for number
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }

    // Check for special character
    // Pattern matches: !@#$%^&*()_+-=[]{};:"|,.<>/?
    final specialCharPattern = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?]');
    if (!specialCharPattern.hasMatch(password)) {
      return 'Password must contain at least one special character';
    }

    // Check against common passwords
    if (commonPasswords.any((common) =>
        password.toLowerCase().contains(common.toLowerCase()))) {
      return 'Password is too common. Please choose a stronger password';
    }

    return null;
  }

  /// Get password requirements text for UI
  static String getRequirementsText() {
    return 'Password must be at least $minLength characters and contain:\n'
        '• Uppercase letter\n'
        '• Lowercase letter\n'
        '• Number\n'
        '• Special character';
  }
}
