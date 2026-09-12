import '../../../domain/user_summary.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.accountLinked = false,
  });

  final String accessToken;
  final String refreshToken;
  final UserSummary user;
  final bool accountLinked;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: userSummaryFromJson(Map<String, dynamic>.from(json['user'] as Map)),
        accountLinked: json['accountLinked'] == true,
      );
}

class RegisterResult {
  const RegisterResult({required this.email, required this.requiresOtp});

  final String email;
  final bool requiresOtp;

  factory RegisterResult.fromJson(Map<String, dynamic> json) => RegisterResult(
        email: json['email'] as String,
        requiresOtp: json['requiresOtpVerification'] == true,
      );
}

class UpgradeResult {
  const UpgradeResult({
    required this.accessToken,
    required this.refreshToken,
    required this.requiresOtp,
  });

  final String accessToken;
  final String refreshToken;
  final bool requiresOtp;

  factory UpgradeResult.fromJson(Map<String, dynamic> json) => UpgradeResult(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        requiresOtp: json['requiresOtpVerification'] == true,
      );
}

class GuestJoinSession {
  const GuestJoinSession({required this.session, required this.requiresProfileCompletion});

  final AuthSession session;
  final bool requiresProfileCompletion;

  factory GuestJoinSession.fromJson(Map<String, dynamic> json) => GuestJoinSession(
        session: AuthSession.fromJson(json),
        requiresProfileCompletion: json['requiresProfileCompletion'] == true,
      );
}

UserSummary userSummaryFromJson(Map<String, dynamic> json) => UserSummary(
      id: json['id'] as String,
      fullName: (json['fullName'] as String?)?.trim().isNotEmpty == true
          ? json['fullName'] as String
          : 'Thành viên',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
