import 'user_summary.dart';

/// Phiên đã xác thực — dùng chung cho `/auth/google`, `/auth/email/login`,
/// `/auth/email/verify-otp` (schema `GoogleLoginResponse` /
/// `EmailAuthSessionResponse` trong `auth-jwt.yaml`).
///
/// Lưu ý: response **không** mang `householdId`/`role`. Hai giá trị đó chỉ có
/// trong claim của access token — đọc qua `SessionStore.householdId`/`.role`
/// (fe-app-shell.md §8.1). Riêng `/auth/qr-join` là ngoại lệ, xem [QrJoinResult].
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
    this.accountLinked = false,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserSummary user;

  /// `true` chỉ khi Google UID vừa được link vào một user EMAIL đã tồn tại —
  /// FE hiện toast một lần (Flow 2).
  final bool accountLinked;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: json['expiresIn'] as int? ?? 0,
        user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
        accountLinked: json['accountLinked'] as bool? ?? false,
      );
}

/// Kết quả `POST /auth/email/register` (schema `RegisterResponse`).
/// Chưa phát hành token — user phải verify OTP trước.
class RegisterResult {
  const RegisterResult({
    required this.requiresOtpVerification,
    required this.message,
    required this.email,
  });

  final bool requiresOtpVerification;
  final String message;
  final String email;

  factory RegisterResult.fromJson(Map<String, dynamic> json) => RegisterResult(
        requiresOtpVerification:
            json['requiresOtpVerification'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        email: json['email'] as String,
      );
}

/// Kết quả `POST /auth/qr-join` (schema `QrJoinResponse`).
///
/// Khác mọi response auth khác: mang thẳng `householdId`/`role` vì JWT được
/// phát hành kèm claim ngay, không cần refresh.
class QrJoinResult {
  const QrJoinResult({
    required this.session,
    required this.householdId,
    required this.role,
    required this.requiresProfileCompletion,
  });

  final AuthSession session;
  final String householdId;
  final String role;

  /// FE hiện banner nhắc thiết lập email — **không được chặn** user (Flow 9).
  final bool requiresProfileCompletion;

  factory QrJoinResult.fromJson(Map<String, dynamic> json) => QrJoinResult(
        session: AuthSession.fromJson(json),
        householdId: json['householdId'] as String,
        role: json['role'] as String,
        requiresProfileCompletion:
            json['requiresProfileCompletion'] as bool? ?? false,
      );
}

/// Kết quả `POST /auth/upgrade-profile` (schema `UpgradeProfileResponse`).
class UpgradeProfileResult {
  const UpgradeProfileResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.requiresOtpVerification,
    required this.message,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final bool requiresOtpVerification;
  final String message;

  factory UpgradeProfileResult.fromJson(Map<String, dynamic> json) =>
      UpgradeProfileResult(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: json['expiresIn'] as int? ?? 0,
        requiresOtpVerification:
            json['requiresOtpVerification'] as bool? ?? false,
        message: json['message'] as String? ?? '',
      );
}
