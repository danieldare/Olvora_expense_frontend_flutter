// Copy this file to firebase_options.dart and run: flutterfire configure
// Do not commit firebase_options.dart if it contains real API keys.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder [FirebaseOptions]. Copy to firebase_options.dart and run
/// `flutterfire configure` to generate real values.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'run flutterfire configure.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'run flutterfire configure.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_AFTER_FLUTTERFIRE_CONFIGURE',
    appId: '1:0:android:0',
    messagingSenderId: '0',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_AFTER_FLUTTERFIRE_CONFIGURE',
    appId: '1:0:ios:0',
    messagingSenderId: '0',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.appspot.com',
    androidClientId: '0.apps.googleusercontent.com',
    iosClientId: '0.apps.googleusercontent.com',
    iosBundleId: 'com.example.yourapp',
  );
}
