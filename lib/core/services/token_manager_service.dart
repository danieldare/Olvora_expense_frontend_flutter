import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

/// Simple token management service
///
/// CRITICAL PRINCIPLES:
/// - Tokens are long-lived (~30 days)
/// - No refresh logic
/// - No retry logic
/// - If token invalid → user logs out
/// - Storage is only source of truth on app start
/// - Runtime uses in-memory cache only
///
/// Interface:
/// - save(token) - Store token securely
/// - get() - Get token (checks cache first, then storage)
/// - clear() - Clear token
/// - hasToken - Sync getter checking in-memory cache only
class TokenManagerService {
  // Secure storage configuration
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false, // Prevent iCloud sync for security
    ),
  );

  // Storage key
  static const String _accessTokenKey = 'auth_token';

  // In-memory cache (source of truth during runtime)
  String? _cachedToken;
  bool _cacheLoaded = false; // True after initial load from storage
  bool _isLoggingOut = false; // Blocks token access during logout

  /// Check if logout is in progress
  ///
  /// CRITICAL: During logout, all token access is blocked.
  bool get isLoggingOut => _isLoggingOut;

  /// Reset logout state to allow login flow
  ///
  /// CRITICAL: This must be called at the start of login flows
  /// to ensure /auth/session requests are not blocked.
  /// This clears the logout flag without clearing tokens.
  void resetLogoutState() {
    if (_isLoggingOut) {
      _isLoggingOut = false;
      AppLogger.d(
        '🔄 [TokenManager] Logout state reset - login flow can proceed',
        tag: 'TokenManager',
      );
    }
  }

  /// Check if token exists (checks secure storage)
  ///
  /// CRITICAL: This checks in-memory cache first (for performance),
  /// but cache is always synced with secure storage.
  /// Storage is the source of truth - cache is loaded from storage on app start
  /// and updated whenever save() or clear() is called.
  /// Returns false during logout to block API requests.
  bool get hasToken {
    if (_isLoggingOut) {
      return false; // Block token access during logout
    }
    // Check cache (which is synced with secure storage)
    // Cache is loaded from storage on app start via loadFromStorage()
    // and updated whenever save() or clear() is called
    return _cachedToken != null && _cachedToken!.isNotEmpty;
  }

  /// Save token to secure storage and update cache
  ///
  /// CRITICAL: This is the only way to store tokens.
  /// After save, token is immediately available via hasToken.
  /// Resets logout flag to allow token access after login.
  Future<void> save(String token) async {
    if (token.isEmpty) {
      throw ArgumentError('Token cannot be empty');
    }

    try {
      // Store in secure storage
      await _storage.write(key: _accessTokenKey, value: token);

      // Update in-memory cache immediately
      _cachedToken = token;
      _cacheLoaded = true;

      // Reset logout flag (new login, allow token access)
      _isLoggingOut = false;

      AppLogger.d('💾 [TokenManager] Token saved', tag: 'TokenManager');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to save token',
        tag: 'TokenManager',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get token from cache or storage
  ///
  /// CRITICAL: During runtime, this checks cache first.
  /// Storage is only read if cache is not loaded (app start).
  /// Returns null during logout to block API requests.
  Future<String?> get() async {
    // Block token access during logout
    if (_isLoggingOut) {
      return null;
    }

    // Return cached token if available
    if (_cacheLoaded && _cachedToken != null) {
      return _cachedToken;
    }

    // Load from storage (only on app start)
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        _cacheLoaded = true;
        AppLogger.d(
          '📦 [TokenManager] Token loaded from storage',
          tag: 'TokenManager',
        );
      } else {
        _cachedToken = null;
        _cacheLoaded = true;
      }
      return token;
    } catch (e) {
      AppLogger.e(
        'Failed to read token from storage',
        tag: 'TokenManager',
        error: e,
      );
      _cachedToken = null;
      _cacheLoaded = true;
      return null;
    }
  }

  /// Clear token from storage and cache
  ///
  /// CRITICAL: This immediately clears both storage and cache.
  /// After clear, hasToken will return false.
  Future<void> clear() async {
    try {
      // Clear from storage
      await _storage.delete(key: _accessTokenKey);

      // Clear cache immediately
      _cachedToken = null;
      _cacheLoaded = true;

      AppLogger.d('🚪 [TokenManager] Token cleared', tag: 'TokenManager');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to clear token',
        tag: 'TokenManager',
        error: e,
        stackTrace: stackTrace,
      );
      // Clear cache even if storage clear fails
      _cachedToken = null;
      _cacheLoaded = true;
      rethrow;
    }
  }

  /// Logout - clear token and block further access
  ///
  /// CRITICAL: This is called during logout to:
  /// 1. Set logout flag (blocks token access)
  /// 2. Clear token from memory
  /// 3. Clear token from secure storage
  ///
  /// After logout completes, the flag is reset on next login (when save() is called).
  Future<void> logout() async {
    // Set logout flag immediately (blocks all token access)
    _isLoggingOut = true;

    try {
      // Clear from storage
      await _storage.delete(key: _accessTokenKey);

      // Clear cache immediately
      _cachedToken = null;
      _cacheLoaded = true;

      AppLogger.d(
        '🚪 [TokenManager] Logout - token cleared and access blocked',
        tag: 'TokenManager',
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to clear token during logout',
        tag: 'TokenManager',
        error: e,
        stackTrace: stackTrace,
      );
      // Clear cache even if storage clear fails
      _cachedToken = null;
      _cacheLoaded = true;
      // Don't rethrow - logout must complete even if storage fails
    }
  }

  /// Load token from storage into cache (call on app start)
  ///
  /// CRITICAL: This should be called once on app start to populate cache.
  /// After this, all operations use cache only.
  Future<void> loadFromStorage() async {
    if (_cacheLoaded) {
      return; // Already loaded
    }

    try {
      final token = await _storage.read(key: _accessTokenKey);
      _cachedToken = token;
      _cacheLoaded = true;

      if (token != null && token.isNotEmpty) {
        AppLogger.d(
          '📦 [TokenManager] Token loaded from storage on app start',
          tag: 'TokenManager',
        );
      }
    } catch (e) {
      AppLogger.e(
        'Failed to load token from storage on app start',
        tag: 'TokenManager',
        error: e,
      );
      _cachedToken = null;
      _cacheLoaded = true;
    }
  }
}
