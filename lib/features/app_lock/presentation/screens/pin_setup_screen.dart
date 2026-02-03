import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../providers/app_lock_providers.dart';
import '../providers/pin_setup_providers.dart';
import '../widgets/pin_input_widget.dart';

/// PIN Setup Screen - shown on first login after Google/Apple auth
///
/// Flow:
/// 1. Enter 4-digit PIN
/// 2. Confirm PIN
/// 3. Optional biometric prompt
/// 4. Done → navigate to home
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final GlobalKey<PinInputWidgetState> _pinInputKey = GlobalKey();
  bool _showBiometricPrompt = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(pinSetupNotifierProvider);

    // Listen for step changes to clear PIN input
    ref.listen<PinSetupState>(pinSetupNotifierProvider, (previous, next) {
      if (previous?.step != next.step) {
        _pinInputKey.currentState?.clear();
      }
      if (next.errorMessage != null) {
        _pinInputKey.currentState?.shake();
      }
      if (next.step == PinSetupStep.complete && !next.isProcessing) {
        // PIN setup complete - check biometric availability
        _checkBiometricAndProceed();
      }
    });

    if (_showBiometricPrompt) {
      return _buildBiometricPrompt(context, isDark);
    }

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24.scaled(context),
          ),
          child: Column(
            children: [
              SizedBox(height: 60.scaled(context)),
              // Lock icon
              Container(
                width: 80.scaled(context),
                height: 80.scaled(context),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 40.scaled(context),
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 32.scaled(context)),

              Expanded(
                child: PinInputWidget(
                  key: _pinInputKey,
                  pinLength: 4,
                  title: _getTitle(state.step),
                  subtitle: _getSubtitle(state.step),
                  errorMessage: state.errorMessage,
                  isDisabled: state.isProcessing,
                  onPinComplete: (pin) => _onPinComplete(pin, state.step),
                ),
              ),

              // Back button for confirm step
              if (state.step == PinSetupStep.confirmPin) ...[
                TextButton(
                  onPressed: () {
                    ref.read(pinSetupNotifierProvider.notifier).goBack();
                  },
                  child: Text(
                    'Go Back',
                    style: AppFonts.textStyle(
                      fontSize: 14.scaledText(context),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 32.scaled(context)),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle(PinSetupStep step) {
    switch (step) {
      case PinSetupStep.enterPin:
        return 'Create your PIN';
      case PinSetupStep.confirmPin:
        return 'Confirm your PIN';
      case PinSetupStep.complete:
        return 'PIN Created';
    }
  }

  String _getSubtitle(PinSetupStep step) {
    switch (step) {
      case PinSetupStep.enterPin:
        return 'Enter a 4-digit PIN to secure your app';
      case PinSetupStep.confirmPin:
        return 'Enter your PIN again to confirm';
      case PinSetupStep.complete:
        return 'Your PIN has been set up successfully';
    }
  }

  Future<void> _onPinComplete(String pin, PinSetupStep step) async {
    final notifier = ref.read(pinSetupNotifierProvider.notifier);
    notifier.submitPin(pin);

    // If we're now in complete step, save the PIN
    final newState = ref.read(pinSetupNotifierProvider);
    if (newState.step == PinSetupStep.complete && newState.isProcessing) {
      try {
        await ref.read(appLockNotifierProvider.notifier).completePinSetup(pin);
        notifier.markCompleted();
      } catch (e) {
        notifier.setError('Failed to save PIN. Please try again.');
      }
    }
  }

  Future<void> _checkBiometricAndProceed() async {
    final biometricService = ref.read(biometricServiceProvider);
    final isAvailable = await biometricService.isBiometricAvailable();

    if (isAvailable) {
      setState(() {
        _showBiometricPrompt = true;
      });
    }
    // If biometrics not available, the app lock state will navigate automatically
  }

  Widget _buildBiometricPrompt(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.scaled(context)),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Biometric icon
              FutureBuilder<BiometricType?>(
                future: ref.read(biometricServiceProvider).getPrimaryBiometricType(),
                builder: (context, snapshot) {
                  final type = snapshot.data;
                  final icon = type == BiometricType.face
                      ? Icons.face_rounded
                      : Icons.fingerprint_rounded;
                  final typeName = ref
                      .read(biometricServiceProvider)
                      .getBiometricTypeName(type);

                  return Column(
                    children: [
                      Container(
                        width: 100.scaled(context),
                        height: 100.scaled(context),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          icon,
                          size: 50.scaled(context),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 32.scaled(context)),
                      Text(
                        'Enable $typeName?',
                        style: AppFonts.textStyle(
                          fontSize: 24.scaledText(context),
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.scaled(context)),
                      Text(
                        'Use $typeName for quick and secure access to your app',
                        style: AppFonts.textStyle(
                          fontSize: 14.scaledText(context),
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),

              const Spacer(flex: 3),

              // Enable button
              SizedBox(
                width: double.infinity,
                height: 52.scaled(context),
                child: ElevatedButton(
                  onPressed: _enableBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Enable',
                    style: AppFonts.textStyle(
                      fontSize: 16.scaledText(context),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.scaled(context)),

              // Skip button
              TextButton(
                onPressed: _skipBiometric,
                child: Text(
                  'Maybe later',
                  style: AppFonts.textStyle(
                    fontSize: 14.scaledText(context),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              SizedBox(height: 32.scaled(context)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enableBiometric() async {
    final biometricService = ref.read(biometricServiceProvider);
    final storageService = ref.read(appLockStorageServiceProvider);

    // Prompt for biometric authentication to confirm
    final success = await biometricService.authenticate(
      reason: 'Confirm biometric setup',
    );

    if (success) {
      await storageService.setBiometricEnabled(true);
    }

    // Continue to app regardless of result
    _finishSetup();
  }

  void _skipBiometric() {
    _finishSetup();
  }

  void _finishSetup() {
    // The app lock state is already Unlocked, so navigation will happen automatically
    // via the app_root.dart listener
    setState(() {
      _showBiometricPrompt = false;
    });
  }
}
