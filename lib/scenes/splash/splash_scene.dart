import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import '../../widgets/states/app_loading_view.dart';

/// `initialRoute` của app (fe-app-shell.md §5).
///
/// Đến lúc `runApp()` chạy, `SessionStore.status` đã resolve xong (bootstrap
/// await trước đó) — nên scene này không cần route guard; nó tự redirect chính
/// mình đúng một lần khi mount.
class SplashScene extends StatefulWidget {
  const SplashScene({super.key});

  @override
  State<SplashScene> createState() => _SplashSceneState();
}

class _SplashSceneState extends State<SplashScene> {
  @override
  void initState() {
    super.initState();
    // Deferred sang frame kế tiếp để GetX navigator đã attach trước khi
    // Get.offAllNamed chạy; status lúc này đã resolve rồi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final status = Get.find<SessionStore>().status;
      Get.offAllNamed(
        status != AuthStatus.authenticated
            ? AppRoutes.login
            : Get.find<SessionStore>().needsHousehold
                ? AppRoutes.householdSetup
                : AppRoutes.shellRoot,
      );
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: AppLoadingView());
}
