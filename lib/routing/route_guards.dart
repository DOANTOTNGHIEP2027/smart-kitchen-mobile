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
      final session = Get.find<SessionStore>();
      return RouteSettings(name: session.householdId == null ? AppRoutes.householdSetup : AppRoutes.shellRoot);
    }
    return null;
  }
}

class HouseholdRequiredGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<SessionStore>() || Get.find<SessionStore>().status != AuthStatus.authenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (Get.find<SessionStore>().householdId == null) return const RouteSettings(name: AppRoutes.householdSetup);
    return null;
  }
}

class HouseholdSetupGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<SessionStore>() || Get.find<SessionStore>().status != AuthStatus.authenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (Get.find<SessionStore>().householdId != null) return const RouteSettings(name: AppRoutes.shellRoot);
    return null;
  }
}

class GuestProviderGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<SessionStore>() || Get.find<SessionStore>().status != AuthStatus.authenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (Get.find<SessionStore>().provider != 'GUEST') return const RouteSettings(name: AppRoutes.shellRoot);
    return null;
  }
}
