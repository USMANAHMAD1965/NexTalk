part of '../app.dart';

class FirebaseBootstrap {
  static Future<bool> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (_usesPlaceholderConfig(options)) {
        return false;
      }
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      return true;
    } on Object {
      return false;
    }
  }

  static bool _usesPlaceholderConfig(FirebaseOptions options) {
    return options.apiKey.startsWith('YOUR_') ||
        options.appId.startsWith('1:000000000000') ||
        options.projectId == 'YOUR_PROJECT_ID' ||
        options.messagingSenderId == '000000000000';
  }
}
