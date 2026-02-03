import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Premium voice input button with multiple animation layers
class VoiceInputButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onTap;

  const VoiceInputButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Ripple animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeOut,
      ),
    );

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = 88.0;
    final iconSize = 40.0;

    return GestureDetector(
      onTap: widget.isProcessing ? null : widget.onTap,
      child: SizedBox(
        width: buttonSize * 1.8,
        height: buttonSize * 1.8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect (only when listening)
            if (widget.isListening)
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    width: buttonSize * (1.0 + _rippleAnimation.value * 0.6),
                    height: buttonSize * (1.0 + _rippleAnimation.value * 0.6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.errorColor.withOpacity(
                          0.3 * (1 - _rippleAnimation.value),
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            // Pulse ring
            if (widget.isListening)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: buttonSize * _pulseAnimation.value,
                    height: buttonSize * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.errorColor.withOpacity(0.2),
                          AppTheme.errorColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            // Main button
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isListening ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _getGradientColors(),
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getShadowColor().withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: _getShadowColor().withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: widget.isProcessing
                        ? Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            widget.isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            size: iconSize,
                            color: Colors.white,
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (widget.isListening) {
      return [
        AppTheme.errorColor,
        AppTheme.errorColor.withOpacity(0.85),
      ];
    } else if (widget.isProcessing) {
      return [
        Colors.grey[500]!,
        Colors.grey[600]!,
      ];
    } else {
      return [
        AppTheme.primaryColor,
        AppTheme.accentColor,
      ];
    }
  }

  Color _getShadowColor() {
    if (widget.isListening) {
      return AppTheme.errorColor;
    } else if (widget.isProcessing) {
      return Colors.grey[500]!;
    } else {
      return AppTheme.primaryColor;
    }
  }
}
