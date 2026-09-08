import 'package:get/get.dart';

import 'app_shell_store.dart';

class AppShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppShellStore>(AppShellStore.new);
  }
}
