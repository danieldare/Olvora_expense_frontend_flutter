import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for secure PIN storage and verification
///
/// Security Implementation:
/// - PBKDF2-SHA256 with 100,000 iterations
/// - 32-byte random salt per PIN
/// - Uses same FlutterSecureStorage config as TokenManagerService
/// - PIN hash and salt stored separately
class PinService {
  // Secure storage configuration (same as TokenManagerService)
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  // Storage keys
  static const String _pinHashKey = 'app_pin_hash';
  static const String _pinSaltKey = 'app_pin_salt';

  // PBKDF2 parameters
  static const int _iterations = 100000;
  static const int _hashLength = 32; // 256 bits
  static const int _saltLength = 32; // 256 bits

  /// Generate a cryptographically secure random salt
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  /// Derive key using PBKDF2-SHA256
  ///
  /// Note: Dart's crypto package doesn't have native PBKDF2,
  /// so we implement it using HMAC-SHA256 as per RFC 2898
  Uint8List _deriveKey(String pin, Uint8List salt) {
    // PBKDF2 implementation using HMAC-SHA256
    final hmac = Hmac(sha256, utf8.encode(pin));

    // We need dkLen/hLen blocks (32/32 = 1 block for our case)
    final derivedKey = Uint8List(_hashLength);

    // For each block (we only need 1 block since hashLength == 32)
    for (int blockIndex = 1; blockIndex <= (_hashLength / 32).ceil(); blockIndex++) {
      // U_1 = PRF(Password, Salt || INT(i))
      final blockInput = Uint8List(salt.length + 4);
      blockInput.setAll(0, salt);
      blockInput[salt.length] = (blockIndex >> 24) & 0xff;
      blockInput[salt.length + 1] = (blockIndex >> 16) & 0xff;
      blockInput[salt.length + 2] = (blockIndex >> 8) & 0xff;
      blockInput[salt.length + 3] = blockIndex & 0xff;

      var u = Uint8List.fromList(hmac.convert(blockInput).bytes);
      var result = Uint8List.fromList(u);

      // U_2 ... U_c
      for (int i = 1; i < _iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        // XOR with result
        for (int j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }

      // Copy to derived key
      final offset = (blockIndex - 1) * 32;
      final copyLength = min(_hashLength - offset, 32);
      derivedKey.setRange(offset, offset + copyLength, result);
    }

    return derivedKey;
  }

  /// Hash a PIN with the given salt
  String _hashPin(String pin, Uint8List salt) {
    final derivedKey = _deriveKey(pin, salt);
    return base64Encode(derivedKey);
  }

  /// Save a new PIN
  ///
  /// Generates a new salt and stores both hash and salt securely
  Future<void> savePin(String pin) async {
    if (pin.isEmpty || pin.length < 4) {
      throw ArgumentError('PIN must be at least 4 digits');
    }

    try {
      // Generate new salt
      final salt = _generateSalt();

      // Hash PIN
      final hash = _hashPin(pin, salt);

      // Store both securely
      await _storage.write(key: _pinHashKey, value: hash);
      await _storage.write(key: _pinSaltKey, value: base64Encode(salt));

      if (kDebugMode) {
        debugPrint('🔐 [PinService] PIN saved securely');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [PinService] Failed to save PIN: $e');
        debugPrint('$stackTrace');
      }
      rethrow;
    }
  }

  /// Verify a PIN against the stored hash
  ///
  /// Returns true if PIN matches, false otherwise
  Future<bool> verifyPin(String pin) async {
    try {
      // Read stored hash and salt
      final storedHash = await _storage.read(key: _pinHashKey);
      final storedSaltBase64 = await _storage.read(key: _pinSaltKey);

      if (storedHash == null || storedSaltBase64 == null) {
        if (kDebugMode) {
          debugPrint('⚠️ [PinService] No PIN stored');
        }
        return false;
      }

      // Decode salt
      final salt = Uint8List.fromList(base64Decode(storedSaltBase64));

      // Hash provided PIN with same salt
      final computedHash = _hashPin(pin, salt);

      // Constant-time comparison to prevent timing attacks
      final result = _constantTimeCompare(storedHash, computedHash);

      if (kDebugMode) {
        debugPrint('🔐 [PinService] PIN verification: ${result ? "success" : "failed"}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PinService] PIN verification error: $e');
      }
      return false;
    }
  }

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Check if a PIN has been set up
  Future<bool> hasPinSetup() async {
    try {
      final hash = await _storage.read(key: _pinHashKey);
      final salt = await _storage.read(key: _pinSaltKey);
      return hash != null && salt != null && hash.isNotEmpty && salt.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PinService] Error checking PIN setup: $e');
      }
      return false;
    }
  }

  /// Clear the stored PIN
  ///
  /// Used when user disables app lock or during account logout
  Future<void> clearPin() async {
    try {
      await _storage.delete(key: _pinHashKey);
      await _storage.delete(key: _pinSaltKey);
      if (kDebugMode) {
        debugPrint('🧹 [PinService] PIN cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PinService] Failed to clear PIN: $e');
      }
      rethrow;
    }
  }

  /// Change PIN (requires current PIN verification first)
  ///
  /// Returns true if PIN was changed successfully
  Future<bool> changePin(String currentPin, String newPin) async {
    // Verify current PIN first
    final isValid = await verifyPin(currentPin);
    if (!isValid) {
      if (kDebugMode) {
        debugPrint('❌ [PinService] Current PIN verification failed');
      }
      return false;
    }

    // Save new PIN
    await savePin(newPin);
    return true;
  }
}
