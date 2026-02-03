import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/wallet_app_icon.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/pre_app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/onboarding_provider.dart';
// TODO: Re-implement auth analytics
// import '../services/auth_analytics_service.dart';
import 'auth_screen.dart';

/// Welcome Screen - Value Proposition First
///
/// Shows the value of the app BEFORE asking for signup.
/// "Your money deserves to be remembered."
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _shimmerPosition;
  late Animation<double> _pulseAnimation;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();

    // TODO: Re-implement analytics
    // AuthAnalyticsService.trackSignupScreenViewed();

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _shimmerPosition = Tween<double>(begin: -1.8, end: 2.8).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToAuth({required bool isSignIn}) async {
    HapticFeedback.lightImpact();

    // Mark onboarding as completed - this is the last step before auth
    await ref.read(markOnboardingCompletedProvider)();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AuthScreen(isSignIn: isSignIn),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
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
        // Block back navigation - users should sign in or create account
      },
      child: Semantics(
        label: 'Welcome to Olvora - Create your account or sign in',
        child: Scaffold(
          body: SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(gradient: PreAppColors.authGradient),
              child: SafeArea(
                child: Column(
                  children: [
                    // Main content - centered
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            AnimatedBuilder(
                              animation: _fadeController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: WalletAppIcon(
                                    size: AppSpacing.authLogoSize,
                                    iconSize: AppSpacing.authLogoIconSize,
                                    shimmerController: _shimmerController,
                                    shimmerPosition: _shimmerPosition,
                                    primaryColor: PreAppColors.primaryColor,
                                    purpleLight: const Color(0xFF8B7AFF),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 48),

                            // Headline - Value proposition
                            AnimatedBuilder(
                              animation: _slideController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _slideAnimation.value),
                                  child: Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: Column(
                                      children: [
                                        Text(
                                          'Your money deserves',
                                          textAlign: TextAlign.center,
                                          style: AppFonts.textStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                            height: 1.2,
                                          ),
                                        ),
                                        Text(
                                          'to be remembered.',
                                          textAlign: TextAlign.center,
                                          style: AppFonts.textStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: PreAppColors.warningColor,
                                            letterSpacing: -0.5,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 16),

                            // Subtext
                            AnimatedBuilder(
                              animation: _slideController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    _slideAnimation.value * 0.7,
                                  ),
                                  child: Opacity(
                                    opacity: _fadeAnimation.value * 0.9,
                                    child: Text(
                                      'Create a free account to keep your expenses safe, synced, and secure.',
                                      textAlign: TextAlign.center,
                                      style: AppFonts.textStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 48),

                            // CTA Buttons
                            AnimatedBuilder(
                              animation: _slideController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _buttonFadeAnimation.value,
                                  child: Column(
                                    children: [
                                      // Primary CTA - Create free account
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseAnimation.value,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  // TODO: Re-implement analytics
                                                  // AuthAnalyticsService.trackSignupStarted(method: 'cta_button');
                                                  _navigateToAuth(
                                                    isSignIn: false,
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      PreAppColors.warningColor,
                                                  foregroundColor: Colors.black,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 18,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: Text(
                                                  'Create free account',
                                                  style: AppFonts.textStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 16),

                                      // Secondary CTA - Sign in
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _navigateToAuth(isSignIn: true),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.4,
                                              ),
                                              width: 1.5,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Text(
                                            'Sign in',
                                            style: AppFonts.textStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom - Trust signals
                    AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _buttonFadeAnimation.value * 0.7,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.screenHorizontal,
                              0,
                              AppSpacing.screenHorizontal,
                              32,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _TrustBadge(
                                  icon: Icons.lock_outline_rounded,
                                  label: 'Encrypted',
                                ),
                                SizedBox(width: 24),
                                _TrustBadge(
                                  icon: Icons.shield_outlined,
                                  label: 'Private',
                                ),
                                SizedBox(width: 24),
                                _TrustBadge(
                                  icon: Icons.delete_outline_rounded,
                                  label: 'Deletable',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.7)),
        SizedBox(height: 4),
        Text(
          label,
          style: AppFonts.textStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
