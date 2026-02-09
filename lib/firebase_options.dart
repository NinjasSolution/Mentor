import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Not supported on this platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCYgvQtWUewh1LDsWIoxWr29V_ARhMAucw',
    appId: '1:661763042710:web:b36c3832930a6403dc81b7',
    messagingSenderId: '661763042710',
    projectId: 'bgnu-mentor',
    authDomain: 'bgnu-mentor.firebaseapp.com',
    storageBucket: 'bgnu-mentor.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCYgvQtWUewh1LDsWIoxWr29V_ARhMAucw',
    appId: '1:661763042710:android:79035686f3ee26c3dc81b7',
    messagingSenderId: '661763042710',
    projectId: 'bgnu-mentor',
    storageBucket: 'bgnu-mentor.firebasestorage.app',
  );
}
