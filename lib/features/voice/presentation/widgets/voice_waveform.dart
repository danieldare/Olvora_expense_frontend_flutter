import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';

/// Animated waveform visualization for voice input
class VoiceWaveform extends StatefulWidget {
  final bool isActive;
  final double? audioLevel; // 0.0 to 1.0

  const VoiceWaveform({
    super.key,
    this.isActive = false,
    this.audioLevel,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      20,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + (index * 50)),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      for (var controller in _controllers) {
        controller.repeat(reverse: true);
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      for (var controller in _controllers) {
        controller.stop();
        controller.reset();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              // Use audio level if available, otherwise use animation
              final heightMultiplier = widget.audioLevel != null
                  ? 0.3 + (widget.audioLevel! * 0.7)
                  : _animations[index].value;

              // Create wave pattern with varying heights
              final baseHeight = 4.0;
              final maxHeight = 40.0;
              final height = baseHeight +
                  (maxHeight - baseHeight) *
                      heightMultiplier *
                      (0.5 + 0.5 * math.sin(index * 0.5));

              return Container(
                width: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.accentColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
