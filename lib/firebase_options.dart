import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBsy9Edl6YRSucwmSX5xZL_crnAPRVyAbc',
    appId: '1:335612678883:web:335bd597d98c1cc38c6bd6',
    messagingSenderId: '335612678883',
    projectId: 'masagani-app-206',
    authDomain: 'masagani-app-206.firebaseapp.com',
    storageBucket: 'masagani-app-206.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6OfjVq7YfyF61C_qZ6C2lxES1qt1srZA',
    appId: '1:335612678883:android:776936caf61d16dc8c6bd6',
    appId: '1:335612678883:android:692364efb0eb429d8c6bd6',
    messagingSenderId: '335612678883',
    projectId: 'masagani-app-206',
    storageBucket: 'masagani-app-206.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCHpAXrNyqWxoCXTGoe-7Cst0rUlHA5t30',
    appId: '1:335612678883:ios:7a3f5e39dc5a5b4b8c6bd6',
    messagingSenderId: '335612678883',
    projectId: 'masagani-app-206',
    storageBucket: 'masagani-app-206.firebasestorage.app',
    iosBundleId: 'com.example.flutterCc206Masagani',
  );

}