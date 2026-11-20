import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'theme_store.g.dart';

/// Chế độ sáng/tối của app (design-system.md §6).
///
/// Mặc định [ThemeMode.light] và KHÔNG persist: màn feature còn dùng màu tĩnh
/// nên chỉ showcase (dev) được bật dark cho tới khi migrate xong (FU-1).
class ThemeStore = _ThemeStore with _$ThemeStore;

abstract class _ThemeStore with Store {
  @observable
  ThemeMode themeMode = ThemeMode.light;

  @action
  void setThemeMode(ThemeMode mode) => themeMode = mode;

  @action
  void toggle() => themeMode =
      themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}
