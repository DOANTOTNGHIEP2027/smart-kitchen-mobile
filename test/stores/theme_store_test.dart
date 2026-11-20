import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/stores/theme_store.dart';

void main() {
  test('mặc định light (dark mode chỉ bật thủ công — design §6)', () {
    expect(ThemeStore().themeMode, ThemeMode.light);
  });

  test('toggle light ↔ dark', () {
    final store = ThemeStore()..toggle();
    expect(store.themeMode, ThemeMode.dark);
    store.toggle();
    expect(store.themeMode, ThemeMode.light);
  });

  test('setThemeMode; toggle từ system → dark', () {
    final store = ThemeStore()..setThemeMode(ThemeMode.system);
    expect(store.themeMode, ThemeMode.system);
    store.toggle();
    expect(store.themeMode, ThemeMode.dark);
  });
}
