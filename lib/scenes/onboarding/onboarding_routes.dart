import '../../routing/app_routes.dart';

/// Tên route của feature onboarding (#28).
///
/// Theo pattern mở rộng D2 của `fe-app-shell.md` §6.1: feature tự sở hữu hằng
/// số route của mình; chỉ [AppRoutes.login] và [AppRoutes.qrJoin] là tên đã
/// được shell dành sẵn vì chính guard/deep-link của shell tham chiếu tới.
abstract class OnboardingRoutes {
  /// Landing chọn phương thức đăng nhập (S1.1) — chính là đích redirect của
  /// `AuthGuard`.
  static const String landing = AppRoutes.login;

  /// Điểm vào quét QR, cũng là seam deep-link `https://app.smartkitchen.vn/join`.
  static const String inviteScan = AppRoutes.qrJoin;

  static const String register = '/register';
  static const String otp = '/otp';
  static const String emailLogin = '/login/email';
  static const String householdSetup = '/household/setup';
  static const String createHousehold = '/household/create';
  static const String inviteCode = '/join/code';
  static const String invitePreview = '/join/preview';
  static const String upgradeProfile = '/profile/upgrade';
}
