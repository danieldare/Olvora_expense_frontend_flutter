import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/pre_app_colors.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
// TODO: Re-implement auth analytics
// import '../services/auth_analytics_service.dart';
import '../../../expenses/presentation/screens/expense_type_selection_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
// TODO: Re-implement account lifecycle providers
// import '../providers/account_lifecycle_providers.dart';
// import '../../domain/models/account_lifecycle_models.dart';
import '../../../../core/utils/app_logger.dart';

/// First Expense Onboarding
/// 
/// Guides new users to add their first expense.
/// Never shows empty dashboard first - always guides to action.
class FirstExpenseOnboarding extends ConsumerStatefulWidget {
  const FirstExpenseOnboarding({super.key});

  @override
  ConsumerState<FirstExpenseOnboarding> createState() => _FirstExpenseOnboardingState();
}

class _FirstExpenseOnboardingState extends ConsumerState<FirstExpenseOnboarding>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // CRITICAL: Check account deletion status on mount
    // If account is pending deletion, navigate immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAccountDeletionStatus();
      }
    });
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _cardSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Check account deletion status - STUB
  /// TODO: Re-implement account lifecycle check
  Future<void> _checkAccountDeletionStatus() async {
    // STUB: Account lifecycle check disabled
    // Always allow onboarding to proceed
    AppLogger.d('Account deletion check - STUB (always allowed)', tag: 'Onboarding');
  }

  void _addFirstExpense() {
    HapticFeedback.mediumImpact();
    // TODO: Re-implement analytics
    // AuthAnalyticsService.trackOnboardingCompleted();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseTypeSelectionScreen(
          isFirstExpense: true,
        ),
      ),
      (route) => false,
    );
  }

  void _skipToHome() {
    HapticFeedback.lightImpact();
    // TODO: Re-implement analytics
    // AuthAnalyticsService.trackOnboardingSkipped(step: 'first_expense');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Block back navigation - users should add expense or skip
      },
      child: Semantics(
        label: 'First Expense - Add your first expense to get started',
        child: Scaffold(
          body: SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(
                gradient: PreAppColors.authGradient,
              ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: Column(
                children: [
                  SizedBox(height: 24.scaledVertical(context)),
                  
                  // Skip button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _skipToHome,
                      child: Text(
                        'Skip for now',
                        style: AppFonts.textStyle(
                          fontSize: 14.scaledText(context),
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  
                  // Main content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration
                        AnimatedBuilder(
                          animation: _fadeController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Container(
                                width: 140.scaled(context),
                                height: 140.scaled(context),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Decorative circles
                                    Positioned(
                                      top: 15.scaled(context),
                                      left: 15.scaled(context),
                                      child: Container(
                                        width: 20.scaled(context),
                                        height: 20.scaled(context),
                                        decoration: BoxDecoration(
                                          color: PreAppColors.warningColor.withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 20.scaled(context),
                                      right: 10.scaled(context),
                                      child: Container(
                                        width: 14.scaled(context),
                                        height: 14.scaled(context),
                                        decoration: BoxDecoration(
                                          color: PreAppColors.successColor.withValues(alpha: 0.4),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    // Main icon
                                    Container(
                                      width: 80.scaled(context),
                                      height: 80.scaled(context),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            PreAppColors.warningColor,
                                            PreAppColors.warningColor.withValues(alpha: 0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24.scaled(context)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: PreAppColors.warningColor.withValues(alpha: 0.4),
                                            blurRadius: 20.scaled(context),
                                            offset: Offset(0, 8.scaled(context)),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.receipt_long_rounded,
                                        size: 40.scaled(context),
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 48.scaledVertical(context)),
                        
                        // Title
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
                                      "Let's add your",
                                      textAlign: TextAlign.center,
                                      style: AppFonts.textStyle(
                                        fontSize: 26.scaledText(context),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                        height: 1.2,
                                      ),
                                    ),
                                    Text(
                                      "first expense",
                                      textAlign: TextAlign.center,
                                      style: AppFonts.textStyle(
                                        fontSize: 26.scaledText(context),
                                        fontWeight: FontWeight.w700,
                                        color: PreAppColors.warningColor,
                                        letterSpacing: -0.3,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 16.scaledVertical(context)),
                        
                        // Subtitle
                        AnimatedBuilder(
                          animation: _slideController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value * 0.9,
                              child: Text(
                                'Start building your money story. It only takes a few seconds.',
                                textAlign: TextAlign.center,
                                style: AppFonts.textStyle(
                                  fontSize: 15.scaledText(context),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  height: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 48.scaledVertical(context)),
                        
                        // Feature preview cards (informational only - not clickable)
                        AnimatedBuilder(
                          animation: _slideController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _cardSlideAnimation.value),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _FeatureCard(
                                      icon: Icons.camera_alt_rounded,
                                      label: 'Scan Receipt',
                                    ),
                                    SizedBox(width: 12.scaled(context)),
                                    _FeatureCard(
                                      icon: Icons.edit_rounded,
                                      label: 'Manual Entry',
                                    ),
                                    SizedBox(width: 12.scaled(context)),
                                    _FeatureCard(
                                      icon: Icons.mic_rounded,
                                      label: 'Voice Input',
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
                  
                  // CTA Button
                  AnimatedBuilder(
                    animation: Listenable.merge([_slideController, _pulseController]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addFirstExpense,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PreAppColors.warningColor,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(vertical: 18.scaledVertical(context)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.scaled(context)),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, size: 22.scaled(context)),
                                  SizedBox(width: 8.scaled(context)),
                                  Text(
                                    'Add first expense',
                                    style: AppFonts.textStyle(
                                      fontSize: 17.scaledText(context),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 32.scaledVertical(context)),
                ],
              ),
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureCard({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive dimensions for all cards
    final cardWidth = 100.0.scaled(context);
    final cardHeight = 100.0.scaled(context);
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: EdgeInsets.all(12.scaled(context)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.scaled(context)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        // No shadow or elevation to make it look non-interactive
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28.scaled(context),
            color: Colors.white.withValues(alpha: 0.7),
          ),
          SizedBox(height: 8.scaled(context)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.textStyle(
              fontSize: 11.scaledText(context),
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}


