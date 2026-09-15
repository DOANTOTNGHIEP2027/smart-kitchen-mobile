import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';
import 'onboarding_routes.dart';

/// Flow 6 — điều hướng household (fe-onboarding.md §10).
///
/// Không phải một lệnh gọi BE: chỉ là nhánh rẽ phía client theo `household_id`
/// của phiên hiện tại, chạy ngay sau **mọi** lượt xác thực thành công (Flow 2,
/// 3→4, 5).
///
/// Nguồn của `household_id` là claim JWT qua `SessionStore.householdId`
/// (fe-app-shell.md §8.1/§13). `fe-onboarding.md` §2 nói đọc từ response body
/// — điều đó không khả thi: `GoogleLoginResponse`/`EmailAuthSessionResponse`
/// trong `auth-jwt.yaml` **không có** field này. Chỉ `QrJoinResponse` mới có.
Future<void> routeAfterAuth() async {
  final session = Get.find<SessionStore>();
  await Get.offAllNamed<void>(
    session.householdId == null
        ? OnboardingRoutes.householdSetup
        : AppRoutes.shellRoot,
  );
}
