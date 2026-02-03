import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PIN setup flow state
enum PinSetupStep {
  /// User is entering their new PIN
  enterPin,
  /// User is confirming their PIN
  confirmPin,
  /// PIN setup is complete
  complete,
}

/// PIN setup flow state
class PinSetupState {
  final PinSetupStep step;
  final String? enteredPin;
  final String? errorMessage;
  final bool isProcessing;

  const PinSetupState({
    this.step = PinSetupStep.enterPin,
    this.enteredPin,
    this.errorMessage,
    this.isProcessing = false,
  });

  PinSetupState copyWith({
    PinSetupStep? step,
    String? enteredPin,
    String? errorMessage,
    bool? isProcessing,
  }) {
    return PinSetupState(
      step: step ?? this.step,
      enteredPin: enteredPin ?? this.enteredPin,
      errorMessage: errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// PIN setup flow notifier
class PinSetupNotifier extends StateNotifier<PinSetupState> {
  PinSetupNotifier() : super(const PinSetupState());

  /// Submit PIN in current step
  void submitPin(String pin) {
    if (state.isProcessing) return;

    switch (state.step) {
      case PinSetupStep.enterPin:
        // Move to confirm step
        state = state.copyWith(
          step: PinSetupStep.confirmPin,
          enteredPin: pin,
          errorMessage: null,
        );
        break;

      case PinSetupStep.confirmPin:
        // Check if PINs match
        if (pin == state.enteredPin) {
          // PINs match - mark processing (caller will handle actual save)
          state = state.copyWith(
            step: PinSetupStep.complete,
            isProcessing: true,
            errorMessage: null,
          );
        } else {
          // PINs don't match - go back to enter step
          state = state.copyWith(
            step: PinSetupStep.enterPin,
            enteredPin: null,
            errorMessage: 'PINs do not match. Please try again.',
          );
        }
        break;

      case PinSetupStep.complete:
        // Already complete
        break;
    }
  }

  /// Go back to previous step
  void goBack() {
    if (state.step == PinSetupStep.confirmPin) {
      state = state.copyWith(
        step: PinSetupStep.enterPin,
        enteredPin: null,
        errorMessage: null,
      );
    }
  }

  /// Reset flow
  void reset() {
    state = const PinSetupState();
  }

  /// Mark as completed (after successful save)
  void markCompleted() {
    state = state.copyWith(isProcessing: false);
  }

  /// Set error message
  void setError(String message) {
    state = state.copyWith(
      errorMessage: message,
      isProcessing: false,
    );
  }
}

/// PIN setup notifier provider (auto-disposed when screen closes)
final pinSetupNotifierProvider =
    StateNotifierProvider.autoDispose<PinSetupNotifier, PinSetupState>((ref) {
  return PinSetupNotifier();
});

/// Convenience provider for current step
final pinSetupStepProvider = Provider.autoDispose<PinSetupStep>((ref) {
  return ref.watch(pinSetupNotifierProvider).step;
});

/// Convenience provider for error message
final pinSetupErrorProvider = Provider.autoDispose<String?>((ref) {
  return ref.watch(pinSetupNotifierProvider).errorMessage;
});

/// Convenience provider for processing state
final pinSetupProcessingProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(pinSetupNotifierProvider).isProcessing;
});
