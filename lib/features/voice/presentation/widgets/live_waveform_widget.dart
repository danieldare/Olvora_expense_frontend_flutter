import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Live waveform visualization widget
/// Shows real-time audio levels during recording
class LiveWaveformWidget extends StatefulWidget {
  final Stream<double> audioLevelStream;
  final bool isActive;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;

  const LiveWaveformWidget({
    super.key,
    required this.audioLevelStream,
    this.isActive = false,
    this.height = 60,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<LiveWaveformWidget> createState() => _LiveWaveformWidgetState();
}

class _LiveWaveformWidgetState extends State<LiveWaveformWidget>
    with SingleTickerProviderStateMixin {
  StreamSubscription<double>? _subscription;
  final List<double> _audioLevels = [];
  static const int _maxBars = 50; // Number of bars in waveform
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    if (widget.isActive) {
      _subscribeToAudioLevels();
    }
  }

  @override
  void didUpdateWidget(LiveWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _subscribeToAudioLevels();
      } else {
        _unsubscribeFromAudioLevels();
        _audioLevels.clear();
      }
    }
  }

  void _subscribeToAudioLevels() {
    _subscription?.cancel();
    _subscription = widget.audioLevelStream.listen(
      (level) {
        if (mounted) {
          setState(() {
            _audioLevels.add(level);
            // Keep only last _maxBars levels
            if (_audioLevels.length > _maxBars) {
              _audioLevels.removeAt(0);
            }
          });
        }
      },
      onError: (error) {
        debugPrint('Waveform audio level error: $error');
      },
    );
  }

  void _unsubscribeFromAudioLevels() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribeFromAudioLevels();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = widget.activeColor ??
        (isDark ? AppTheme.primaryColor : AppTheme.primaryColor);
    final inactiveColor = widget.inactiveColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[300]!);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomPaint(
            painter: _WaveformPainter(
              audioLevels: _audioLevels,
              isActive: widget.isActive,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              animationValue: _animationController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> audioLevels;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final double animationValue;

  _WaveformPainter({
    required this.audioLevels,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive || audioLevels.isEmpty) {
      // Show idle animation
      _drawIdleWaveform(canvas, size);
      return;
    }

    // Draw waveform bars
    final barWidth = size.width / 50; // 50 bars
    final spacing = barWidth * 0.3;
    final actualBarWidth = barWidth - spacing;

    for (int i = 0; i < 50; i++) {
      double level;
      if (i < audioLevels.length) {
        // Use actual audio level
        level = audioLevels[audioLevels.length - 1 - i];
      } else {
        // Generate smooth idle animation for empty slots
        level = 0.1 + 0.1 * math.sin((animationValue * 2 * math.pi) + (i * 0.2));
      }

      // Normalize and clamp level
      level = math.min(1.0, math.max(0.05, level));
      
      // Calculate bar height
      final barHeight = size.height * level * 0.8; // Use 80% of height
      final x = i * barWidth + spacing / 2;
      final y = (size.height - barHeight) / 2;

      // Color based on level
      Color barColor;
      if (level > 0.7) {
        // High level - red (clipping warning)
        barColor = Colors.red.withOpacity(0.8);
      } else if (level > 0.4) {
        // Medium level - green (good)
        barColor = activeColor;
      } else {
        // Low level - dimmed
        barColor = activeColor.withOpacity(0.5);
      }

      // Draw bar with rounded top
      final paint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, actualBarWidth, barHeight),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  void _drawIdleWaveform(Canvas canvas, Size size) {
    final barWidth = size.width / 50;
    final spacing = barWidth * 0.3;
    final actualBarWidth = barWidth - spacing;

    for (int i = 0; i < 50; i++) {
      // Smooth idle animation
      final level = 0.1 + 0.1 * math.sin((animationValue * 2 * math.pi) + (i * 0.2));
      final barHeight = size.height * level * 0.6;
      final x = i * barWidth + spacing / 2;
      final y = (size.height - barHeight) / 2;

      final paint = Paint()
        ..color = inactiveColor.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, actualBarWidth, barHeight),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.audioLevels.length != audioLevels.length ||
        oldDelegate.isActive != isActive ||
        oldDelegate.animationValue != animationValue;
  }
}
