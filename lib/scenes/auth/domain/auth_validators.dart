/// Luật validate form auth/household dùng chung cho validate realtime
/// (`AppTextField.validator`) và validate lúc submit trong store
/// (fe-onboarding.md §18b). Trả key l10n (dịch qua `localized`) hoặc `null`.
abstract class AuthValidators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  static String? email(String? value) =>
      isValidEmail(value ?? '') ? null : 'auth_email_invalid';

  static String? password(String? value) =>
      (value ?? '').length < 8 ? 'auth_password_short' : null;

  /// [required] = false cho form nâng cấp GUEST (họ tên tuỳ chọn).
  static String? fullName(String? value, {bool required = true}) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return required ? 'auth_name_required' : null;
    return name.length > 100 ? 'auth_name_too_long' : null;
  }

  static String? householdName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'household_name_required';
    return name.length > 255 ? 'household_name_too_long' : null;
  }
}
