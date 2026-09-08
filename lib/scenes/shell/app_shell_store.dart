import 'package:mobx/mobx.dart';

class AppShellStore {
  final Observable<int> _selectedIndex = Observable(0);

  int get selectedIndex => _selectedIndex.value;

  void selectTab(int index) {
    if (index < 0 || index > 4) return;
    runInAction(() => _selectedIndex.value = index);
  }
}
