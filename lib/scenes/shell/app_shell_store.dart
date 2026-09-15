import 'package:mobx/mobx.dart';

part 'app_shell_store.g.dart';

/// State của khung bottom-nav (fe-app-shell.md §12).
/// Theo phạm vi scene — `Get.lazyPut` trong [AppShellBinding].
// ignore: library_private_types_in_public_api — mixin application chuẩn của MobX
class AppShellStore = _AppShellStore with _$AppShellStore;

abstract class _AppShellStore with Store {
  _AppShellStore({int initialIndex = 0}) : selectedIndex = initialIndex;

  @observable
  int selectedIndex;

  @action
  void selectTab(int index) => selectedIndex = index;
}
