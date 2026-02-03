import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../providers/app_lock_providers.dart';
import '../widgets/pin_input_widget.dart';

/// Change PIN screen - requires current PIN verification
///
/// Flow:
/// 1. Enter current PIN for verification
/// 2. Enter new PIN
/// 3. Confirm new PIN
/// 4. Success - return to settings
enum _ChangePinStep {
  verifyCurrentPin,
  enterNewPin,
  confirmNewPin,
}

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final GlobalKey<PinInputWidgetState> _pinInputKey = GlobalKey();
  _ChangePinStep _currentStep = _ChangePinStep.verifyCurrentPin;
  String? _newPin;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.scaled(context),
                vertical: 8.scaled(context),
              ),
              child: Row(
                children: [
                  AppBackButton(
                    onPressed: () {
                      if (_currentStep != _ChangePinStep.verifyCurrentPin) {
                        _goBack();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  SizedBox(width: 8.scaled(context)),
                  Text(
                    'Change PIN',
                    style: AppFonts.textStyle(
                      fontSize: 18.scaledText(context),
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // PIN input
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.scaled(context),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 40.scaled(context)),

                    // Step indicator
                    _buildStepIndicator(context, isDark),

                    SizedBox(height: 24.scaled(context)),

                    Expanded(
                      child: PinInputWidget(
                        key: _pinInputKey,
                        pinLength: 4,
                        title: _getTitle(),
                        subtitle: _getSubtitle(),
                        errorMessage: _errorMessage,
                        isDisabled: _isProcessing,
                        onPinComplete: _onPinComplete,
                      ),
                    ),

                    SizedBox(height: 32.scaled(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(context, isDark, 0, _currentStep.index >= 0),
        _buildStepLine(context, isDark, _currentStep.index >= 1),
        _buildStepDot(context, isDark, 1, _currentStep.index >= 1),
        _buildStepLine(context, isDark, _currentStep.index >= 2),
        _buildStepDot(context, isDark, 2, _currentStep.index >= 2),
      ],
    );
  }

  Widget _buildStepDot(BuildContext context, bool isDark, int step, bool isActive) {
    return Container(
      width: 12.scaled(context),
      height: 12.scaled(context),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppTheme.primaryColor
            : (isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildStepLine(BuildContext context, bool isDark, bool isActive) {
    return Container(
      width: 32.scaled(context),
      height: 2,
      color: isActive
          ? AppTheme.primaryColor
          : (isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.3)),
    );
  }

  String _getTitle() {
    switch (_currentStep) {
      case _ChangePinStep.verifyCurrentPin:
        return 'Enter Current PIN';
      case _ChangePinStep.enterNewPin:
        return 'Enter New PIN';
      case _ChangePinStep.confirmNewPin:
        return 'Confirm New PIN';
    }
  }

  String _getSubtitle() {
    switch (_currentStep) {
      case _ChangePinStep.verifyCurrentPin:
        return 'Verify your current PIN to continue';
      case _ChangePinStep.enterNewPin:
        return 'Choose a new 4-digit PIN';
      case _ChangePinStep.confirmNewPin:
        return 'Enter your new PIN again';
    }
  }

  Future<void> _onPinComplete(String pin) async {
    setState(() {
      _errorMessage = null;
    });

    switch (_currentStep) {
      case _ChangePinStep.verifyCurrentPin:
        await _verifyCurrentPin(pin);
        break;
      case _ChangePinStep.enterNewPin:
        _setNewPin(pin);
        break;
      case _ChangePinStep.confirmNewPin:
        await _confirmNewPin(pin);
        break;
    }
  }

  Future<void> _verifyCurrentPin(String pin) async {
    setState(() {
      _isProcessing = true;
    });

    final pinService = ref.read(pinServiceProvider);
    final isValid = await pinService.verifyPin(pin);

    setState(() {
      _isProcessing = false;
    });

    if (isValid) {
      setState(() {
        _currentStep = _ChangePinStep.enterNewPin;
      });
      _pinInputKey.currentState?.clear();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
      _pinInputKey.currentState?.shake();
      _pinInputKey.currentState?.clear();
    }
  }

  void _setNewPin(String pin) {
    setState(() {
      _newPin = pin;
      _currentStep = _ChangePinStep.confirmNewPin;
    });
    _pinInputKey.currentState?.clear();
  }

  Future<void> _confirmNewPin(String pin) async {
    if (pin != _newPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _currentStep = _ChangePinStep.enterNewPin;
        _newPin = null;
      });
      _pinInputKey.currentState?.shake();
      _pinInputKey.currentState?.clear();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final pinService = ref.read(pinServiceProvider);
      await pinService.savePin(pin);

      if (mounted) {
        // Show success and go back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PIN changed successfully',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to change PIN. Please try again.';
      });
      _pinInputKey.currentState?.shake();
      _pinInputKey.currentState?.clear();
    }
  }

  void _goBack() {
    setState(() {
      _errorMessage = null;
      switch (_currentStep) {
        case _ChangePinStep.verifyCurrentPin:
          // Already at first step, do nothing
          break;
        case _ChangePinStep.enterNewPin:
          _currentStep = _ChangePinStep.verifyCurrentPin;
          break;
        case _ChangePinStep.confirmNewPin:
          _currentStep = _ChangePinStep.enterNewPin;
          _newPin = null;
          break;
      }
    });
    _pinInputKey.currentState?.clear();
  }
}
