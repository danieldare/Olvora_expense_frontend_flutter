import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../utils/app_logger.dart';

final firebaseInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    if (Firebase.apps.isEmpty) {
      // Use FlutterFire-generated options (firebase_options.dart from `flutterfire configure`)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return true;
  } catch (e) {
    AppLogger.e('Firebase initialization error', tag: 'Firebase', error: e);
    AppLogger.i(
      'Ensure Firebase is configured: run `flutterfire configure` and add your app bundle/package IDs in Firebase Console.',
      tag: 'Firebase',
    );
    return false;
  }
});
