import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Audio player widget for voice messages
class OraAudioPlayer extends StatefulWidget {
  final String audioPath;
  final bool isUser;

  const OraAudioPlayer({
    required this.audioPath,
    this.isUser = false,
    super.key,
  });

  @override
  State<OraAudioPlayer> createState() => _OraAudioPlayerState();
}

class _OraAudioPlayerState extends State<OraAudioPlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      setState(() => _isLoading = true);
      _errorMessage = null;

      final file = File(widget.audioPath);
      if (!file.existsSync()) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Audio file not found';
        });
        return;
      }

      final fileSize = file.lengthSync();
      if (fileSize == 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Audio file is empty';
        });
        return;
      }

      // Load audio file
      await _audioPlayer.setAudioSource(AudioSource.file(widget.audioPath));
      
      // Listen to duration changes
      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _duration = duration);
        }
      });

      // Listen to position changes
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering) {
              _isLoading = true;
            } else {
              _isLoading = false;
            }
          });
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _errorMessage = 'Unable to load audio';
        debugPrint('Error loading audio: $e');
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error toggling playback: $e');
    }
  }

  Future<void> _seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : AppTheme.primaryColor.withValues(alpha: 0.1);
    final iconColor = widget.isUser
        ? AppTheme.primaryColor
        : (isDark ? Colors.white : AppTheme.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: _errorMessage != null
          ? Text(
              _errorMessage!,
              style: AppFonts.textStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play/Pause button - smaller
                GestureDetector(
                  onTap: _isLoading ? null : _togglePlayPause,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                // Progress bar and time - compact
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar - thinner
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 4,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: _duration.inMilliseconds > 0
                              ? _position.inMilliseconds.toDouble()
                              : 0.0,
                          max: _duration.inMilliseconds > 0
                              ? _duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (value) {
                            _seek(Duration(milliseconds: value.toInt()));
                          },
                          activeColor: AppTheme.primaryColor,
                          inactiveColor:
                              AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      // Time display - single line, smaller
                      Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: AppFonts.textStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: iconColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
