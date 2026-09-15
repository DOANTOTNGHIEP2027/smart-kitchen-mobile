/// Validation phía client cho form onboarding.
///
/// **Mirror đúng quy tắc của BE, không khắt khe hơn** (fe-onboarding.md §7).
/// Đây chỉ là tiện ích UX — `ERR_VALIDATION_FAILED` từ BE mới là lớp có thẩm
/// quyền cuối cùng.
abstract class Validators {
  /// Giới hạn UI mềm cho `fullName`: BE không ghi nhận giới hạn nào
  /// (open question Q5), nên đây là ước đoán ở mức UI, không phải quy tắc BE.
  static const int fullNameMaxLength = 100;

  /// Độ dài tối thiểu của mật khẩu theo `EmailRegisterRequest.minLength`.
  static const int passwordMinLength = 8;

  /// Invite code: 8 ký tự alphanumeric (`household-invite-role.yaml`).
  static const int inviteCodeLength = 8;

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _inviteCode = RegExp(r'^[A-Za-z0-9]{8}$');

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  static bool isValidPassword(String value) =>
      value.length >= passwordMinLength;

  static bool isValidFullName(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.length <= fullNameMaxLength;
  }

  static bool isValidInviteCode(String value) =>
      _inviteCode.hasMatch(value.trim());

  /// Tên household: 1–255 ký tự, khớp `CreateHouseholdRequest`.
  static bool isValidHouseholdName(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.length <= 255;
  }

  /// OTP: đúng 6 chữ số (`VerifyOtpRequest.pattern`).
  static bool isValidOtp(String value) =>
      RegExp(r'^[0-9]{6}$').hasMatch(value.trim());
}
