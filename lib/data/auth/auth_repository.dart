import 'package:dio/dio.dart';

import '../../domain/auth/auth_session.dart';
import '../network/api_response.dart';

/// Gọi các endpoint `/api/v1/auth/*` (fe-onboarding.md Flow 2–5, 8, 9).
///
/// Field JSON dùng camelCase theo `docs/contracts/openapi/auth-jwt.yaml` —
/// `fe-onboarding.md` viết snake_case (`id_token`, `full_name`, ...) là drift
/// có trước `docs/contracts/naming-convention.md` (chốt 23/08/2026).
///
/// Lỗi trồi lên dưới dạng `DioException` mang `ApiException` ở `.error`, do
/// pipeline interceptor của shell gắn vào (fe-app-shell.md §7.6). Repository
/// KHÔNG bắt lỗi — store mới là nơi rẽ nhánh theo `.code`.
class AuthRepository {
  const AuthRepository(this._dio);

  static const String _google = '/api/v1/auth/google';
  static const String _register = '/api/v1/auth/email/register';
  static const String _sendOtp = '/api/v1/auth/email/send-otp';
  static const String _verifyOtp = '/api/v1/auth/email/verify-otp';
  static const String _login = '/api/v1/auth/email/login';
  static const String _qrJoin = '/api/v1/auth/qr-join';
  static const String _upgradeProfile = '/api/v1/auth/upgrade-profile';

  final Dio _dio;

  Future<AuthSession> loginWithGoogle(String idToken) async {
    final data = await _post(_google, <String, dynamic>{'idToken': idToken});
    return AuthSession.fromJson(data);
  }

  Future<RegisterResult> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final data = await _post(_register, <String, dynamic>{
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    return RegisterResult.fromJson(data);
  }

  /// Luôn `200` kể cả khi email không tồn tại (chống dò email) — caller không
  /// bao giờ cần xử lý "email không tồn tại" như một state riêng.
  Future<void> sendOtp(String email) =>
      _post(_sendOtp, <String, dynamic>{'email': email});

  Future<AuthSession> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _post(
      _verifyOtp,
      <String, dynamic>{'email': email, 'otp': otp},
    );
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final data = await _post(
      _login,
      <String, dynamic>{'email': email, 'password': password},
    );
    return AuthSession.fromJson(data);
  }

  /// Dành cho user **chưa có JWT**. User đã đăng nhập nhưng chưa có household
  /// phải dùng `HouseholdRepository.join` — xem bảng định tuyến Flow 8.
  Future<QrJoinResult> qrJoin({
    required String inviteCode,
    String? displayName,
  }) async {
    final data = await _post(_qrJoin, <String, dynamic>{
      'inviteCode': inviteCode,
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
    });
    return QrJoinResult.fromJson(data);
  }

  Future<UpgradeProfileResult> upgradeProfile({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final data = await _post(_upgradeProfile, <String, dynamic>{
      'email': email,
      'password': password,
      if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
    });
    return UpgradeProfileResult.fromJson(data);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<dynamic>(path, data: body);
    return unwrapEnvelope(response);
  }
}
