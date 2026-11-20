import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../network/api_exception.dart';

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
  /// error banner (§14). `null` CHỈ dành cho trường hợp huỷ: đăng nhập xong
  /// mà không có token → [GoogleAuthTokenMissingException] (OD-38).
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

/// Firebase đăng nhập xong nhưng không trả được ID token — KHÔNG được coi là
/// user huỷ, nếu không nút Google im lặng không làm gì (OD-38).
class GoogleAuthTokenMissingException implements Exception {
  const GoogleAuthTokenMissingException();

  @override
  String toString() => 'ERR_AUTH_GOOGLE_TOKEN_MISSING';
}

class GoogleAuthGatewayImpl implements GoogleAuthGateway {
  GoogleAuthGatewayImpl({GoogleSignIn? googleSignIn, FirebaseAuth? firebaseAuth})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const <String>['email']),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

  /// Lỗi SDK được đổi sang lỗi của app NGAY tại đây (giống `_unwrap` của
  /// `*Api`) — store không phải biết kiểu lỗi của Firebase/Google (OD-38):
  /// - mất mạng → [NetworkException];
  /// - `sign_in_failed` (thường do thiếu SHA-1/cấu hình OAuth) →
  ///   [GoogleAuthUnavailableException].
  @override
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user hủy — không phải exception

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        // Thoát phiên native để lần bấm sau picker hiện lại.
        await _signOutQuietly();
        throw const GoogleAuthTokenMissingException();
      }
      return idToken;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') throw NetworkException();
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'network_error') throw NetworkException();
      if (e.code == 'sign_in_failed') {
        developer.log('Google sign-in failed: ${e.message}', name: 'auth');
        throw const GoogleAuthUnavailableException();
      }
      rethrow;
    }
  }

  Future<void> _signOutQuietly() async {
    try {
      await signOut();
    } catch (error) {
      developer.log('Google sign-out after missing token failed',
          name: 'auth', error: error);
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
