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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAmkkG3PrDdwUJ9OvNDpcK4vvqHwE1vDYI',
    authDomain: 'trustshieldai-8f2fd.firebaseapp.com',
    projectId: 'trustshieldai-8f2fd',
    storageBucket: 'trustshieldai-8f2fd.firebasestorage.app',
    messagingSenderId: '19970207099',
    appId: '1:19970207099:web:8e3d817239b370f71261de',
    measurementId: 'G-LLBF43X1XV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDprILzSUz3ZqcA8SRrE5iD6tk2OCzFwM0',
    appId: '1:19970207099:android:0bacf46a1e18720f1261de',
    messagingSenderId: '19970207099',
    projectId: 'trustshieldai-8f2fd',
    storageBucket: 'trustshieldai-8f2fd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDprILzSUz3ZqcA8SRrE5iD6tk2OCzFwM0',
    appId: '1:19970207099:ios:0bacf46a1e18720f1261de', // Note: Needs real iOS app ID when setting up iOS
    messagingSenderId: '19970207099',
    projectId: 'trustshieldai-8f2fd',
    storageBucket: 'trustshieldai-8f2fd.firebasestorage.app',
    iosClientId: '19970207099-fh565ep4r7husr76hm1rt9lf5r2q5rcj.apps.googleusercontent.com',
    iosBundleId: 'com.trustshield.ai',
  );
}
