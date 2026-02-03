import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/pre_app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import 'currency_selection_screen.dart';

/// Onboarding Screen for first-time users
///
/// 3-page intro carousel showcasing app features before signup.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.receipt_long_rounded,
      iconBackground: PreAppColors.warningColor,
      subtitleColor: null,
      title: 'Track Every Expense',
      subtitle: 'Effortlessly',
      description:
          'Snap receipts, use voice, or type manually. Your spending, captured in seconds.',
      decorationIcon1: Icons.camera_alt_rounded,
      decorationIcon2: Icons.mic_rounded,
    ),
    _OnboardingPageData(
      icon: Icons.insights_rounded,
      iconBackground: PreAppColors.primaryColor,
      subtitleColor: Colors.white, // High contrast for "Weekly" on purple gradient
      title: 'Smart Insights',
      subtitle: 'Weekly',
      description:
          'Understand your spending patterns with beautiful summaries, budgets, and AI-powered insights.',
      decorationIcon1: Icons.pie_chart_rounded,
      decorationIcon2: Icons.trending_up_rounded,
    ),
    _OnboardingPageData(
      icon: Icons.shield_rounded,
      iconBackground: PreAppColors.primaryLight, // Matches gradient violet for better blend
      subtitleColor: Colors.white, // High contrast for "Always" on purple gradient
      title: 'Secure & Synced',
      subtitle: 'Always',
      description:
          'Your data is encrypted, synced across devices, and fully deletable. You\'re in control.',
      decorationIcon1: Icons.sync_rounded,
      decorationIcon2: Icons.lock_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      HapticFeedback.mediumImpact();
      _navigateToCurrencySelection();
    }
  }

  void _navigateToCurrencySelection() async {
    // Note: Onboarding completion is marked in WelcomeScreen (last step)
    // to ensure all steps (currency, notifications) are completed first

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CurrencySelectionScreen(),
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
    final isLastPage = _currentPage == _pages.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Block back navigation during onboarding - users should complete the flow
        // or use the Skip button to proceed
      },
      child: Semantics(
        label: 'Onboarding - Step ${_currentPage + 1} of ${_pages.length}: ${_pages[_currentPage].title}',
        child: Scaffold(
          body: SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(gradient: PreAppColors.authGradient),
              child: SafeArea(
                child: Column(
                  children: [
              // Skip button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: 16.scaledVertical(context),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _navigateToCurrencySelection();
                          },
                          child: Text(
                            'Skip',
                            style: AppFonts.textStyle(
                              fontSize: 15.scaledText(context),
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(
                      data: _pages[index],
                      fadeAnimation: _fadeAnimation,
                      slideAnimation: _slideAnimation,
                    );
                  },
                ),
              ),

              // Bottom section
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  32.scaledVertical(context),
                ),
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          // Page indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _pages.length,
                              (index) => GestureDetector(
                                onTap: index < _currentPage
                                    ? () {
                                        HapticFeedback.selectionClick();
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeOutCubic,
                                        );
                                      }
                                    : null,
                                child: _PageIndicator(
                                  isActive: index == _currentPage,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.scaledVertical(context)),

                          // CTA Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PreAppColors.warningColor,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  vertical: 18.scaledVertical(context),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    14.scaled(context),
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isLastPage ? 'Get Started' : 'Continue',
                                style: AppFonts.textStyle(
                                  fontSize: 17.scaledText(context),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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

class _OnboardingPageData {
  final IconData icon;
  final Color iconBackground;
  /// When set, used for subtitle text for better contrast (e.g. white on gradient).
  final Color? subtitleColor;
  final String title;
  final String subtitle;
  final String description;
  final IconData decorationIcon1;
  final IconData decorationIcon2;

  const _OnboardingPageData({
    required this.icon,
    required this.iconBackground,
    this.subtitleColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.decorationIcon1,
    required this.decorationIcon2,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;

  const _OnboardingPage({
    required this.data,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          AnimatedBuilder(
            animation: fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: fadeAnimation.value,
                child: Container(
                  width: 160.scaled(context),
                  height: 160.scaled(context),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decoration icons
                      Positioned(
                        top: 18.scaled(context),
                        left: 18.scaled(context),
                        child: Container(
                          width: 32.scaled(context),
                          height: 32.scaled(context),
                          decoration: BoxDecoration(
                            color: data.iconBackground.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            data.decorationIcon1,
                            size: 16.scaled(context),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 22.scaled(context),
                        right: 14.scaled(context),
                        child: Container(
                          width: 28.scaled(context),
                          height: 28.scaled(context),
                          decoration: BoxDecoration(
                            color: data.iconBackground.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            data.decorationIcon2,
                            size: 14.scaled(context),
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      // Main icon
                      Container(
                        width: 88.scaled(context),
                        height: 88.scaled(context),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              data.iconBackground,
                              data.iconBackground.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28.scaled(context)),
                          boxShadow: [
                            BoxShadow(
                              color: data.iconBackground.withValues(alpha: 0.4),
                              blurRadius: 24.scaled(context),
                              offset: Offset(0, 10.scaled(context)),
                            ),
                          ],
                        ),
                        child: Icon(
                          data.icon,
                          size: 44.scaled(context),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 56.scaledVertical(context)),

          // Title
          AnimatedBuilder(
            animation: slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, slideAnimation.value),
                child: Opacity(
                  opacity: fadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: AppFonts.textStyle(
                          fontSize: 28.scaledText(context),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        data.subtitle,
                        textAlign: TextAlign.center,
                        style: AppFonts.textStyle(
                          fontSize: 28.scaledText(context),
                          fontWeight: FontWeight.w700,
                          color: data.subtitleColor ?? data.iconBackground,
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

          SizedBox(height: 20.scaledVertical(context)),

          // Description
          AnimatedBuilder(
            animation: fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: fadeAnimation.value * 0.9,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.scaled(context)),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: AppFonts.textStyle(
                      fontSize: 16.scaledText(context),
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.symmetric(horizontal: 4.scaled(context)),
      width: isActive ? 28.scaled(context) : 8.scaled(context),
      height: 8.scaled(context),
      decoration: BoxDecoration(
        color: isActive
            ? PreAppColors.warningColor
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4.scaled(context)),
      ),
    );
  }
}
