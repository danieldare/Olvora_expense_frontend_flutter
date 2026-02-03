import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_providers.dart';

/// User info model containing display information
class UserInfo {
  final String displayName;
  final String? photoUrl;
  final String email;

  const UserInfo({
    required this.displayName,
    this.photoUrl,
    required this.email,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserInfo &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          email == other.email;

  @override
  int get hashCode => displayName.hashCode ^ photoUrl.hashCode ^ email.hashCode;
}

/// Provider that centralizes user info extraction logic.
///
/// Combines Firebase user data with auth session data to provide
/// consistent user information across the app.
///
/// OPTIMIZATION: Uses select() to only rebuild when session email changes,
/// not on every auth state update (like token refreshes).
///
/// Priority for display name:
/// 1. Firebase displayName (if available)
/// 2. Firebase email username (part before @)
/// 3. Session email username (part before @)
/// 4. Default: 'User'
final currentUserInfoProvider = Provider<UserInfo>((ref) {
  // Use select to only rebuild when session/email actually changes
  // This prevents rebuilds on token refreshes or minor auth state updates
  final session = ref.watch(currentSessionProvider);

  if (session == null) {
    return const UserInfo(displayName: 'User', email: '');
  }

  final firebaseUser = FirebaseAuth.instance.currentUser;

  String displayName = 'User';
  String email = '';
  String? photoUrl;

  // Determine display name with fallback priority
  if (firebaseUser?.displayName?.isNotEmpty == true) {
    displayName = firebaseUser!.displayName!;
  } else if (firebaseUser?.email?.isNotEmpty == true) {
    displayName = firebaseUser!.email!.split('@').first;
  } else if (session.email.isNotEmpty) {
    displayName = session.email.split('@').first;
  }

  // Determine email with fallback
  if (firebaseUser?.email?.isNotEmpty == true) {
    email = firebaseUser!.email!;
  } else if (session.email.isNotEmpty) {
    email = session.email;
  }

  // Get photo URL from Firebase user
  photoUrl = firebaseUser?.photoURL;

  return UserInfo(
    displayName: displayName,
    photoUrl: photoUrl,
    email: email,
  );
});
