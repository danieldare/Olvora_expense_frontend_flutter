import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../dtos/auth_session_dto.dart';
import '../exceptions/auth_exceptions.dart';

/// Local data source for auth session persistence - Data Layer
///
/// Responsibilities:
/// - Securely store auth session
/// - Retrieve cached session
/// - Clear session on logout
///
/// Uses FlutterSecureStorage for encrypted storage.
abstract class AuthLocalDataSource {
  /// Save session to secure storage
  Future<void> saveSession(AuthSessionDto session);

  /// Get cached session from secure storage
  /// Returns null if no session exists
  Future<AuthSessionDto?> getSession();

  /// Clear session from secure storage
  Future<void> clearSession();

  /// Check if a session exists
  Future<bool> hasSession();
}

/// Implementation of [AuthLocalDataSource]
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _storage;

  static const String _sessionKey = 'auth_session';

  AuthLocalDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  @override
  Future<void> saveSession(AuthSessionDto session) async {
    try {
      await _storage.write(
        key: _sessionKey,
        value: session.toJsonString(),
      );
    } catch (e) {
      throw StorageException('Failed to save session', e);
    }
  }

  @override
  Future<AuthSessionDto?> getSession() async {
    try {
      final jsonString = await _storage.read(key: _sessionKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      return AuthSessionDto.fromJsonString(jsonString);
    } catch (e) {
      throw StorageException('Failed to read session', e);
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _sessionKey);
    } catch (e) {
      throw StorageException('Failed to clear session', e);
    }
  }

  @override
  Future<bool> hasSession() async {
    try {
      final session = await _storage.read(key: _sessionKey);
      return session != null && session.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
