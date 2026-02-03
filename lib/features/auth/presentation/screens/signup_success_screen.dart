import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/pre_app_colors.dart';
import 'first_expense_onboarding.dart';

/// Signup Success Screen
/// 
/// Quick celebration after successful signup.
/// Immediately transitions to onboarding flow.
class SignupSuccessScreen extends ConsumerStatefulWidget {
  const SignupSuccessScreen({super.key});

  @override
  ConsumerState<SignupSuccessScreen> createState() => _SignupSuccessScreenState();
}

class _SignupSuccessScreenState extends ConsumerState<SignupSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  
  late Animation<double> _checkAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: Curves.elasticOut,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );
    
    _textSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        HapticFeedback.heavyImpact(); // Celebrate with strong haptic
        _checkController.forward();
        _confettiController.forward();
      }
    });
    
    // Auto-navigate to onboarding after celebration
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateToOnboarding();
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            const FirstExpenseOnboarding(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Block back navigation - this is a celebration screen
      },
      child: Semantics(
        label: 'Success! Your account has been created. Starting your journey now.',
        child: Scaffold(
          body: SizedBox.expand(
            child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: PreAppColors.authGradient,
                ),
              ),
              // Confetti particles
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      animation: _confettiController,
                      screenSize: MediaQuery.of(context).size,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              // Main content
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success checkmark
                    AnimatedBuilder(
                      animation: Listenable.merge([_scaleController, _checkController]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: PreAppColors.successColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: PreAppColors.successColor.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform.scale(
                                scale: _checkAnimation.value,
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 40),

                    // Success text
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Column(
                              children: [
                                Text(
                                  "You're all set!",
                                  textAlign: TextAlign.center,
                                  style: AppFonts.textStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Let's start tracking.",
                                  textAlign: TextAlign.center,
                                  style: AppFonts.textStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 60),

                    // Loading indicator (subtle)
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value * 0.6,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// Custom painter for confetti celebration effect
class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final Size screenSize;
  final List<_ConfettiParticle> _particles;

  _ConfettiPainter({
    required this.animation,
    required this.screenSize,
  }) : _particles = List.generate(
          50,
          (index) => _ConfettiParticle(
            random: Random(index),
            screenSize: screenSize,
          ),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;

    for (final particle in _particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: (1 - progress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final x = particle.startX + particle.horizontalVelocity * progress * 300;
      final y = particle.startY + particle.verticalVelocity * progress * screenSize.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * particle.rotationSpeed * 10);

      // Draw different shapes
      if (particle.shapeType == 0) {
        // Rectangle
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.6),
          paint,
        );
      } else if (particle.shapeType == 1) {
        // Circle
        canvas.drawCircle(Offset.zero, particle.size * 0.4, paint);
      } else {
        // Diamond
        final path = Path()
          ..moveTo(0, -particle.size * 0.5)
          ..lineTo(particle.size * 0.3, 0)
          ..lineTo(0, particle.size * 0.5)
          ..lineTo(-particle.size * 0.3, 0)
          ..close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}

/// Individual confetti particle data
class _ConfettiParticle {
  final double startX;
  final double startY;
  final double horizontalVelocity;
  final double verticalVelocity;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;
  final int shapeType;

  _ConfettiParticle({
    required Random random,
    required Size screenSize,
  })  : startX = random.nextDouble() * screenSize.width,
        startY = -20 - random.nextDouble() * 100,
        horizontalVelocity = (random.nextDouble() - 0.5) * 2,
        verticalVelocity = 0.5 + random.nextDouble() * 0.8,
        rotation = random.nextDouble() * 3.14159 * 2,
        rotationSpeed = (random.nextDouble() - 0.5) * 2,
        size = 8 + random.nextDouble() * 8,
        color = _confettiColors[random.nextInt(_confettiColors.length)],
        shapeType = random.nextInt(3);

  static const List<Color> _confettiColors = [
    Color(0xFFFFC000), // Gold/Yellow (warningColor)
    Color(0xFF10B981), // Green (successColor)
    Color(0xFF8B5CF6), // Purple (primaryColor)
    Color(0xFFFF6B6B), // Coral red
    Color(0xFF4ECDC4), // Teal
    Color(0xFFFFE66D), // Bright yellow
  ];
}
