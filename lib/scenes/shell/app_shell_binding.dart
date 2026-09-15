import 'package:get/get.dart';

import 'app_shell_store.dart';

/// Chỉ inject store theo phạm vi scene. Singleton toàn app (`SessionStore`,
/// `DioClient`, `TokenStorage`) KHÔNG được đăng ký lại ở đây — chúng đã được
/// `Get.put(..., permanent: true)` trong `bootstrap()` (fe-app-shell.md §6.3).
class AppShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppShellStore>(AppShellStore.new);
  }
}
