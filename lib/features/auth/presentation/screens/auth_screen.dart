import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/wallet_app_icon.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/pre_app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/utils/email_validator.dart';
import '../../../../core/utils/password_validator.dart';
import '../providers/auth_providers.dart';
import '../state/auth_state.dart';

/// Unified Auth Screen - Frictionless Signup/Signin
///
/// Features:
/// - OAuth-first (Google, Apple)
/// - Email as fallback
/// - Trust signals prominently displayed
/// - No unnecessary fields
/// - Under 30 seconds to complete
class AuthScreen extends ConsumerStatefulWidget {
  final bool isSignIn;
  final String? autoTriggerOAuth; // 'google' or 'apple' to auto-trigger OAuth
  final String? prefillEmail; // Pre-fill email field (for start afresh flow)

  const AuthScreen({
    super.key,
    this.isSignIn = false,
    this.autoTriggerOAuth,
    this.prefillEmail,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _showEmailForm = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerPosition;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _shimmerPosition = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Pre-fill email if provided (for start afresh flow)
    if (widget.prefillEmail != null && widget.prefillEmail!.isNotEmpty) {
      _emailController.text = widget.prefillEmail!;
      // Auto-show email form if email is pre-filled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showEmailForm = true;
          });
        }
      });
    }

    // Auto-trigger OAuth if specified (for start afresh flow)
    if (widget.autoTriggerOAuth != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.autoTriggerOAuth == 'google') {
          _handleGoogleAuth();
        } else if (mounted && widget.autoTriggerOAuth == 'apple') {
          _handleAppleAuth();
        }
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleAuth() async {
    if (_isGoogleLoading || _isAppleLoading || _isLoading) return;

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.loginWithGoogle();
    } catch (e) {
      _handleError('google', e);
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleAppleAuth() async {
    if (_isGoogleLoading || _isAppleLoading || _isLoading) return;

    setState(() {
      _isAppleLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.loginWithApple();
    } catch (e) {
      _handleError('apple', e);
    } finally {
      if (mounted) {
        setState(() => _isAppleLoading = false);
      }
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);

      if (widget.isSignIn) {
        await authNotifier.loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Parse name for registration (format: "FirstName LastName" or just "Name")
        final nameParts = _nameController.text.trim().split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : null;
        final lastName = nameParts.length > 1
            ? nameParts.sublist(1).join(' ')
            : null;

        await authNotifier.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          firstName: firstName,
          lastName: lastName,
        );
      }
    } catch (e) {
      _handleError('email', e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleError(String method, dynamic error) {
    // Errors are handled by AuthStateError from the notifier
    // This method is kept for backwards compatibility but errors
    // should come from authState, not from exceptions
    if (mounted) {
      setState(() {
        _errorMessage = null; // Clear local error, rely on AuthStateError
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Navigation is handled by authNavigationProvider in AppRoot
    // This screen only handles UI and calling auth methods

    final isLoading =
        authState is AuthStateAuthenticating ||
        authState is AuthStateEstablishingSession ||
        _isLoading;
    final isAnyOAuthLoading = _isGoogleLoading || _isAppleLoading;
    // Only the tapped button shows loading; others are disabled via onPressed
    final isGoogleAuthInProgress = _isGoogleLoading;
    final isAppleAuthInProgress = _isAppleLoading;

    // Get error message from auth state if available
    final stateErrorMessage = authState is AuthStateError
        ? authState.message
        : null;
    final displayErrorMessage = stateErrorMessage ?? _errorMessage;

    return PopScope(
      canPop: false, // Prevent back navigation - this is a root screen
      child: Scaffold(
        body: SizedBox.expand(
          child: Container(
            decoration: BoxDecoration(gradient: PreAppColors.authGradient),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.spacingLarge,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Center(
                          child: WalletAppIcon(
                            size: AppSpacing.authLogoSize,
                            iconSize: AppSpacing.authLogoIconSize,
                            shimmerController: _shimmerController,
                            shimmerPosition: _shimmerPosition,
                            primaryColor: PreAppColors.primaryColor,
                            purpleLight: PreAppColors.primaryLight,
                          ),
                        ),

                        SizedBox(height: AppSpacing.sectionLarge),

                        // Title
                        Text(
                          widget.isSignIn
                              ? 'Welcome back'
                              : 'Create your account',
                          textAlign: TextAlign.center,
                          style: AppFonts.textStyle(
                            fontSize: 24.scaledText(context),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),

                        SizedBox(
                          height: AppSpacing.spacingXSmall.scaled(context),
                        ),

                        Text(
                          widget.isSignIn
                              ? 'Sign in to continue tracking your expenses'
                              : 'Start your journey to financial clarity',
                          textAlign: TextAlign.center,
                          style: AppFonts.textStyle(
                            fontSize: 14.scaledText(context),
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),

                        SizedBox(height: AppSpacing.sectionMedium),

                        // Error message (from auth state or local)
                        if (displayErrorMessage != null &&
                            displayErrorMessage.isNotEmpty &&
                            displayErrorMessage != 'null') ...[
                          Container(
                            padding: EdgeInsets.all(
                              AppSpacing.spacingSmall.scaled(context),
                            ),
                            decoration: BoxDecoration(
                              color: PreAppColors.errorColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSmall.scaled(context),
                              ),
                              border: Border.all(
                                color: PreAppColors.errorColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white,
                                  size: AppSpacing.iconSize.scaled(context),
                                ),
                                SizedBox(
                                  width: AppSpacing.spacingSmall.scaled(
                                    context,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    displayErrorMessage,
                                    style: AppFonts.textStyle(
                                      fontSize: 14.scaledText(context),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSpacing.spacingMedium),
                        ],

                        // OAuth buttons: only the one in progress shows loading; others are disabled
                        if (!_showEmailForm) ...[
                          // Google - shows spinner only when Google auth is in progress
                          AppButton(
                            label: widget.isSignIn
                                ? 'Continue with Google'
                                : 'Continue with Google',
                            onPressed: isAnyOAuthLoading || isLoading
                                ? null
                                : _handleGoogleAuth,
                            isLoading: isGoogleAuthInProgress,
                            size: AppButtonSize.primary,
                            variant: AppButtonVariant.outlined,
                            imageIcon: 'assets/images/google_logo.png',
                            icon: Icons.g_mobiledata,
                            backgroundColor: Colors.white,
                            textColor: const Color(0xFF1F2937),
                          ),

                          SizedBox(height: AppSpacing.spacingSmall),

                          // Apple - shows spinner only when Apple auth is in progress
                          if (Platform.isIOS) ...[
                            AppButton(
                              label: widget.isSignIn
                                  ? 'Continue with Apple'
                                  : 'Continue with Apple',
                              onPressed: isAnyOAuthLoading || isLoading
                                  ? null
                                  : _handleAppleAuth,
                              isLoading: isAppleAuthInProgress,
                              size: AppButtonSize.primary,
                              variant: AppButtonVariant.outlined,
                              icon: Icons.apple,
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                            ),
                            SizedBox(height: AppSpacing.spacingSmall),
                          ],

                          SizedBox(height: AppSpacing.spacingSmall),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.spacingMedium.scaled(
                                    context,
                                  ),
                                ),
                                child: Text(
                                  'or',
                                  style: AppFonts.textStyle(
                                    fontSize: 14.scaledText(context),
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: AppSpacing.spacingMedium),

                          // Create Free Account / Sign In - Primary Large Button
                          AppButton.primary(
                            label: widget.isSignIn
                                ? 'Sign In'
                                : 'Create Free Account',
                            onPressed: isAnyOAuthLoading || isLoading
                                ? null
                                : () {
                                    setState(() => _showEmailForm = true);
                                  },
                            isLoading:
                                false, // Never show loading for this button (it just opens email form)
                            icon: Icons.email_outlined,
                          ),
                        ],

                        // Email form
                        if (_showEmailForm) ...[
                          // Back to OAuth options
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() => _showEmailForm = false);
                              },
                              icon: Icon(
                                Icons.chevron_left,
                                size: 14.scaled(context),
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              label: Text(
                                'Other sign in options',
                                style: AppFonts.textStyle(
                                  fontSize: 14.scaledText(context),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: AppSpacing.spacingSmall
                                      .scaledVertical(context),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),

                          SizedBox(height: AppSpacing.spacingMedium),

                          // Name field (only for signup)
                          if (!widget.isSignIn) ...[
                            AppTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              hintText: 'John Doe',
                              useDarkStyle: true,
                              autofillHints: const [AutofillHints.name],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSpacing.spacingMedium),
                          ],

                          // Email field
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            useDarkStyle: true,
                            autofillHints: const [AutofillHints.email],
                            validator: EmailValidator.validate,
                          ),

                          SizedBox(height: AppSpacing.spacingMedium),

                          // Password field
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: widget.isSignIn
                                ? 'Enter your password'
                                : 'Create a password',
                            obscureText: _obscurePassword,
                            useDarkStyle: true,
                            autofillHints: [
                              widget.isSignIn
                                  ? AutofillHints.password
                                  : AutofillHints.newPassword,
                            ],
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              // For registration, use strict password validation
                              if (!widget.isSignIn) {
                                return PasswordValidator.validate(value);
                              }
                              // For login, just check it's not empty
                              return null;
                            },
                          ),

                          // Password hint (signup only)
                          if (!widget.isSignIn) ...[
                            SizedBox(height: AppSpacing.spacingXSmall),
                            Text(
                              'Must be at least 8 characters',
                              style: AppFonts.textStyle(
                                fontSize: 13.scaledText(context),
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],

                          SizedBox(height: AppSpacing.spacingMedium),

                          // Submit button - Primary Large Button
                          AppButton.primary(
                            label: widget.isSignIn
                                ? 'Sign In'
                                : 'Create Free Account',
                            onPressed: isLoading ? null : _handleEmailAuth,
                            isLoading: isLoading,
                          ),
                        ],

                        SizedBox(height: AppSpacing.spacingMedium),

                        // Switch auth mode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.isSignIn
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                              style: AppFonts.textStyle(
                                fontSize: 14.scaledText(context),
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => AuthScreen(
                                          isSignIn: !widget.isSignIn,
                                        ),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                    transitionDuration: const Duration(
                                      milliseconds: 200,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                widget.isSignIn ? 'Sign Up' : 'Sign In',
                                style: AppFonts.textStyle(
                                  fontSize: 14.scaledText(context),
                                  fontWeight: FontWeight.w700,
                                  color: PreAppColors.warningColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: AppSpacing.spacingLarge),
                      ],
                    ),
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
