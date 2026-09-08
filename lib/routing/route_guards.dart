import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../stores/session_store.dart';
import 'app_routes.dart';

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<SessionStore>() ||
        Get.find<SessionStore>().status != AuthStatus.authenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

class GuestOnlyGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (Get.isRegistered<SessionStore>() &&
        Get.find<SessionStore>().status == AuthStatus.authenticated) {
      return const RouteSettings(name: AppRoutes.shellRoot);
    }
    return null;
  }
}
