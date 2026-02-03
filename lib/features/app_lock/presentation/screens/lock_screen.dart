import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../providers/app_lock_providers.dart';
import '../widgets/pin_input_widget.dart';
import '../../domain/entities/app_lock_state.dart';

/// Lock Screen - shown when app is locked
///
/// Features:
/// - Biometric unlock (if enabled)
/// - PIN fallback
/// - Failed attempt tracking
/// - Lockout on 5 failures
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final GlobalKey<PinInputWidgetState> _pinInputKey = GlobalKey();
  bool _attemptedBiometric = false;

  @override
  void initState() {
    super.initState();
    // Try biometric on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  Future<void> _tryBiometricUnlock() async {
    if (_attemptedBiometric) return;
    _attemptedBiometric = true;

    final isBiometricAvailable = await ref.read(isBiometricUnlockAvailableProvider.future);
    if (!isBiometricAvailable) return;

    // Small delay for UI to settle
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await ref.read(appLockNotifierProvider.notifier).unlockWithBiometrics();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appLockState = ref.watch(appLockNotifierProvider);

    // Get remaining attempts if locked
    final remainingAttempts = appLockState is AppLockStateLocked
        ? appLockState.remainingAttempts
        : null;

    final isApproachingLockout = appLockState is AppLockStateLocked &&
        appLockState.isApproachingLockout;

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
              SizedBox(height: 16.scaled(context)),

              // App name
              Text(
                'Olvora',
                style: AppFonts.textStyle(
                  fontSize: 20.scaledText(context),
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 24.scaled(context)),

              Expanded(
                child: FutureBuilder<bool>(
                  future: ref.read(isBiometricUnlockAvailableProvider.future),
                  builder: (context, snapshot) {
                    final showBiometric = snapshot.data ?? false;

                    return FutureBuilder<BiometricType?>(
                      future: ref.read(biometricTypeProvider.future),
                      builder: (context, biometricSnapshot) {
                        final biometricType = biometricSnapshot.data;
                        final biometricIcon = biometricType == BiometricType.face
                            ? Icons.face_rounded
                            : Icons.fingerprint_rounded;

                        return PinInputWidget(
                          key: _pinInputKey,
                          pinLength: 4,
                          title: 'Enter PIN',
                          subtitle: _getSubtitle(remainingAttempts, isApproachingLockout),
                          errorMessage: isApproachingLockout && remainingAttempts != null
                              ? '$remainingAttempts attempts remaining'
                              : null,
                          showBiometricButton: showBiometric,
                          biometricIcon: biometricIcon,
                          onBiometricPressed: _onBiometricPressed,
                          onPinComplete: _onPinComplete,
                        );
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: 32.scaled(context)),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle(int? remainingAttempts, bool isApproachingLockout) {
    if (isApproachingLockout && remainingAttempts != null) {
      return 'Warning: $remainingAttempts attempts remaining';
    }
    return 'Enter your PIN to unlock';
  }

  Future<void> _onPinComplete(String pin) async {
    final success = await ref.read(appLockNotifierProvider.notifier).unlockWithPin(pin);

    if (!success && mounted) {
      _pinInputKey.currentState?.shake();
      _pinInputKey.currentState?.clear();
    }
  }

  Future<void> _onBiometricPressed() async {
    await ref.read(appLockNotifierProvider.notifier).unlockWithBiometrics();
  }
}
