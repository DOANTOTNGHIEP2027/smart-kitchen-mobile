import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../stores/session_store.dart';
import 'app_routes.dart';

/// Chặn route cần đăng nhập (fe-app-shell.md §6.2).
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final status = Get.find<SessionStore>().status;
    // Allow-list, không phải deny-list: chỉ `authenticated` mới được vào.
    // `unknown` phải bị chặn — §5 lập luận rằng status luôn resolve xong trước
    // `runApp()`, nhưng nếu `SessionStore.bootstrap()` gặp lỗi bất thường thì
    // `unknown` vẫn có thể còn sót lại, và khi đó không có access token nào.
    // Cho `unknown` đi qua đồng nghĩa mở shell cho một phiên không tồn tại.
    if (status != AuthStatus.authenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null; // allow
  }
}

/// Chặn user đã đăng nhập quay lại màn hình khách (login/register/OTP).
///
/// Shell chỉ định nghĩa class; `fe-onboarding` tự gắn nó vào `GetPage` của
/// mình — shell không wiring guard vào route mà nó không sở hữu.
class GuestOnlyGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final status = Get.find<SessionStore>().status;
    if (status == AuthStatus.authenticated) {
      return const RouteSettings(name: AppRoutes.shellRoot);
    }
    return null; // allow
  }
}
