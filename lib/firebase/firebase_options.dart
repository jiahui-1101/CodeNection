import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static Future<FirebaseOptions> get currentPlatform async {
    await dotenv.load(fileName: ".env.development");

    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY_WEB'),
    appId: dotenv.get('FIREBASE_APP_ID_WEB'),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    authDomain: dotenv.get('FIREBASE_AUTH_DOMAIN'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY_ANDROID'),
    appId: dotenv.get('FIREBASE_APP_ID_ANDROID'),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY_IOS'),
    appId: dotenv.get('FIREBASE_APP_ID_IOS'),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: dotenv.get('FIREBASE_IOS_BUNDLE_ID'),
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: dotenv.get('FIREBASE_API_KEY_WEB'),
    appId: dotenv.get('FIREBASE_APP_ID_WEB'),
    messagingSenderId: dotenv.get('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: dotenv.get('FIREBASE_PROJECT_ID'),
    authDomain: dotenv.get('FIREBASE_AUTH_DOMAIN'),
    storageBucket: dotenv.get('FIREBASE_STORAGE_BUCKET'),
  );
}