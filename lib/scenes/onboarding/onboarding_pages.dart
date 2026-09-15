import 'package:get/get.dart';

import '../../routing/route_guards.dart';
import 'auth_landing_scene.dart';
import 'create_household_scene.dart';
import 'household_setup_scene.dart';
import 'invite_code_scene.dart';
import 'invite_preview_scene.dart';
import 'invite_scan_scene.dart';
import 'login_scene.dart';
import 'onboarding_binding.dart';
import 'onboarding_routes.dart';
import 'otp_scene.dart';
import 'register_scene.dart';
import 'upgrade_profile_scene.dart';

/// Danh sách `GetPage` của feature onboarding, được `AppPages.pages` nối vào
/// (pattern mở rộng D2 — shell không phải biết gì về nội bộ feature này).
///
/// Ghi chú về guard — ba nhóm route, ba cách xử lý khác nhau:
///
/// - **Trước khi có session** (landing, register, email login): [GuestOnlyGuard]
///   để user đã đăng nhập deep-link vào `/login` bị bật về shell.
/// - **Sau khi có session** (household setup/create, upgrade profile):
///   [AuthGuard]. Mọi đường tới đây đều đi qua `setSession()` nên
///   `status == authenticated` trước khi điều hướng — không có vòng lặp.
///   (Bản đầu của file này cố ý bỏ guard vì sợ lặp; nỗi lo đó xuất phát từ
///   `AuthGuard` cũ vốn cho `AuthStatus.unknown` đi qua, đã được sửa thành
///   allow-list ở vòng fix FE-1.)
/// - **Phục vụ cả hai trạng thái** (OTP, toàn bộ `/join/*`): không guard nào
///   đúng. OTP chạy cả ở `flow=register` (chưa có token) lẫn `flow=upgrade`
///   (đã đăng nhập); luồng join chạy cả cho user chưa đăng ký (QR-join) lẫn
///   user đã đăng nhập chưa có household.
abstract class OnboardingPages {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<void>(
      name: OnboardingRoutes.landing,
      page: () => const AuthLandingScene(),
      binding: OnboardingBinding(),
      middlewares: <GetMiddleware>[GuestOnlyGuard()],
    ),
    GetPage<void>(
      name: OnboardingRoutes.register,
      page: () => const RegisterScene(),
      binding: OnboardingBinding(),
      middlewares: <GetMiddleware>[GuestOnlyGuard()],
    ),
    GetPage<void>(
      name: OnboardingRoutes.emailLogin,
      page: () => const LoginScene(),
      binding: OnboardingBinding(),
      middlewares: <GetMiddleware>[GuestOnlyGuard()],
    ),
    // OTP không gắn GuestOnlyGuard: `flow=upgrade` chạy khi user ĐÃ đăng nhập
    // (GUEST nâng cấp), guard sẽ chặn nhầm chính luồng đó.
    GetPage<void>(
      name: OnboardingRoutes.otp,
      page: () => const OtpScene(),
      binding: OnboardingBinding(),
    ),
    GetPage<void>(
      name: OnboardingRoutes.householdSetup,
      page: () => const HouseholdSetupScene(),
      binding: OnboardingBinding(),
      middlewares: <GetMiddleware>[AuthGuard()],
    ),
    GetPage<void>(
      name: OnboardingRoutes.createHousehold,
      page: () => const CreateHouseholdScene(),
      binding: OnboardingBinding(),
      middlewares: <GetMiddleware>[AuthGuard()],
    ),
    // Luồng join mở cho cả user chưa đăng nhập (QR-join) lẫn user đã đăng
    // nhập chưa có household — không guard nào phù hợp cho cả hai.
    GetPage<void>(
      name: OnboardingRoutes.inviteScan,
      page: () => const InviteScanScene(),
      binding: OnboardingBinding(),
    ),
    GetPage<void>(
      name: OnboardingRoutes.inviteCode,
      page: () => const InviteCodeScene(),
      binding: OnboardingBinding(),
    ),
    GetPage<void>(
      name: OnboardingRoutes.invitePreview,
      page: () => const InvitePreviewScene(),
      binding: OnboardingBinding(),
    ),
    GetPage<void>(
      name: OnboardingRoutes.upgradeProfile,
      page: () => const UpgradeProfileScene(),
      binding: OnboardingBinding(),
      middlewares: <GetMiddleware>[AuthGuard()],
    ),
  ];
}
