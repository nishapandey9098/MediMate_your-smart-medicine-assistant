// lib/core/config/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// IMPORTANT: You need to get these values from Firebase Console
/// 1. Go to Project Settings (gear icon)
/// 2. Scroll down to "Your apps"
/// 3. Click on your Android app
/// 4. Copy the values and replace below

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not supported yet',
      );
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

  // Get them from Firebase Console > Project Settings > Your apps
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDf3wdoWt8Vb-0qd_8IMVC8YAyQgi79yxA', // Replace with actual API key
    appId: '1:80061953972:android:f1e4879b0f78ddef2664e1', // Replace with actual App ID
    messagingSenderId: '80061953972', // Replace with actual sender ID
    projectId: 'medimate-47d14', // Replace with your project ID
    storageBucket: 'medimate-47d14.firebasestorage.app', // Replace with storage bucket
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDf3wdoWt8Vb-0qd_8IMVC8YAyQgi79yxA',
    appId: '1:80061953972:android:f1e4879b0f78ddef2664e1',
    messagingSenderId: '80061953972',
    projectId: 'medimate-47d14',
    storageBucket: 'medimate-47d14.firebasestorage.app',
    iosBundleId: 'com.medimate.app',
  );
}

// INSTRUCTIONS TO GET YOUR VALUES:
// 1. Go to Firebase Console: console.firebase.google.com
// 2. Select your MediMate project
// 3. Click the gear icon (⚙️) → Project settings
// 4. Scroll down to "Your apps" section
// 5. Click on your Android app
// 6. You'll see all these values - copy them here
//
// Example what you'll see:
// apiKey: "AIzaSyAbc123..." 
// appId: "1:123456789:android:abc123..."
// messagingSenderId: "123456789"
// projectId: "medimate-abc123"
// storageBucket: "medimate-abc123.appspot.com"