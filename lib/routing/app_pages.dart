import 'package:get/get.dart';

import '../scenes/auth/auth_landing_scene.dart';
import '../scenes/auth/email_login_scene.dart';
import '../scenes/auth/email_register_scene.dart';
import '../scenes/auth/otp_scene.dart';
import '../scenes/auth/upgrade_profile_scene.dart';
import '../scenes/household/create_household_scene.dart';
import '../scenes/household/household_setup_scene.dart';
import '../scenes/household/join_household_scene.dart';
import '../scenes/shell/app_shell_binding.dart';
import '../scenes/shell/app_shell_scene.dart';
import '../scenes/splash/splash_binding.dart';
import '../scenes/splash/splash_scene.dart';
import 'app_routes.dart';
import 'route_guards.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: SplashScene.new,
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.shellRoot,
      page: AppShellScene.new,
      binding: AppShellBinding(),
      middlewares: [HouseholdRequiredGuard()],
    ),
    GetPage(
      name: AppRoutes.login,
      page: AuthLandingScene.new,
      middlewares: [GuestOnlyGuard()],
    ),
    GetPage(name: AppRoutes.emailLogin, page: EmailLoginScene.new, middlewares: [GuestOnlyGuard()]),
    GetPage(name: AppRoutes.register, page: EmailRegisterScene.new, middlewares: [GuestOnlyGuard()]),
    GetPage(name: AppRoutes.otp, page: OtpScene.new),
    GetPage(name: AppRoutes.qrJoin, page: JoinHouseholdScene.new),
    GetPage(name: AppRoutes.qrJoinCode, page: JoinHouseholdScene.new),
    GetPage(name: AppRoutes.householdSetup, page: HouseholdSetupScene.new, middlewares: [HouseholdSetupGuard()]),
    GetPage(name: AppRoutes.householdCreate, page: CreateHouseholdScene.new, middlewares: [HouseholdSetupGuard()]),
    GetPage(name: AppRoutes.upgradeProfile, page: UpgradeProfileScene.new, middlewares: [GuestProviderGuard()]),
  ];
}
