import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCPRZeLm2MSUMhvGXJeJ_x1zwcTlkPNZKI",
    appId: "1:641729749448:web:cac812d3238d59cbcaa0fd",
    messagingSenderId: "641729749448",
    projectId: "smartocr-5610d",
    authDomain: "smartocr-5610d.firebaseapp.com",
    storageBucket: "smartocr-5610d.firebasestorage.app",
    measurementId: "G-BR5Y4HME9D",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCPRZeLm2MSUMhvGXJeJ_x1zwcTlkPNZKI",
    appId: "1:641729749448:web:cac812d3238d59cbcaa0fd",
    messagingSenderId: "641729749448",
    projectId: "smartocr-5610d",
    storageBucket: "smartocr-5610d.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyCPRZeLm2MSUMhvGXJeJ_x1zwcTlkPNZKI",
    appId: "1:641729749448:web:cac812d3238d59cbcaa0fd",
    messagingSenderId: "641729749448",
    projectId: "smartocr-5610d",
    storageBucket: "smartocr-5610d.firebasestorage.app",
    iosBundleId: "com.snapbudget.snapbudgetOcr",
  );
}