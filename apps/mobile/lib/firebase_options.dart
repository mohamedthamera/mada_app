import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for fuchsia - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCoTS32tgSD-SRv2HsBU8bYxabN6UMoLsw',
    appId: '1:360671311223:web:9a861d5a01a7c2cc095d72',
    messagingSenderId: '360671311223',
    projectId: 'evrest-67b8a',
    authDomain: 'evrest-67b8a.firebaseapp.com',
    storageBucket: 'evrest-67b8a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCoTS32tgSD-SRv2HsBU8bYxabN6UMoLsw',
    appId: '1:360671311223:ios:9a861d5a01a7c2cc095d72',
    messagingSenderId: '360671311223',
    projectId: 'evrest-67b8a',
    storageBucket: 'evrest-67b8a.firebasestorage.app',
    iosClientId:
        '360671311223-jtnv1k75o189oer6b9u78nuo9id2dvcs.apps.googleusercontent.com',
    iosBundleId: 'com.example.madaMobile',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAY5F4UHg4R2ct04gJpp0LT1jFBzKIMN58',
    appId: '1:360671311223:android:35387b3e0b7785a7095d72',
    messagingSenderId: '360671311223',
    projectId: 'evrest-67b8a',
    storageBucket: 'evrest-67b8a.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCoTS32tgSD-SRv2HsBU8bYxabN6UMoLsw',
    appId: '1:360671311223:ios:9a861d5a01a7c2cc095d72',
    messagingSenderId: '360671311223',
    projectId: 'evrest-67b8a',
    storageBucket: 'evrest-67b8a.firebasestorage.app',
    iosClientId:
        '360671311223-jtnv1k75o189oer6b9u78nuo9id2dvcs.apps.googleusercontent.com',
    iosBundleId: 'com.example.madaMobile',
  );
}
