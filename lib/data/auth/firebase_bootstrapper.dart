import 'package:firebase_core/firebase_core.dart';

enum FirebaseSetupStatus { ready, unavailable }

abstract final class FirebaseBootstrapper {
  /// Missing platform Firebase files are an environment/setup concern, not a
  /// reason to block the non-Google parts of the app from opening.
  static Future<FirebaseSetupStatus> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      return FirebaseSetupStatus.ready;
    } on FirebaseException {
      return FirebaseSetupStatus.unavailable;
    }
  }
}
