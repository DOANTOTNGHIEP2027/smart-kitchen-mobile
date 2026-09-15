import 'package:get/get.dart';

import '../scenes/onboarding/onboarding_pages.dart';
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
    ...OnboardingPages.pages,
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
}
