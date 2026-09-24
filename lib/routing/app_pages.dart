import 'package:get/get.dart';

import '../scenes/auth/auth_landing_scene.dart';
import '../scenes/auth/email_login_scene.dart';
import '../scenes/auth/email_register_scene.dart';
import '../scenes/auth/forgot_password_scene.dart';
import '../scenes/auth/otp_scene.dart';
import '../scenes/auth/reset_password_scene.dart';
import '../scenes/auth/upgrade_profile_scene.dart';
import '../scenes/cooking/scenes/cooking_routes.dart';
import '../scenes/household/create_household_scene.dart';
import '../scenes/household/household_setup_scene.dart';
import '../scenes/household/join_household_scene.dart';
import '../scenes/inventory/inventory_routes.dart';
import '../scenes/mealplan/scenes/meal_plan_routes.dart';
import '../scenes/profile/profile_family_routes.dart';
import '../scenes/shopping/scenes/shopping_routes.dart';
import '../scenes/shell/app_shell_binding.dart';
import '../scenes/shell/app_shell_scene.dart';
import '../scenes/splash/splash_binding.dart';
import '../scenes/splash/splash_scene.dart';
import 'app_routes.dart';
import 'route_guards.dart';

/// Registry route (fe-app-shell.md §6.1).
///
/// Pattern mở rộng (D2): một feature module export hằng số `List<GetPage>`
/// của riêng nó và [pages] nối nó vào. Không feature nào phải sửa nội bộ shell
/// để đăng ký một màn hình.
class AppPages {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    ...shellPages,
    ...feature1Pages,
    ...profileFamilyPages,
    ...inventoryPages,
    ...cookingPages,
    ...mealPlanPages,
    ...shoppingPages,
  ];

  static final List<GetPage<dynamic>> shellPages = <GetPage<dynamic>>[
    GetPage<void>(
      name: AppRoutes.splash,
      page: () => const SplashScene(),
      binding: SplashBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.shellRoot,
      page: () => const AppShellScene(),
      binding: AppShellBinding(),
      middlewares: <GetMiddleware>[AuthGuard()],
    ),
  ];

  static final List<GetPage<dynamic>> feature1Pages = <GetPage<dynamic>>[
    GetPage<void>(
      name: AppRoutes.login,
      page: () => const AuthLandingScene(),
      middlewares: <GetMiddleware>[GuestOnlyGuard()],
    ),
    GetPage<void>(name: AppRoutes.emailLogin, page: () => const EmailLoginScene(), middlewares: <GetMiddleware>[GuestOnlyGuard()]),
    GetPage<void>(name: AppRoutes.register, page: () => const EmailRegisterScene(), middlewares: <GetMiddleware>[GuestOnlyGuard()]),
    GetPage<void>(name: AppRoutes.otp, page: () => const OtpScene()),
    GetPage<void>(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScene(), middlewares: <GetMiddleware>[GuestOnlyGuard()]),
    GetPage<void>(name: AppRoutes.resetPassword, page: () => const ResetPasswordScene(), middlewares: <GetMiddleware>[GuestOnlyGuard()]),
    GetPage<void>(name: AppRoutes.qrJoin, page: () => const JoinHouseholdScene()),
    GetPage<void>(name: AppRoutes.qrJoinCode, page: () => const JoinHouseholdScene()),
    GetPage<void>(name: AppRoutes.householdSetup, page: () => const HouseholdSetupScene(), middlewares: <GetMiddleware>[HouseholdSetupGuard()]),
    GetPage<void>(name: AppRoutes.householdCreate, page: () => const CreateHouseholdScene(), middlewares: <GetMiddleware>[HouseholdSetupGuard()]),
    GetPage<void>(name: AppRoutes.profileUpgrade, page: () => const UpgradeProfileScene(), middlewares: <GetMiddleware>[GuestProfileGuard()]),
  ];
}
