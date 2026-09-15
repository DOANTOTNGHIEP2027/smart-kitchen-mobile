import 'package:get/get.dart';

/// Splash không có store theo phạm vi scene — việc redirect chỉ đọc singleton
/// `SessionStore` đã được `Get.put` từ `bootstrap()` (fe-app-shell.md §5).
class SplashBinding extends Bindings {
  @override
  void dependencies() {}
}
