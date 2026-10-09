// File configured for RoadMate Firebase Project
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static String _env(String key, String fallback) {
    try {
      final val = dotenv.env[key];
      if (val != null &&
          val.trim().isNotEmpty &&
          !val.contains('your_') &&
          !val.contains('here')) {
        return val.trim();
      }
    } catch (_) {}
    return fallback;
  }

  static bool get isPlaceholder {
    try {
      final key = currentPlatform.apiKey;
      return key.isEmpty ||
          key.contains('Placeholder') ||
          key.contains('your_') ||
          key.contains('here');
    } catch (_) {
      return true;
    }
  }

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

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _env('FIREBASE_API_KEY', 'AIzaSyCOoeb886uVGkZrGMdsgha9UGPhV5lIWVc'),
        appId: _env('FIREBASE_WEB_APP_ID', '1:647731252131:web:roadmate'),
        messagingSenderId:
            _env('FIREBASE_MESSAGING_SENDER_ID', '647731252131'),
        projectId: _env('FIREBASE_PROJECT_ID', 'road-mate-a9f6e'),
        authDomain: _env('FIREBASE_AUTH_DOMAIN', 'road-mate-a9f6e.firebaseapp.com'),
        storageBucket: _env('FIREBASE_STORAGE_BUCKET', 'road-mate-a9f6e.firebasestorage.app'),
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _env(
          'FIREBASE_ANDROID_API_KEY',
          _env('FIREBASE_API_KEY', 'AIzaSyCOoeb886uVGkZrGMdsgha9UGPhV5lIWVc'),
        ),
        appId: _env('FIREBASE_ANDROID_APP_ID',
            '1:647731252131:android:6c9d79f4217928232b6816'),
        messagingSenderId:
            _env('FIREBASE_MESSAGING_SENDER_ID', '647731252131'),
        projectId: _env('FIREBASE_PROJECT_ID', 'road-mate-a9f6e'),
        storageBucket: _env('FIREBASE_STORAGE_BUCKET', 'road-mate-a9f6e.firebasestorage.app'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _env('FIREBASE_IOS_API_KEY', 'AIzaSyCOoeb886uVGkZrGMdsgha9UGPhV5lIWVc'),
        appId: _env('FIREBASE_IOS_APP_ID', '1:647731252131:ios:abcdef123456'),
        messagingSenderId:
            _env('FIREBASE_MESSAGING_SENDER_ID', '647731252131'),
        projectId: _env('FIREBASE_PROJECT_ID', 'road-mate-a9f6e'),
        storageBucket: _env('FIREBASE_STORAGE_BUCKET', 'road-mate-a9f6e.firebasestorage.app'),
      );
}
