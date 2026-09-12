import 'package:get/get.dart';

import 'app_shell_store.dart';

class AppShellBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments;
    final profileTab = arguments is Map && arguments['profileTab'] == true;
    Get.lazyPut<AppShellStore>(() => AppShellStore(initialIndex: profileTab ? 4 : 0));
  }
}
