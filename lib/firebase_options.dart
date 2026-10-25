// File generated for World of IT Firebase configuration (world-of-iot-hub).
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
    apiKey: 'AIzaSyAZ8bHRixieDYqvexQyrDmaCEPO8MGaiSE',
    appId: '1:444951093704:web:98dfa2b4c99a04d8e6a0fd',
    messagingSenderId: '444951093704',
    projectId: 'world-of-iot-hub',
    authDomain: 'world-of-iot-hub.firebaseapp.com',
    databaseURL: 'https://world-of-iot-hub-default-rtdb.firebaseio.com',
    storageBucket: 'world-of-iot-hub.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCIq7EqH9feI9vBkhYJgZ8iAglty0_iuVI',
    appId: '1:444951093704:android:2f1e5bd2896d82f6e6a0fd',
    messagingSenderId: '444951093704',
    projectId: 'world-of-iot-hub',
    databaseURL: 'https://world-of-iot-hub-default-rtdb.firebaseio.com',
    storageBucket: 'world-of-iot-hub.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD14uIS-cj8h5vQPcwmtuJO-G0grStrV-w',
    appId: '1:444951093704:ios:e43df725024d3869e6a0fd',
    messagingSenderId: '444951093704',
    projectId: 'world-of-iot-hub',
    databaseURL: 'https://world-of-iot-hub-default-rtdb.firebaseio.com',
    storageBucket: 'world-of-iot-hub.firebasestorage.app',
    iosBundleId: 'com.example.worldOfIot',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD14uIS-cj8h5vQPcwmtuJO-G0grStrV-w',
    appId: '1:444951093704:ios:e43df725024d3869e6a0fd',
    messagingSenderId: '444951093704',
    projectId: 'world-of-iot-hub',
    databaseURL: 'https://world-of-iot-hub-default-rtdb.firebaseio.com',
    storageBucket: 'world-of-iot-hub.firebasestorage.app',
    iosBundleId: 'com.example.worldOfIot',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyAZ8bHRixieDYqvexQyrDmaCEPO8MGaiSE',
    appId: '1:444951093704:web:98dfa2b4c99a04d8e6a0fd',
    messagingSenderId: '444951093704',
    projectId: 'world-of-iot-hub',
    authDomain: 'world-of-iot-hub.firebaseapp.com',
    databaseURL: 'https://world-of-iot-hub-default-rtdb.firebaseio.com',
    storageBucket: 'world-of-iot-hub.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAZ8bHRixieDYqvexQyrDmaCEPO8MGaiSE',
    appId: '1:444951093704:web:98dfa2b4c99a04d8e6a0fd',
    messagingSenderId: '444951093704',
    projectId: 'world-of-iot-hub',
    authDomain: 'world-of-iot-hub.firebaseapp.com',
    databaseURL: 'https://world-of-iot-hub-default-rtdb.firebaseio.com',
    storageBucket: 'world-of-iot-hub.firebasestorage.app',
  );
}
