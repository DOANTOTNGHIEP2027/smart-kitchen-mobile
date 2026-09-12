import 'package:mobx/mobx.dart';

class AppShellStore {
  AppShellStore({int initialIndex = 0}) : _selectedIndex = Observable(initialIndex);

  final Observable<int> _selectedIndex;

  int get selectedIndex => _selectedIndex.value;

  void selectTab(int index) {
    if (index < 0 || index > 4) return;
    runInAction(() => _selectedIndex.value = index);
  }
}
