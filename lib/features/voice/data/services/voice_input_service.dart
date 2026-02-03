import 'dart:io' show Platform;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;

  /// Check microphone permission status without requesting
  Future<PermissionStatus> checkPermissionStatus() async {
    try {
      final status = await Permission.microphone.status;
      if (kDebugMode) {
        debugPrint('🎤 Permission status: $status');
        debugPrint('  - isGranted: ${status.isGranted}');
        debugPrint('  - isDenied: ${status.isDenied}');
        debugPrint('  - isPermanentlyDenied: ${status.isPermanentlyDenied}');
        debugPrint('  - isRestricted: ${status.isRestricted}');
        debugPrint('  - isLimited: ${status.isLimited}');
      }
      return status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking permission status: $e');
      }
      return PermissionStatus.denied;
    }
  }

  /// Check if microphone permission is permanently denied
  /// IMPORTANT: On iOS, the first time the permission is checked, it may return
  /// isPermanentlyDenied=true even though the user hasn't been prompted yet.
  /// This is a known iOS quirk. We handle this by also checking if it's "restricted"
  Future<bool> isPermissionPermanentlyDenied() async {
    try {
      final status = await checkPermissionStatus();

      // On iOS, if restricted (parental controls), treat as permanently denied
      if (status.isRestricted) {
        if (kDebugMode) {
          debugPrint('🚫 Permission is restricted (parental controls)');
        }
        return true;
      }

      // iOS quirk: On fresh install, isPermanentlyDenied can be true even though
      // user was never prompted. The real "permanently denied" state only happens
      // after the user has explicitly denied the permission dialog.
      // We'll rely on the actual request to determine true permanent denial.
      if (Platform.isIOS && status.isPermanentlyDenied) {
        if (kDebugMode) {
          debugPrint('⚠️  iOS reports permanently denied - may be first launch');
        }
        // Return false on iOS to allow the permission request to proceed
        // The request itself will show the dialog or fail if truly permanently denied
        return false;
      }

      return status.isPermanentlyDenied;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking permission status: $e');
      }
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> isPermissionGranted() async {
    try {
      final status = await checkPermissionStatus();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking permission status: $e');
      }
      return false;
    }
  }

  /// Request microphone permission (only call when user explicitly requests it)
  Future<PermissionStatus> requestPermission() async {
    try {
      if (kDebugMode) {
        debugPrint('🎤 Requesting microphone permission...');
      }
      final status = await Permission.microphone.request();
      if (kDebugMode) {
        debugPrint('🎤 Permission request result: $status');
        debugPrint('  - isGranted: ${status.isGranted}');
        debugPrint('  - isDenied: ${status.isDenied}');
        debugPrint('  - isPermanentlyDenied: ${status.isPermanentlyDenied}');
      }
      return status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error requesting microphone permission: $e');
      }
      return PermissionStatus.denied;
    }
  }

  /// Open app settings for iOS/Android
  /// This opens the app's settings page where user can enable microphone permission
  Future<bool> openSettings() async {
    try {
      // Use permission_handler's openAppSettings top-level function
      await openAppSettings();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error opening app settings: $e');
      }
      return false;
    }
  }

  /// Request permission with full flow including explanation dialog
  /// Returns true if permission granted, false otherwise
  /// Handles all states: granted, denied, permanently denied
  /// shouldShowExplanation callback should show explanation dialog and return true if user wants to continue
  Future<bool> requestPermissionWithExplanation({
    required Future<bool> Function() shouldShowExplanation,
    required Function() onPermanentlyDenied,
  }) async {
    try {
      // Check if already granted
      final isGranted = await isPermissionGranted();
      if (isGranted) {
        return true;
      }

      // Check if permanently denied
      final isPermanentlyDenied = await isPermissionPermanentlyDenied();
      if (isPermanentlyDenied) {
        onPermanentlyDenied();
        return false;
      }

      // Show explanation dialog first
      final shouldContinue = await shouldShowExplanation();
      if (!shouldContinue) {
        return false;
      }

      // Request permission
      final status = await requestPermission();

      // Check result
      if (status.isGranted) {
        // Re-initialize speech recognition now that permission is granted
        await initialize();
        return true;
      }

      // Check if it became permanently denied
      if (status.isPermanentlyDenied) {
        onPermanentlyDenied();
        return false;
      }

      // Permission denied but not permanently
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in permission flow: $e');
      }
      return false;
    }
  }

  /// Monitor permission status during recording (for mid-recording revocation)
  /// Call this periodically during active recording
  Future<bool> checkPermissionDuringRecording() async {
    try {
      final status = await checkPermissionStatus();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking permission during recording: $e');
      }
      return false;
    }
  }

  /// Initialize speech recognition (does NOT request permission)
  /// Only checks if permission is available and initializes the speech engine
  /// IMPORTANT: On Android, permission should be granted before calling this
  Future<bool> initialize() async {
    try {
      // Check permission status without requesting
      // We don't request here - that happens only when user taps the mic button
      try {
        final micPermission = await checkPermissionStatus();

        if (micPermission.isPermanentlyDenied) {
          if (kDebugMode) {
            debugPrint(
              'Microphone permission permanently denied. Please enable in settings.',
            );
          }
          _isAvailable = false;
          return false;
        }

        // On Android, we need permission to be granted for speech recognition to work
        // On iOS, the speech_to_text package handles permissions automatically
        if (micPermission.isDenied) {
          if (kDebugMode) {
            debugPrint(
              'Microphone permission denied. Will need to request before listening.',
            );
          }
          // Don't mark as unavailable yet - allow initialization to proceed
          // Permission will be checked again in startListening()
        }
      } catch (e) {
        // If permission_handler fails, continue anyway - speech_to_text will handle permissions
        if (kDebugMode) {
          debugPrint('Permission check failed (may need rebuild): $e');
        }
      }

      // Initialize speech recognition
      // Note: On Android, the speech_to_text package may still initialize even without permission
      // but will fail when trying to listen. We check permission explicitly in startListening()
      _isAvailable = await _speech.initialize(
        onError: (error) {
          if (kDebugMode) {
            debugPrint('Speech recognition error: $error');
          }
          _isAvailable = false;
        },
        onStatus: (status) {
          if (kDebugMode) {
            debugPrint('Speech recognition status: $status');
          }
        },
      );
      return _isAvailable;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize speech recognition: $e');
      }
      _isAvailable = false;
      return false;
    }
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isAvailable;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Start listening for speech input.
  /// Returns true if listening started, false otherwise (check onError for reason).
  /// IMPORTANT: On Android, ensure permission is granted before calling this.
  Future<bool> startListening({
    required Function(String text) onResult,
    Function()? onDone,
    Function(String error)? onError,
  }) async {
    try {
      final permissionStatus = await checkPermissionStatus();

      if (!permissionStatus.isGranted) {
        _isListening = false;
        if (permissionStatus.isPermanentlyDenied) {
          onError?.call(
            'Microphone permission is permanently denied. Please enable it in app settings.',
          );
        } else {
          onError?.call(
            'Microphone permission is required. Please grant permission to use voice input.',
          );
        }
        return false;
      }

      if (!_isAvailable) {
        await initialize();
      }

      if (!_isAvailable) {
        _isListening = false;
        onError?.call('Speech recognition not available');
        return false;
      }

      if (_isListening) {
        return true;
      }

      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _isListening = false;
            onResult(result.recognizedWords);
            onDone?.call();
          } else {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 10),
        localeId: 'en_US',
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
        ),
      );
      return true;
    } catch (e) {
      _isListening = false;
      final errorMessage =
          e.toString().contains('permission') ||
              e.toString().contains('Permission')
          ? 'Microphone permission is required. Please grant permission to use voice input.'
          : 'Failed to start listening: $e';
      onError?.call(errorMessage);
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error stopping speech recognition: $e');
      }
      _isListening = false;
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    try {
      if (_isListening) {
        await _speech.cancel();
        _isListening = false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error canceling speech recognition: $e');
      }
      _isListening = false;
    }
  }

  /// Dispose resources
  void dispose() {
    try {
      if (_isListening) {
        _speech.cancel();
      }
      _isListening = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error disposing speech recognition: $e');
      }
    }
  }
}
