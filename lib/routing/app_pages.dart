import 'package:get/get.dart';

import '../app/env_config.dart';
import '../scenes/dev/dev_login_scene.dart';
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
    // Chỉ build dev mới có màn hình login giả. Build release KHÔNG được chứa
    // một route mint session giả với role OWNER.
    if (EnvConfig.isDev) ...devPlaceholderPages,
    // ...onboardingPages,   // fe-onboarding (#28) append danh sách của nó ở đây
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

  /// TẠM THỜI, CHỈ DEV — xóa cả danh sách này lẫn [DevLoginScene] khi
  /// `fe-onboarding` (#28) đăng ký màn hình login thật cho [AppRoutes.login].
  ///
  /// Cho tới lúc đó, build release cố tình KHÔNG có route nào cho
  /// [AppRoutes.login]: chưa có màn hình đăng nhập thật, nên hiển thị route
  /// chưa tồn tại còn đúng hơn là hiển thị một màn hình đăng nhập giả.
  static final List<GetPage<dynamic>> devPlaceholderPages = <GetPage<dynamic>>[
    GetPage<void>(
      name: AppRoutes.login,
      page: () => const DevLoginScene(),
      middlewares: <GetMiddleware>[GuestOnlyGuard()],
    ),
  ];
}
