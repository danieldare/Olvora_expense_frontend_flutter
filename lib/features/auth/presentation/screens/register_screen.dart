import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/wallet_app_icon.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/pre_app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/email_validator.dart';
import '../../../../core/utils/password_validator.dart';
import '../providers/auth_providers.dart';
import '../state/auth_state.dart';
import '../../../home/presentation/screens/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final bool _obscurePassword = true;
  bool _isRegistering = false;
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
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || _isRegistering) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        firstName: _firstNameController.text.trim().isNotEmpty
            ? _firstNameController.text.trim()
            : null,
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
      );
    } catch (e) {
      // Errors are handled by AuthStateError from the notifier
      // The error will be displayed via the auth state listener
      if (kDebugMode) {
        debugPrint('Registration error (handled by AuthStateError): $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isRegistering) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.loginWithGoogle();
    } catch (e) {
      // Errors are handled by AuthStateError from the notifier
      if (kDebugMode) {
        debugPrint('Google sign-in error (handled by AuthStateError): $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen to auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthStateAuthenticated && mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        });
      } else if (next is AuthStateError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${next.message}'),
            backgroundColor: PreAppColors.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final isLoading =
        authState is AuthStateAuthenticating ||
        authState is AuthStateEstablishingSession ||
        _isRegistering;

    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: PreAppColors.authGradient,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 100),
                    // App Logo
                    Center(
                      child: WalletAppIcon(
                        size: AppSpacing.authLogoSize,
                        iconSize: AppSpacing.authLogoIconSize,
                        shimmerController: _shimmerController,
                        shimmerPosition: _shimmerPosition,
                        primaryColor: PreAppColors.primaryColor,
                        purpleLight: const Color(0xFF8B7AFF),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Logo-style text with "OLVORA" on top, "expense" below
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "OLVORA" on top
                        Text(
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
                        Text(
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
                      ],
                    ),
                    SizedBox(height: 12),
                    // Subtitle
                    Text(
                      'Create an account to start tracking your expenses',
                      textAlign: TextAlign.center,
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: 48),
                    // First Name Field
                    AppTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hintText: 'John',
                      // autofocus: true,
                      useDarkStyle: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    // Last Name Field
                    AppTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hintText: 'Doe',
                      useDarkStyle: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    // Email Field
                    AppTextField(
                      controller: _emailController,
                      label: 'Email address',
                      hintText: 'User@olvora.com',
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      useDarkStyle: true,
                      validator: EmailValidator.validate,
                    ),
                    SizedBox(height: 20),
                    // Password Field
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: 'Enter your password',
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      useDarkStyle: true,
                      validator: PasswordValidator.validate,
                    ),
                    SizedBox(height: 8),
                    // Password requirements
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              PasswordValidator.getRequirementsText(),
                              style: AppFonts.textStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    // Next/Register button
                    ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PreAppColors.warningColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              child: LoadingSpinnerVariants.black(
                                size: 20,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign Up',
                              style: AppFonts.textStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                    ),
                    SizedBox(height: 24),
                    // Or separator
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color.fromARGB(117, 229, 231, 235),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or',
                            style: AppFonts.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: const Color.fromARGB(117, 229, 231, 235),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Google Sign-up button
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _handleGoogleSignIn,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: Color(0xFF4285F4),
                          );
                        },
                      ),
                      label: Text(
                        'Sign up with Google',
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppFonts.textStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Sign In',
                            style: AppFonts.textStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
