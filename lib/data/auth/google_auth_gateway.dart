import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Issue #16 — gateway mỏng quanh Firebase Auth + Google Sign-In
/// (fe-app-shell.md §9, quyết định D7).
///
/// Gateway dừng ở việc lấy Firebase ID token. Lệnh gọi
/// `POST /api/v1/auth/google` là trách nhiệm của `fe-onboarding` (#28) —
/// gateway này KHÔNG được gọi BE.
abstract class GoogleAuthGateway {
  /// Trả về Firebase ID token để gửi dưới dạng `{idToken}` tới
  /// `POST /api/v1/auth/google`, hoặc `null` nếu user hủy picker native.
  ///
  /// `null` KHÔNG phải lỗi — caller phải coi đây là no-op, không hiển thị
  /// error banner (§14).
  Future<String?> signInWithGoogle();

  Future<void> signOut();
}

/// Fallback khi Firebase chưa được cấu hình cho app/platform hiện tại.
///
/// Bootstrap vẫn cho phép ứng dụng khởi động trong trạng thái này; luồng
/// Google sign-in trả về lỗi nghiệp vụ có thể hiển thị thay vì truy cập
/// FirebaseAuth chưa được khởi tạo và làm app crash.
class UnavailableGoogleAuthGateway implements GoogleAuthGateway {
  const UnavailableGoogleAuthGateway();

  @override
  Future<String?> signInWithGoogle() =>
      Future<String?>.error(const GoogleAuthUnavailableException());

  @override
  Future<void> signOut() async {}
}

class GoogleAuthUnavailableException implements Exception {
  const GoogleAuthUnavailableException();

  @override
  String toString() => 'ERR_AUTH_FIREBASE_UNAVAILABLE';
}

class GoogleAuthGatewayImpl implements GoogleAuthGateway {
  GoogleAuthGatewayImpl({GoogleSignIn? googleSignIn, FirebaseAuth? firebaseAuth})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const <String>['email']),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<String?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user hủy — không phải exception

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user?.getIdToken();
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
