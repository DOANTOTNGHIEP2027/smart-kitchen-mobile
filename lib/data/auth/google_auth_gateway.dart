import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../network/api_exception.dart';
import 'firebase_bootstrapper.dart';

abstract interface class GoogleAuthGateway {
  /// Returns null only when the user closes the native account picker.
  Future<String?> signInWithGoogle();

  Future<void> signOut();
}

class GoogleAuthGatewayImpl implements GoogleAuthGateway {
  GoogleAuthGatewayImpl({GoogleSignIn? googleSignIn, FirebaseAuth? firebaseAuth})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<String?> signInWithGoogle() async {
    final setupStatus = Get.isRegistered<FirebaseSetupStatus>()
        ? Get.find<FirebaseSetupStatus>()
        : FirebaseSetupStatus.unavailable;
    if (setupStatus != FirebaseSetupStatus.ready) {
      throw const BusinessException(
        'ERR_AUTH_FIREBASE_UNAVAILABLE',
        'Firebase is not configured for this build.',
      );
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user?.getIdToken();
  }

  @override
  Future<void> signOut() async {
    await Future.wait<void>([_googleSignIn.signOut(), _firebaseAuth.signOut()]);
  }
}
