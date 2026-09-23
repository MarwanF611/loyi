// Placeholder options for the local `demo-loyi` emulator project.
//
// When the real Firebase project exists, regenerate this file with:
//   flutterfire configure --project=<your-project-id>
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final appId = switch (defaultTargetPlatform) {
      _ when kIsWeb => '1:000000000000:web:0000000000000000',
      TargetPlatform.android => '1:000000000000:android:0000000000000000',
      _ => '1:000000000000:ios:0000000000000000',
    };
    return FirebaseOptions(
      apiKey: 'demo-api-key',
      appId: appId,
      messagingSenderId: '000000000000',
      projectId: 'demo-loyi',
      authDomain: 'demo-loyi.firebaseapp.com',
      iosBundleId: 'be.loyi.loyi',
    );
  }
}
