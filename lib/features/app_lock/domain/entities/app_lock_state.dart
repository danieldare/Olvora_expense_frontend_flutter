/// App lock state - determines what the user sees
///
/// State Machine:
/// - PinSetupRequired: First login, user must set up PIN
/// - Unlocked: App is unlocked, normal usage
/// - Locked: App is locked, show lock screen
/// - Lockout: Too many failed attempts, must re-authenticate with Google
sealed class AppLockState {
  const AppLockState();
}

/// PIN setup is required (first login after auth)
///
/// User must complete PIN setup before accessing the app
class AppLockStatePinSetupRequired extends AppLockState {
  const AppLockStatePinSetupRequired();
}

/// App is unlocked - normal usage
class AppLockStateUnlocked extends AppLockState {
  const AppLockStateUnlocked();
}

/// App is locked - show lock screen
///
/// [failedAttempts] tracks PIN entry failures for lockout logic
class AppLockStateLocked extends AppLockState {
  final int failedAttempts;

  const AppLockStateLocked({this.failedAttempts = 0});

  /// Maximum failed attempts before lockout
  static const int maxFailedAttempts = 5;

  /// Check if approaching lockout
  bool get isApproachingLockout => failedAttempts >= maxFailedAttempts - 2;

  /// Get remaining attempts before lockout
  int get remainingAttempts => maxFailedAttempts - failedAttempts;

  /// Create state with incremented failure count
  AppLockStateLocked withFailedAttempt() {
    return AppLockStateLocked(failedAttempts: failedAttempts + 1);
  }
}

/// Lockout state - too many failed PIN attempts
///
/// User must re-authenticate with Google/Apple to continue
/// This clears the session and requires fresh login
class AppLockStateLockout extends AppLockState {
  const AppLockStateLockout();
}
