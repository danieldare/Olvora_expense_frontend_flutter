import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/pre_app_colors.dart';
import '../theme/dynamic_theme_colors.dart';
import '../models/color_theme.dart';
import '../providers/app_providers.dart';
import '../providers/theme_providers.dart';
import '../widgets/notification_detection_listener.dart';
import '../widgets/app_lifecycle_handler.dart';
import '../widgets/app_lock_overlay.dart';
import '../widgets/loading_spinner.dart';
import '../services/local_notification_service.dart';
import '../services/share_handler_service.dart';
import '../navigation/navigator_service.dart';
import '../navigation/auth_navigation_providers.dart';
import '../navigation/app_phase_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/app_lock/presentation/providers/app_lock_providers.dart';
import '../../features/app_lock/domain/entities/app_lock_state.dart';
import '../../features/app_lock/presentation/screens/pin_setup_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/account_grace_period_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../providers/onboarding_provider.dart';

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  // Track if phase transition listener has been set up
  bool _phaseListenerSetup = false;
  // Track if ShareHandlerService container has been set (avoids scheduling callback on every rebuild)
  bool _shareHandlerContainerSet = false;

  @override
  void initState() {
    super.initState();
    // Initialize app-wide services once per app lifecycle
    // Using postFrameCallback to ensure initialization happens after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotificationService().initialize().catchError((error) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to initialize notifications: $error');
        }
        return false;
      });
      ShareHandlerService().initialize();
    });
  }

  /// Setup lifecycle listener for app phase transitions
  ///
  /// CRITICAL: This listener watches authNavigationProvider and transitions
  /// from bootstrapping to running phase when a terminal destination is reached.
  ///
  /// This is the ONLY place where phase transitions occur, ensuring:
  /// - Providers remain pure (no side effects in providers)
  /// - Phase transition is idempotent and write-once
  /// - SplashScreen is structurally impossible after running phase
  ///
  /// Terminal destinations that trigger transition:
  /// - AuthDestination.home: User is authenticated
  /// - AuthDestination.auth: User is unauthenticated (terminal state reached)
  /// - AuthDestination.pinSetup: User needs PIN setup
  ///
  /// Non-terminal destinations (do NOT trigger transition):
  /// - AuthDestination.splash: Still bootstrapping
  ///
  /// ADDITIONAL: When user reaches home (authenticated), mark onboarding as complete.
  /// This ensures that even if SharedPreferences is cleared, authenticated users
  /// never see onboarding again after logout.
  void _setupPhaseTransitionListener(WidgetRef ref) {
    // Listen to authNavigationProvider changes
    // This runs OUTSIDE provider build, so side effects are allowed
    ref.listen<AuthDestination>(authNavigationProvider, (previous, next) {
      // CRITICAL: When user reaches home (authenticated), mark onboarding complete
      // This ensures:
      // 1. OAuth users who skip onboarding flow have it marked complete
      // 2. Users who clear app data but stay logged in don't see onboarding on logout
      // 3. Returning users on new devices who login directly never see onboarding
      if (next == AuthDestination.home) {
        _ensureOnboardingMarkedComplete(ref);
      }

      // Skip if this is the first call (previous is null)
      // We only want to transition when destination actually changes from splash
      if (previous == null) {
        return;
      }

      // Only transition if we're still in bootstrapping phase
      final currentPhase = ref.read(appPhaseProvider);
      if (currentPhase != AppPhase.bootstrapping) {
        // Already in running phase - no transition needed
        return;
      }

      // Transition to running phase when terminal destination is reached
      // Terminal destinations are: home, pinSetup, gracePeriod (authenticated) or auth (unauthenticated)
      // Non-terminal: splash (still bootstrapping)
      final isTerminalDestination =
          next == AuthDestination.home ||
          next == AuthDestination.auth ||
          next == AuthDestination.pinSetup ||
          next == AuthDestination.gracePeriod;

      if (isTerminalDestination) {
        if (kDebugMode) {
          debugPrint(
            '🔄 [AppRoot] Transitioning to running phase (terminal destination: $next, previous: $previous)',
          );
        }
        // Use SchedulerBinding to defer transition until after current frame
        // This prevents splash from flashing when transitioning too quickly
        // It allows splash to be visible for at least one frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final currentPhaseCheck = ref.read(appPhaseProvider);
            if (currentPhaseCheck == AppPhase.bootstrapping) {
              ref.read(appPhaseNotifierProvider.notifier).transitionToRunning();
            }
          }
        });
      }
    });
  }

  /// Setup app lock related listeners
  ///
  /// CRITICAL: These listeners handle:
  /// 1. Initializing app lock when user becomes authenticated
  /// 2. Triggering logout when lockout state is reached
  /// 3. Clearing app lock data on logout
  void _setupAppLockListeners(WidgetRef ref) {
    // Listen for auth state changes to initialize/clear app lock
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthStateAuthenticated &&
          previous is! AuthStateAuthenticated) {
        // User just became authenticated - initialize app lock
        if (kDebugMode) {
          debugPrint('🔐 [AppRoot] User authenticated - initializing app lock');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(appLockNotifierProvider.notifier).initialize();
          }
        });
      } else if (next is AuthStateUnauthenticated &&
          previous is AuthStateAuthenticated) {
        // User logged out - clear app lock data
        if (kDebugMode) {
          debugPrint('🔐 [AppRoot] User logged out - clearing app lock');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(appLockNotifierProvider.notifier).clearAll();
          }
        });
      }
    });

    // Listen for lockout state to trigger logout
    ref.listen<AppLockState>(appLockNotifierProvider, (previous, next) {
      if (next is AppLockStateLockout) {
        // Lockout triggered - force logout
        if (kDebugMode) {
          debugPrint('🔐 [AppRoot] Lockout triggered - forcing logout');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(authNotifierProvider.notifier).logout();
          }
        });
      }
    });
  }

  /// Ensures onboarding status is synced when user is authenticated
  ///
  /// This is called when navigation destination becomes `home`, indicating
  /// the user is fully authenticated. This ensures:
  /// - Local and server onboarding status are in sync
  /// - Users who authenticated via OAuth (skipping onboarding) have flag set
  /// - Users who clear SharedPreferences but remain logged in are protected
  /// - Cross-device sync: server is the source of truth
  void _ensureOnboardingMarkedComplete(WidgetRef ref) {
    if (kDebugMode) {
      debugPrint('🎯 [AppRoot] Syncing onboarding status (user authenticated)');
    }

    // Sync onboarding status between local and server
    // This handles all edge cases:
    // - Local true, server false → sync to server
    // - Local false, server true → sync to local
    // - Both false → mark complete (user just authenticated)
    // - Both true → no action needed
    ref.read(syncOnboardingToServerProvider)().then((_) {
      // After sync, if still not completed, mark it complete
      // This handles OAuth users who skip the onboarding flow entirely
      ref.read(onboardingCompletedProvider).whenData((completed) {
        if (!completed) {
          if (kDebugMode) {
            debugPrint('🎯 [AppRoot] Marking onboarding complete (OAuth user)');
          }
          ref.read(markOnboardingCompletedProvider)();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set provider container for ShareHandlerService once (avoids callback on every rebuild)
    if (!_shareHandlerContainerSet) {
      _shareHandlerContainerSet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            final container = ProviderScope.containerOf(context);
            ShareHandlerService().setProviderContainer(container);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Could not set provider container: $e');
            }
          }
        }
      });
    }
    final firebaseState = ref.watch(firebaseInitializationProvider);
    final colorTheme = ref.watch(colorThemeProvider);
    final appPhase = ref.watch(appPhaseProvider);
    final authDestination = ref.watch(authNavigationProvider);

    // CRITICAL: Watch authInitializationProvider to trigger auth check reactively
    // This provider automatically calls checkAuthStatus() when Firebase is ready
    // and auth state is Unauthenticated. No imperative logic needed.
    ref.watch(authInitializationProvider);

    // CRITICAL: Setup phase transition listener ONCE per widget lifecycle
    // This ensures the listener is only registered once, preventing duplicate transitions
    // The listener runs OUTSIDE provider build, so side effects are allowed
    if (!_phaseListenerSetup) {
      _setupPhaseTransitionListener(ref);
      _setupAppLockListeners(ref);
      _phaseListenerSetup = true;
    }

    // Debug logging
    if (kDebugMode) {
      debugPrint(
        '🏠 [AppRoot] Firebase: ${firebaseState.isLoading
            ? "loading"
            : firebaseState.hasValue
            ? "ready"
            : "error"}',
      );
      debugPrint('🏠 [AppRoot] AppPhase: $appPhase');
      debugPrint('🏠 [AppRoot] Destination: $authDestination');
    }

    // Update DynamicThemeColors whenever theme changes
    DynamicThemeColors.updateTheme(colorTheme);

    // Automatically set theme mode based on selected color theme
    final themeMode = colorTheme.isDark ? ThemeMode.dark : ThemeMode.light;

    // Generate light and dark themes from the selected color theme
    final lightTheme = colorTheme.isDark
        ? AppTheme.fromColorTheme(
            ColorTheme.allThemes.firstWhere(
              (t) =>
                  !t.isDark &&
                  t.id.replaceAll('_dark', '') ==
                      colorTheme.id.replaceAll('_dark', ''),
              orElse: () => ColorTheme.defaultTheme,
            ),
          )
        : AppTheme.fromColorTheme(colorTheme);

    final darkTheme = colorTheme.isDark
        ? AppTheme.fromColorTheme(colorTheme)
        : AppTheme.fromColorTheme(
            ColorTheme.allThemes.firstWhere(
              (t) => t.isDark && t.id == '${colorTheme.id}_dark',
              orElse: () => ColorTheme.defaultDarkTheme,
            ),
          );

    // CRITICAL: Build pages list reactively based on AppPhase and auth destination
    // AppPhase determines whether SplashRouter or AuthenticatedApp/UnauthenticatedApp is shown
    // This ensures SplashScreen is structurally unreachable after bootstrapping phase
    final authState = ref.watch(authNotifierProvider);
    final List<Page<dynamic>> pages = _buildPages(
      firebaseState,
      appPhase,
      authDestination,
      authState,
    );

    // One-time font debug (kDebugMode only)
    if (kDebugMode) {
      assert(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _logFontDebugOnce(lightTheme, darkTheme);
        });
        return true;
      }());
    }

    return AppLifecycleHandler(
      child: MaterialApp(
        // CRITICAL: navigatorKey is set on the Navigator widget below, not here
        // MaterialApp will use the Navigator from home: as its root navigator
        title: 'Olvora',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        builder: (context, child) {
          return DefaultTextStyle(
            style: TextStyle(fontFamily: 'Manrope', inherit: true),
            child: NotificationDetectionListener(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        // CRITICAL: Use Navigator.pages for declarative, state-driven navigation
        // This ensures the entire stack is reset when authDestination changes
        // The navigatorKey is attached to this Navigator, making it the root navigator
        home: Navigator(
          key: navigatorKey,
          pages: pages,
          onPopPage: (route, result) {
            // CRITICAL: For auth-driven navigation, prevent back navigation
            // The navigation stack is controlled entirely by authDestination.
            // Allowing manual back navigation would break the auth flow.
            // Since we only have one page per destination, back navigation
            // would try to pop the root route, which we prevent.
            return false;
          },
        ),
      ),
    );
  }

  /// Build the pages list based on Firebase state, app phase, and auth destination
  ///
  /// CRITICAL: This method defines the entire Navigator stack.
  /// - During `bootstrapping` phase: SplashRouter is shown (if auth destination is splash)
  /// - During `running` phase: SplashRouter is PERMANENTLY removed, only AuthenticatedApp/UnauthenticatedApp
  ///
  /// This ensures SplashScreen is structurally impossible to reappear after bootstrapping.
  List<Page<dynamic>> _buildPages(
    AsyncValue<bool> firebaseState,
    AppPhase appPhase,
    AuthDestination authDestination,
    AuthState authState,
  ) {
    // Handle Firebase loading state (pre-theme: use fixed brand colors)
    if (firebaseState.isLoading) {
      return [
        MaterialPage<dynamic>(
          key: const ValueKey('loading'),
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(gradient: PreAppColors.authGradient),
              child: Center(
                child: LoadingSpinnerVariants.white(size: 48, strokeWidth: 3),
              ),
            ),
          ),
        ),
      ];
    }

    // Handle Firebase error state
    if (firebaseState.hasError) {
      return [
        MaterialPage<dynamic>(
          key: const ValueKey('error'),
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error initializing app',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    firebaseState.error.toString(),
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // Firebase initialized but failed (pre-theme: use fixed brand colors)
    if (firebaseState.value != true) {
      return [
        MaterialPage<dynamic>(
          key: const ValueKey('firebase-failed'),
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(gradient: PreAppColors.authGradient),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: PreAppColors.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Firebase initialization failed',
                      style: AppTheme.lightTheme.textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please restart the app',
                      style: AppTheme.lightTheme.textTheme.bodyMedium!.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];
    }

    // Firebase is ready - build pages based on app phase and auth destination
    // CRITICAL: SplashScreen exists ONLY during bootstrapping phase.
    // Once app transitions to running phase, SplashScreen is structurally unreachable.
    if (kDebugMode) {
      debugPrint(
        '🏠 [AppRoot] Building pages for phase: $appPhase, destination: $authDestination',
      );
    }

    // CRITICAL: During bootstrapping phase, show SplashRouter if destination is splash
    // During running phase, SplashRouter is PERMANENTLY removed from widget tree
    if (appPhase == AppPhase.bootstrapping &&
        authDestination == AuthDestination.splash) {
      return [
        MaterialPage<dynamic>(
          key: const ValueKey('splash'),
          child: const SplashScreen(),
        ),
      ];
    }

    // During running phase OR when destination is not splash, show AuthenticatedApp/UnauthenticatedApp
    return switch (authDestination) {
      AuthDestination.splash => [
        // This should never be reached during running phase
        // But if it is, show auth screen as fallback (splash is unreachable)
        MaterialPage<dynamic>(
          key: const ValueKey('auth-fallback'),
          child: const AuthScreen(isSignIn: true),
        ),
      ],
      AuthDestination.auth => [
        MaterialPage<dynamic>(
          key: const ValueKey('auth'),
          // Check if onboarding has been completed
          // First-time users see OnboardingScreen, returning users see AuthScreen
          child: const _AuthOrOnboardingRouter(),
        ),
      ],
      AuthDestination.pinSetup => [
        MaterialPage<dynamic>(
          key: const ValueKey('pin-setup'),
          child: const PinSetupScreen(),
        ),
      ],
      AuthDestination.home => [
        MaterialPage<dynamic>(
          key: const ValueKey('home'),
          // Wrap home with AppLockOverlay to show lock screen when locked
          child: const AppLockOverlay(child: HomeScreen()),
        ),
      ],
      AuthDestination.gracePeriod => [
        MaterialPage<dynamic>(
          key: const ValueKey('grace-period'),
          child: authState is AuthStateGracePeriod
              ? AccountGracePeriodScreen(
                  deletionStatus: AccountDeletionStatus(
                    daysRemaining: authState.daysRemaining,
                    canRestore: authState.canRestore,
                    canStartAfresh: authState.canStartAfresh,
                    recoveryDeadline: authState.recoveryDeadline,
                    deletedAt: authState.deletedAt,
                  ),
                )
              : const SizedBox.shrink(), // Fallback if state mismatch
        ),
      ],
    };
  }

  /// One-time debug logging for font configuration (debug builds only).
  /// Helps verify that Manrope font is properly registered and applied.
  static bool _fontDebugLogged = false;
  void _logFontDebugOnce(ThemeData lightTheme, ThemeData darkTheme) {
    if (_fontDebugLogged) return;
    _fontDebugLogged = true;

    debugPrint(
      '🔤 [Font Debug] Theme fontFamily: ${lightTheme.textTheme.bodyMedium?.fontFamily}',
    );
    debugPrint('🔤 [Font Debug] Light theme configured with Manrope');
    debugPrint('🔤 [Font Debug] Dark theme configured with Manrope');
  }
}

/// Router widget that shows OnboardingScreen for first-time users
/// and AuthScreen for returning users
class _AuthOrOnboardingRouter extends ConsumerWidget {
  const _AuthOrOnboardingRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    return onboardingCompleted.when(
      data: (completed) {
        if (completed) {
          // Returning user - show auth screen directly
          return const AuthScreen(isSignIn: true);
        } else {
          // First-time user - show onboarding
          return const OnboardingScreen();
        }
      },
      // Show AuthScreen while loading to avoid flicker when navigating to auth (e.g. after logout).
      // Returning users see AuthScreen immediately; first-time users may briefly see it then OnboardingScreen.
      loading: () => const AuthScreen(isSignIn: true),
      error: (_, __) => const AuthScreen(isSignIn: true),
    );
  }
}
