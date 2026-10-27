// Template Firebase Options for WiFi Sync.
// Connect your own free Firebase project by replacing the placeholders below
// or by entering your credentials directly in the in-app Firebase Setup screen.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:1234567890:web:abcdef012345',
    messagingSenderId: '1234567890',
    projectId: 'your-firebase-project-id',
    authDomain: 'your-firebase-project-id.firebaseapp.com',
    databaseURL: 'https://your-firebase-project-id-default-rtdb.firebaseio.com',
    storageBucket: 'your-firebase-project-id.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:1234567890:android:abcdef012345',
    messagingSenderId: '1234567890',
    projectId: 'your-firebase-project-id',
    databaseURL: 'https://your-firebase-project-id-default-rtdb.firebaseio.com',
    storageBucket: 'your-firebase-project-id.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:1234567890:ios:abcdef012345',
    messagingSenderId: '1234567890',
    projectId: 'your-firebase-project-id',
    databaseURL: 'https://your-firebase-project-id-default-rtdb.firebaseio.com',
    storageBucket: 'your-firebase-project-id.firebasestorage.app',
    iosBundleId: 'com.example.worldOfIot',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:1234567890:ios:abcdef012345',
    messagingSenderId: '1234567890',
    projectId: 'your-firebase-project-id',
    databaseURL: 'https://your-firebase-project-id-default-rtdb.firebaseio.com',
    storageBucket: 'your-firebase-project-id.firebasestorage.app',
    iosBundleId: 'com.example.worldOfIot',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:1234567890:web:abcdef012345',
    messagingSenderId: '1234567890',
    projectId: 'your-firebase-project-id',
    authDomain: 'your-firebase-project-id.firebaseapp.com',
    databaseURL: 'https://your-firebase-project-id-default-rtdb.firebaseio.com',
    storageBucket: 'your-firebase-project-id.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:1234567890:web:abcdef012345',
    messagingSenderId: '1234567890',
    projectId: 'your-firebase-project-id',
    authDomain: 'your-firebase-project-id.firebaseapp.com',
    databaseURL: 'https://your-firebase-project-id-default-rtdb.firebaseio.com',
    storageBucket: 'your-firebase-project-id.firebasestorage.app',
  );
}
