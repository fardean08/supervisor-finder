// Placeholder Firebase options file.
// Replace this file by running:
//
// dart pub global activate flutterfire_cli
// flutterfire configure
//
// The app includes an in-memory fallback mode, so it will still open and
// work fully (with local-only data) without Firebase. Real login/sign-up
// through Firebase and persistent shared storage needs the generated
// options file.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase has not been configured yet. Run flutterfire configure to generate firebase_options.dart.',
    );
  }
}
