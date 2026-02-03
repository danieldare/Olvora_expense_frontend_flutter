import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric capability result
enum BiometricCapability {
  /// Device supports biometrics and user has enrolled
  available,
  /// Device supports biometrics but user hasn't enrolled
  notEnrolled,
  /// Device doesn't support biometrics
  notSupported,
  /// Biometrics are locked out (too many attempts)
  lockedOut,
  /// Permanent lockout requiring passcode
  permanentLockedOut,
}

/// Service for biometric authentication
///
/// Provides device capability detection and biometric authentication
/// using Face ID, Touch ID, or fingerprint depending on device
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  ///
  /// Returns the capability status
  Future<BiometricCapability> checkBiometricCapability() async {
    try {
      // Check if device supports biometrics
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        if (kDebugMode) {
          debugPrint('🔐 [Biometric] Device does not support biometrics');
        }
        return BiometricCapability.notSupported;
      }

      // Check available biometric types
      final availableBiometrics = await _auth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        if (kDebugMode) {
          debugPrint('🔐 [Biometric] No biometrics enrolled');
        }
        return BiometricCapability.notEnrolled;
      }

      if (kDebugMode) {
        debugPrint('🔐 [Biometric] Available: $availableBiometrics');
      }
      return BiometricCapability.available;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Biometric] Platform exception: ${e.code} - ${e.message}');
      }

      // Handle specific error codes
      switch (e.code) {
        case 'NotEnrolled':
          return BiometricCapability.notEnrolled;
        case 'LockedOut':
          return BiometricCapability.lockedOut;
        case 'PermanentlyLockedOut':
          return BiometricCapability.permanentLockedOut;
        case 'NotAvailable':
        default:
          return BiometricCapability.notSupported;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Biometric] Error checking capability: $e');
      }
      return BiometricCapability.notSupported;
    }
  }

  /// Check if biometrics are available and enrolled
  Future<bool> isBiometricAvailable() async {
    final capability = await checkBiometricCapability();
    return capability == BiometricCapability.available;
  }

  /// Get the type of biometric available (for UI display)
  Future<BiometricType?> getPrimaryBiometricType() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) return null;

      // Prefer Face ID over fingerprint
      if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricType.face;
      }
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      }
      if (availableBiometrics.contains(BiometricType.strong)) {
        return BiometricType.strong;
      }
      if (availableBiometrics.contains(BiometricType.weak)) {
        return BiometricType.weak;
      }

      return availableBiometrics.first;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Biometric] Error getting biometric type: $e');
      }
      return null;
    }
  }

  /// Get user-friendly name for biometric type
  String getBiometricTypeName(BiometricType? type) {
    if (type == null) return 'Biometrics';

    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Touch ID';
      case BiometricType.strong:
      case BiometricType.weak:
      case BiometricType.iris:
        return 'Biometrics';
    }
  }

  /// Authenticate using biometrics
  ///
  /// Returns true if authentication successful, false otherwise
  /// [reason] is the message shown to the user
  Future<bool> authenticate({
    String reason = 'Authenticate to unlock the app',
  }) async {
    try {
      final capability = await checkBiometricCapability();

      if (capability != BiometricCapability.available) {
        if (kDebugMode) {
          debugPrint('🔐 [Biometric] Cannot authenticate: $capability');
        }
        return false;
      }

      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Keep auth dialog if app goes to background
          biometricOnly: true, // Don't allow device passcode fallback
          useErrorDialogs: true, // Show system error dialogs
        ),
      );

      if (kDebugMode) {
        debugPrint('🔐 [Biometric] Authentication result: $result');
      }

      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Biometric] Authentication error: ${e.code} - ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Biometric] Authentication error: $e');
      }
      return false;
    }
  }

  /// Stop any ongoing authentication
  ///
  /// Call this when navigating away or when authentication should be cancelled
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Biometric] Error stopping authentication: $e');
      }
    }
  }
}
