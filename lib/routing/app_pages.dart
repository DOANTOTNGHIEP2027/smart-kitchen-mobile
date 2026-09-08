import 'package:get/get.dart';

import '../scenes/auth/login_placeholder_scene.dart';
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
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: AppRoutes.login,
      page: LoginPlaceholderScene.new,
      middlewares: [GuestOnlyGuard()],
    ),
  ];
}
