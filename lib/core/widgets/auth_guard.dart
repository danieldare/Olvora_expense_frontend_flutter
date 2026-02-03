import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/loading_spinner.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../theme/app_theme.dart';

/// A widget that protects its child by requiring authentication.
/// If the user is not authenticated, they will be redirected to the sign-in screen.
class AuthGuard extends ConsumerWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // Listen to auth state changes - redirect if not authenticated
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      // Immediately redirect if not authenticated (even during loading)
      if (next is AuthStateUnauthenticated && context.mounted) {
        // User is not authenticated - immediately redirect to sign-in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthScreen(isSignIn: true)),
              (route) => false,
            );
          }
        });
      }
    });

    // CRITICAL: Never show content if not authenticated
    // Show loading while checking auth or during authentication
    if (authState is AuthStateAuthenticating ||
        authState is AuthStateEstablishingSession) {
      return Scaffold(
        body: Center(
          child: LoadingSpinner.large(color: AppTheme.warningColor),
        ),
      );
    }

    // CRITICAL: If auth check is complete and user is not authenticated,
    // immediately redirect (don't show any content)
    if (authState is! AuthStateAuthenticated) {
      // Redirect immediately without showing content
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen(isSignIn: true)),
            (route) => false,
          );
        }
      });
      // Return loading while redirect happens
      return Scaffold(
        body: Center(
          child: LoadingSpinner.large(color: AppTheme.warningColor),
        ),
      );
    }

    // User is authenticated AND auth check is complete - show the protected content
    return child;
  }
}

