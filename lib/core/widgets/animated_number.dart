import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated number widget with slide transition
/// 
/// When the value changes OR the animationKey changes, the previous number 
/// slides up and out, while the new number slides up from the bottom, creating 
/// a smooth odometer-like effect.
/// 
/// The animationKey should change whenever you want to force an animation,
/// such as when the period/date range changes, even if the value stays the same.
class AnimatedNumber extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final String Function(double)? formatter;
  final Duration duration;
  final Curve curve;
  final bool animateOnFirstLoad;
  final Object? animationKey; // Key that triggers animation when changed
  /// When false, value updates are shown immediately with no slide animation.
  final bool enableSlideAnimation;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.formatter,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.animateOnFirstLoad = false,
    this.animationKey,
    this.enableSlideAnimation = true,
  });

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  
  String _currentText = '';
  String _previousText = '';
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Set initial value
    _currentText = _formatValue(widget.value);
    _previousText = _currentText;

    // Optionally animate on first load
    if (widget.animateOnFirstLoad && widget.value != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerAnimation();
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final valueChanged = _hasValueChanged(oldWidget.value, widget.value);
    final keyChanged = oldWidget.animationKey != widget.animationKey;
    
    // Trigger animation if value OR animation key changed
    if (valueChanged || keyChanged) {
      // Preserve the current value as previous (don't reset to 0)
      _previousText = _currentText;
      _currentText = _formatValue(widget.value);
      
      // Schedule animation in next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerAnimation();
        }
      });
    }
  }

  /// Check if value has actually changed, handling edge cases
  bool _hasValueChanged(double oldValue, double newValue) {
    // Handle NaN
    if (oldValue.isNaN && newValue.isNaN) return false;
    if (oldValue.isNaN || newValue.isNaN) return true;
    
    // Handle infinity
    if (oldValue.isInfinite && newValue.isInfinite) {
      return oldValue != newValue; // Different signs
    }
    if (oldValue.isInfinite || newValue.isInfinite) return true;
    
    // Use epsilon comparison for floating point
    const epsilon = 1e-10;
    return (oldValue - newValue).abs() > epsilon;
  }

  void _triggerAnimation() {
    if (!mounted) return;
    
    // Stop any ongoing animation and reset
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.reset();
    
    // Update state to show both texts during animation
    setState(() {
      _isAnimating = true;
    });
    
    // Start animation
    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    if (widget.formatter != null) {
      return widget.formatter!(value);
    }
    
    // Handle special cases
    if (value.isNaN) return 'NaN';
    if (value.isInfinite) return value.isNegative ? '-∞' : '∞';
    
    // If it's a whole number, display without decimals
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    // Otherwise, format with 2 decimal places
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableSlideAnimation) {
      return Text(
        _currentText,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final fontSize = widget.style?.fontSize ?? 16.0;
    final lineHeight = fontSize * 1.2;
    final slideDistance = math.max(fontSize * 0.5, 20.0);

    return RepaintBoundary(
      child: ClipRect(
        child: SizedBox(
          height: lineHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.hardEdge,
            children: [
              if (_isAnimating && _previousText != _currentText)
                _AnimatedText(
                  key: ValueKey('prev_$_previousText'),
                  text: _previousText,
                  style: widget.style,
                  animation: _slideAnimation,
                  slideDistance: slideDistance,
                  isExiting: true,
                ),
              _AnimatedText(
                key: ValueKey('curr_$_currentText'),
                text: _currentText,
                style: widget.style,
                animation: _slideAnimation,
                slideDistance: slideDistance,
                isExiting: false,
                isAnimating: _isAnimating,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optimized animated text widget to reduce rebuilds
class _AnimatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Animation<double> animation;
  final double slideDistance;
  final bool isExiting;
  final bool isAnimating;

  const _AnimatedText({
    super.key,
    required this.text,
    this.style,
    required this.animation,
    required this.slideDistance,
    required this.isExiting,
    this.isAnimating = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAnimating && !isExiting) {
      // Static text when not animating
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final offset = isExiting
            ? -animation.value * slideDistance // Slide up and out
            : (1.0 - animation.value) * slideDistance; // Slide up from bottom

        return Transform.translate(
          offset: Offset(0, offset),
          child: Opacity(
            opacity: isExiting
                ? 1.0 - animation.value
                : animation.value,
            child: Text(
              text,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

/// Animated integer widget with slide transition
class AnimatedInteger extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final bool animateOnFirstLoad;
  final Object? animationKey;
  final bool enableSlideAnimation;

  const AnimatedInteger({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.animateOnFirstLoad = false,
    this.animationKey,
    this.enableSlideAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedNumber(
      value: value.toDouble(),
      style: style,
      formatter: (val) => val.toInt().toString(),
      duration: duration,
      curve: curve,
      animateOnFirstLoad: animateOnFirstLoad,
      animationKey: animationKey,
      enableSlideAnimation: enableSlideAnimation,
    );
  }
}
