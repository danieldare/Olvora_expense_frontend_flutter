import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// World-Class Raw Audio Recording Service
/// 
/// Features:
/// - Raw PCM audio recording using Android AudioRecord (via platform channel)
/// - High-quality audio: 48kHz preferred, 16kHz minimum
/// - PCM 16-bit, Mono channel
/// - Manual start/stop (NO auto-stop on silence)
/// - Real-time audio level streaming for waveform visualization
/// - WAV file output
/// - Offline-first storage
/// - Audio processing disabled (no noise suppression, echo cancel, AGC)
class RawAudioRecorderService {
  static const String _channelName = 'com.olvora/audio_record';
  static const String _eventChannelName = 'com.olvora/audio_record/stream';
  
  final MethodChannel _methodChannel = const MethodChannel(_channelName);
  final EventChannel _eventChannel = const EventChannel(_eventChannelName);
  
  StreamSubscription<dynamic>? _eventSubscription;
  final _audioLevelController = StreamController<double>.broadcast();
  final _recordingCompleteController = StreamController<RecordingResult>.broadcast();
  
  bool _isRecording = false;
  String? _currentRecordingPath;
  final List<double> _audioLevels = []; // Track levels for average calculation

  /// Stream of real-time audio levels (0.0 - 1.0) for waveform visualization
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  /// Stream of recording completion events
  Stream<RecordingResult> get recordingCompleteStream => _recordingCompleteController.stream;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording file path (if recording)
  String? get currentRecordingPath => _currentRecordingPath;

  bool _isInitialized = false;

  /// Initialize the service and set up event listeners (lazy initialization)
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    try {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (event) {
          if (event is Map) {
            final type = event['type'] as String?;
            
            if (type == 'audioLevel') {
              final level = (event['level'] as num?)?.toDouble() ?? 0.0;
              _audioLevels.add(level);
              _audioLevelController.add(level);
            } else if (type == 'recordingComplete') {
              final success = event['success'] as bool? ?? false;
              final filePath = event['filePath'] as String?;
              final duration = event['duration'] as int?;
              final error = event['error'] as String?;
              
              _isRecording = false;
              _currentRecordingPath = null;
              
              // Calculate average audio level
              final averageLevel = _audioLevels.isNotEmpty
                  ? _audioLevels.reduce((a, b) => a + b) / _audioLevels.length
                  : null;
              _audioLevels.clear();
              
              _recordingCompleteController.add(
                RecordingResult(
                  success: success,
                  filePath: filePath,
                  durationMs: duration,
                  error: error,
                  averageAudioLevel: averageLevel,
                ),
              );
            }
          }
        },
        onError: (error) {
          debugPrint('Audio recording event error: $error');
          // Don't throw - just log and continue
          // The error might be transient (e.g., EventChannel not ready yet)
        },
        cancelOnError: false, // Don't cancel on error
      );
      _isInitialized = true;
      debugPrint('Audio recording service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize audio recording event stream: $e');
      // Don't throw - allow the service to be used even if event stream fails
      // The app can still record audio, just without live waveform
    }
  }

  /// Public initialize method (for backward compatibility)
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  /// Start recording audio
  /// Returns the file path where audio will be saved
  Future<String> startRecording() async {
    if (_isRecording) {
      throw StateError('Recording is already in progress');
    }

    // Ensure event stream is initialized before starting recording
    await _ensureInitialized();

    // Get app documents directory for offline storage
    final appDir = await getApplicationDocumentsDirectory();
    final voiceDir = Directory('${appDir.path}/voice_recordings');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }

    // Generate unique file name
    final fileName = '${const Uuid().v4()}.wav';
    final filePath = '${voiceDir.path}/$fileName';

    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'startRecording',
        {'outputPath': filePath},
      );

      if (result == null || result['success'] != true) {
        throw Exception('Failed to start recording: ${result?['error']}');
      }

      _isRecording = true;
      _currentRecordingPath = filePath;
      _audioLevels.clear();

      debugPrint('Recording started: $filePath');
      return filePath;
    } on PlatformException catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      throw Exception('Platform error: ${e.message}');
    }
  }

  /// Stop recording manually
  /// User controls when to stop - NO auto-stop on silence
  Future<void> stopRecording() async {
    if (!_isRecording) {
      throw StateError('No recording in progress');
    }

    try {
      await _methodChannel.invokeMethod('stopRecording');
      debugPrint('Stop recording requested');
      // Note: _isRecording will be set to false when we receive recordingComplete event
    } on PlatformException catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      throw Exception('Platform error: ${e.message}');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isRecording) {
      try {
        await stopRecording();
      } catch (e) {
        debugPrint('Error stopping recording during dispose: $e');
      }
    }

    await _eventSubscription?.cancel();
    await _audioLevelController.close();
    await _recordingCompleteController.close();
    
    try {
      await _methodChannel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('Error disposing audio recorder: $e');
    }
  }
}

/// Result of a completed recording
class RecordingResult {
  final bool success;
  final String? filePath;
  final int? durationMs;
  final String? error;
  final double? averageAudioLevel;

  const RecordingResult({
    required this.success,
    this.filePath,
    this.durationMs,
    this.error,
    this.averageAudioLevel,
  });

  /// Check if recording was too short
  bool get isTooShort => error?.contains('too short') ?? false;

  /// Check if recording has valid audio
  bool get hasValidAudio => success && filePath != null && durationMs != null;
}
