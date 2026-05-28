import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC56P7mbfZtw_y0j51WmJKV2U6IBbCwl38',
    appId: '1:213800371663:web:9f902e3323625b45703eba',
    messagingSenderId: '213800371663',
    projectId: 'fir-8b7cc',
    authDomain: 'fir-8b7cc.firebaseapp.com',
    storageBucket: 'fir-8b7cc.firebasestorage.app',
    measurementId: 'G-7PMHY6NJJT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAhPwZYV9WF03tsna4vrI7TlgwkRxVJGSU',
    appId: '1:213800371663:android:744babf684c2d0da703eba',
    messagingSenderId: '213800371663',
    projectId: 'fir-8b7cc',
    storageBucket: 'fir-8b7cc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA5R-BUPR2OY-Ju6FmZ4667FZga06YVutM',
    appId: '1:213800371663:ios:b25c9acc4ee7f9a1703eba',
    messagingSenderId: '213800371663',
    projectId: 'fir-8b7cc',
    storageBucket: 'fir-8b7cc.firebasestorage.app',
    iosBundleId: 'com.example.chatApp',
  );
}
