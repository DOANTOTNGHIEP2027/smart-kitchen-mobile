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

class GoogleAuthGatewayImpl implements GoogleAuthGateway {
  GoogleAuthGatewayImpl({GoogleSignIn? googleSignIn, FirebaseAuth? firebaseAuth})
      : _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: const <String>['email']),
        _injectedAuth = firebaseAuth;

  final GoogleSignIn _googleSignIn;
  final FirebaseAuth? _injectedAuth;

  /// Resolve **lazy**, không phải trong constructor: `Firebase.initializeApp()`
  /// được phép thất bại (chưa có file config platform — open question Q6) và
  /// `bootstrap.dart` cố tình nuốt lỗi đó để app vẫn boot. Nếu constructor
  /// chạm `FirebaseAuth.instance`, việc chỉ *đăng ký* gateway trong DI đã đủ
  /// ném lỗi và làm chết toàn bộ route onboarding — kể cả các luồng email/QR
  /// vốn không dùng Google chút nào.
  FirebaseAuth get _firebaseAuth => _injectedAuth ?? FirebaseAuth.instance;

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
