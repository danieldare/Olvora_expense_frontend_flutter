import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// WhatsApp-style voice recording for Ora AI
///
/// Features:
/// - Single tap to start recording
/// - Pause/Resume support
/// - Real waveform visualization
/// - Recording timer
/// - Delete (cancel) and Send buttons
/// - Slide to cancel gesture
/// - Haptic feedback
/// - 60 second max recording

/// Simple mic button - triggers recording start
class OraVoiceMicButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onTap;

  const OraVoiceMicButton({
    required this.isProcessing,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic_none_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// Recording controls bar - WhatsApp-style with pause/resume
class OraRecordingBar extends StatefulWidget {
  final VoidCallback onCancel;
  final void Function(File) onSend;

  const OraRecordingBar({
    required this.onCancel,
    required this.onSend,
    super.key,
  });

  @override
  State<OraRecordingBar> createState() => _OraRecordingBarState();
}

class _OraRecordingBarState extends State<OraRecordingBar>
    with TickerProviderStateMixin {
  // Recorder controller from audio_waveforms
  late RecorderController _recorderController;

  // Recording state
  Timer? _durationTimer;
  Duration _duration = Duration.zero;
  bool _isPaused = false;
  String? _recordingPath;

  static const _maxDuration = Duration(seconds: 60);
  static const _minDuration = Duration(seconds: 1);

  // Pulse animation for recording indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Slide to cancel
  double _slideOffset = 0;
  static const _cancelThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initRecorder();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initRecorder() async {
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 128000;

    await _startRecording();
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();

    // Generate file path
    final appDir = await getApplicationDocumentsDirectory();
    final voiceDir = Directory('${appDir.path}/voice_recordings');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }
    _recordingPath = '${voiceDir.path}/${const Uuid().v4()}.m4a';

    try {
      await _recorderController.record(path: _recordingPath);
      _startDurationTimer();
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      _showRecordingError(e.toString());
      widget.onCancel();
    }
  }

  void _startDurationTimer() {
    _duration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          _duration += const Duration(milliseconds: 100);
        });

        if (_duration >= _maxDuration) {
          HapticFeedback.heavyImpact();
          _sendRecording();
        }
      }
    });
  }

  Future<void> _togglePause() async {
    HapticFeedback.lightImpact();

    if (_isPaused) {
      await _recorderController.record(path: _recordingPath);
      setState(() => _isPaused = false);
      _pulseController.repeat(reverse: true);
    } else {
      await _recorderController.pause();
      setState(() => _isPaused = true);
      _pulseController.stop();
    }
  }

  Future<void> _cancelRecording() async {
    HapticFeedback.lightImpact();
    _durationTimer?.cancel();

    try {
      await _recorderController.stop();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }

    // Delete file if exists
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting recording: $e');
      }
    }

    widget.onCancel();
  }

  Future<void> _sendRecording() async {
    _durationTimer?.cancel();

    if (_duration < _minDuration) {
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Recording too short'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      await _cancelRecording();
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      final path = await _recorderController.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          widget.onSend(file);
          return;
        }
      }
      widget.onCancel();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      widget.onCancel();
    }
  }

  void _showRecordingError(String error) {
    HapticFeedback.heavyImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording failed: $error'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _duration.inMinutes;
    final seconds = _duration.inSeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _slideOffset += details.delta.dx;
          if (_slideOffset > 0) _slideOffset = 0;
        });

        if (_slideOffset.abs() > _cancelThreshold) {
          _cancelRecording();
        }
      },
      onHorizontalDragEnd: (_) {
        if (_slideOffset.abs() < _cancelThreshold) {
          setState(() => _slideOffset = 0);
        }
      },
      child: Transform.translate(
        offset: Offset(_slideOffset, 0),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _isPaused
                ? AppTheme.warningColor.withValues(alpha: 0.08)
                : AppTheme.errorColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _isPaused
                  ? AppTheme.warningColor.withValues(alpha: 0.2)
                  : AppTheme.errorColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Delete/Cancel button
              _buildCancelButton(),

              // Slide hint or Waveform
              Expanded(
                child: _slideOffset.abs() > 20
                    ? _buildSlideHint()
                    : _buildWaveform(),
              ),

              // Pause/Resume button
              _buildPauseButton(),

              // Recording indicator + timer
              _buildRecordingIndicator(timeString),

              // Send button
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _cancelRecording,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.errorColor.withValues(alpha: 0.1),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.errorColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSlideHint() {
    return Opacity(
      opacity: min(1.0, _slideOffset.abs() / _cancelThreshold),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back,
            size: 16,
            color: AppTheme.errorColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            'Slide to cancel',
            style: AppFonts.textStyle(
              fontSize: 12,
              color: AppTheme.errorColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AudioWaveforms(
        recorderController: _recorderController,
        size: Size(double.infinity, 36),
        waveStyle: WaveStyle(
          waveColor: _isPaused ? AppTheme.warningColor : AppTheme.errorColor,
          extendWaveform: true,
          showMiddleLine: false,
          spacing: 4,
          waveThickness: 2.5,
          showDurationLabel: false,
        ),
        enableGesture: false,
      ),
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: _togglePause,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPaused
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.textSecondary.withValues(alpha: 0.1),
        ),
        child: Icon(
          _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: _isPaused ? AppTheme.primaryColor : AppTheme.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator(String timeString) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPaused
                      ? AppTheme.warningColor
                      : AppTheme.errorColor.withValues(alpha: _pulseAnimation.value),
                  boxShadow: _isPaused
                      ? null
                      : [
                          BoxShadow(
                            color: AppTheme.errorColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          // Timer
          Text(
            timeString,
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isPaused ? AppTheme.warningColor : AppTheme.errorColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendRecording,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
