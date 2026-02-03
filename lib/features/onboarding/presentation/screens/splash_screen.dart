import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/wallet_app_icon.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/pre_app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
// TODO: Re-implement analytics service
// import '../../../auth/presentation/services/auth_analytics_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late AnimationController _breathController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerPosition;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _gradientAnimation;
  late Animation<double> _particleAnimation;
  late AnimationController _exitController;
  late Animation<double> _exitSlideAnimation;
  late Animation<double> _exitFadeAnimation;

  DateTime? _splashStartTime;

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();

    // Icon fade and scale animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Shimmer effect for icon
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Pulse animation for loading indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Slide animation for text
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    // Glow animation for logo
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Gradient animation
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 25000),
    )..repeat();

    // Breath animation for subtle movement
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    // Exit animation controller (for slide up before navigation)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Configure animations with refined curves
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const ElasticOutCurve(0.5),
      ),
    );

    _shimmerPosition = Tween<double>(begin: -1.8, end: 2.8).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Cubic(0.2, 0.0, 0.2, 1.0),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );


    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );


    // Exit animations (slide up and fade)
    _exitSlideAnimation = Tween<double>(begin: 0.0, end: -1.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations with refined stagger
    _fadeController.forward();
    _scaleController.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _slideController.forward();
      }
    });

    // Navigation is now handled by AppRoot via authNavigationProvider
    // SplashScreen is purely presentational - no auth checks here
    // This prevents race conditions with AppRoot._checkAuthAfterFirebaseInit()
  }

  // Removed _triggerAuthCheck() - auth checking is now handled exclusively by AppRoot
  // This prevents race conditions and duplicate auth checks

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _gradientController.dispose();
    _particleController.dispose();
    _breathController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Navigation is now handled by AuthNavigationCoordinator in AppRoot.
    // This screen only triggers the auth check and displays the splash UI.
    // The coordinator watches auth state changes and decides which screen to show.

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Gradient background - fixed brand gradient (not affected by theme)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: PreAppColors.walletGradient.length >= 2
                      ? PreAppColors.walletGradient
                      : [PreAppColors.primaryColor, PreAppColors.primaryColor],
                ),
              ),
            ),
            // Floating particles overlay (at top)
            _buildAnimatedBackground(),
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Spacer to push content to center
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _exitController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              MediaQuery.of(context).size.height *
                                  _exitSlideAnimation.value *
                                  0.3, // Slide up on exit
                            ),
                            child: Opacity(
                              opacity: _exitFadeAnimation.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Logo with animations
                                  _buildLogo(),
                                  SizedBox(height: 32),
                                  // Brand name matching auth screen style
                                  _buildBrandName(),
                                  // Expense text matching auth screen style (no spacing between)
                                  _buildExpenseText(),
                                  SizedBox(height: 12),
                                  // Tagline
                                  _buildTagline(),
                                  SizedBox(height: 60),
                                  // Loading indicator
                                  _buildLoadingIndicator(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Finance quote at bottom
                  _buildFinanceQuote(),
                  SizedBox(height: 24),
                  // Production info (version, copyright)
                  _buildProductionInfo(),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeController,
        _scaleController,
        _shimmerController,
      ]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: WalletAppIcon(
              size: AppSpacing.authLogoSize,
              iconSize: AppSpacing.authLogoIconSize,
              shimmerController: _shimmerController,
              shimmerPosition: _shimmerPosition,
              primaryColor: PreAppColors.primaryColor,
              purpleLight: PreAppColors.primaryLight,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandName() {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _textFadeAnimation.value,
            child: Text(
              'OLVORA',
              textAlign: TextAlign.center,
              style:
                  AppFonts.textStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                    height: 1.0,
                  ).copyWith(
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpenseText() {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.8),
          child: Opacity(
            opacity: _textFadeAnimation.value,
            child: Text(
              'expense',
              textAlign: TextAlign.center,
              style:
                  AppFonts.textStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: PreAppColors.warningColor,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ).copyWith(
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.7),
          child: Opacity(
            opacity: _textFadeAnimation.value * 0.8,
            child: Text(
              'Making expense tracking a lifestyle.',
              textAlign: TextAlign.center,
              style:
                  AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.0,
                    height: 1.7,
                  ).copyWith(
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinanceQuote() {
    // Inspirational finance quotes
    const quotes = [
      "Every dollar saved is a dollar earned.",
      "Budget your money, or your money will budget you.",
      "Wealth is not about having money, it's about managing it wisely.",
      "Small expenses add up to big savings.",
      "Track your expenses, control your future.",
      "Financial freedom starts with awareness.",
    ];

    // Use a simple hash of splash start time to pick a quote
    final quoteIndex =
        (_splashStartTime?.millisecondsSinceEpoch ?? 0) % quotes.length;

    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Opacity(
          opacity: _textFadeAnimation.value * 0.7,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              quotes[quoteIndex],
              textAlign: TextAlign.center,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 0.5,
                height: 1.5,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductionInfo() {
    final currentYear = DateTime.now().year;
    const version = '1.0.0';
    const buildNumber = '1';
    const appName = 'Olvora';

    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Opacity(
          opacity: _textFadeAnimation.value * 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App name and version
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appName,
                    style: AppFonts.textStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    ' • ',
                    style: AppFonts.textStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  Text(
                    'v$version',
                    style: AppFonts.textStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (buildNumber != '1') ...[
                    Text(
                      ' ($buildNumber)',
                      style: AppFonts.textStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 6),
              // Copyright
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '© $currentYear ',
                    style: AppFonts.textStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Olvora',
                    style: AppFonts.textStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    '. All rights reserved.',
                    style: AppFonts.textStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  PreAppColors.primaryColor.withValues(alpha: 0.15),
                  PreAppColors.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: PreAppColors.primaryColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: PreAppColors.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: LoadingSpinnerVariants.white(size: 30, strokeWidth: 3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeController, _particleController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _EnhancedParticlePainter(
            progress: _fadeAnimation.value,
            time: _particleAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _EnhancedParticlePainter extends CustomPainter {
  final double progress;
  final double time;

  _EnhancedParticlePainter({required this.progress, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.2) return;

    final particleCount = 12;
    // Increased alpha for better visibility while still blending with purple gradient
    final baseAlpha = (0.25 * (progress - 0.2) / 0.8).clamp(0.0, 0.25);

    for (int i = 0; i < particleCount; i++) {
      final seed = i * 1000;
      final random = math.Random(seed);

      // Create floating particles with movement
      final baseX = size.width * (0.05 + random.nextDouble() * 0.9);
      final baseY = size.height * (0.05 + random.nextDouble() * 0.9);

      // Animate particles with sine/cosine waves
      final offsetX = math.sin(time * 2 * math.pi + seed * 0.01) * 40;
      final offsetY = math.cos(time * 2 * math.pi + seed * 0.01) * 40;

      final x = baseX + offsetX;
      final y = baseY + offsetY;

      // Vary particle sizes (slightly larger for better visibility)
      final radius = 2.0 + random.nextDouble() * 5;

      // Use white/light colors that blend with purple gradient but are more visible
      final particleColor = i % 3 == 0
          ? Colors.white.withValues(
              alpha: baseAlpha * 0.9,
            ) // White particles - more visible
          : i % 3 == 1
          ? const Color(0xFF8B7AFF).withValues(
              alpha: baseAlpha * 1.2,
            ) // Light purple - brighter
          : Colors.white.withValues(
              alpha: baseAlpha * 0.7,
            ); // White variant for contrast

      // Create gradient paint for particles
      final paint = Paint()
        ..shader =
            RadialGradient(
              colors: [particleColor, particleColor.withValues(alpha: 0.0)],
            ).createShader(
              Rect.fromCircle(center: Offset(x, y), radius: radius * 3),
            )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Add more visible glow that blends with purple background
      final glowPaint = Paint()
        ..color = particleColor.withValues(alpha: baseAlpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.time != time;
  }
}
