import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_store.dart';
import 'package:smart_kitchen_mobile/widgets/app_bottom_nav.dart';

import 'helpers/pump_app.dart';
import 'helpers/shell_bindings_stub.dart';

/// Khung shell bottom-nav (fe-app-shell.md §12).
///
/// Sau khi wire feature scene thật vào shell (commit này), các test cũ kỳ
/// vọng `AppEmptyView("Coming soon")` cho mọi tab không còn đúng — chỉ còn
/// tab Shopping (chưa làm theo D-07) là placeholder. Test mới kiểm:
///  - shell dựng đủ 5 InkResponse (1 / tab).
///  - tap tab đổi selectedIndex.
///  - tab Shopping (index 3) vẫn render AppEmptyView.
void main() {
  late AppShellStore store;

  setUp(() {
    store = AppShellStore();
    Get.put<AppShellStore>(store);
    registerShellStubBindings(); // stub để `_ensureBindings()` không ném.
  });

  tearDown(Get.reset);

  testWidgets('render 5 tab, mặc định chọn tab đầu', (WidgetTester tester) async {
    await tester.pumpAppWidget(const AppShellScene(), wrapInScaffold: false);

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(InkResponse), findsNWidgets(5));
    expect(store.selectedIndex, 0);
  });

  testWidgets('chạm tab đổi selectedIndex',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(const AppShellScene(), wrapInScaffold: false);

    await tester.tap(find.text('Kho'));
    await tester.pumpAndSettle();
    expect(store.selectedIndex, 1);
  });

  testWidgets('tab Shopping (index 3) giữ placeholder Coming soon',
      (WidgetTester tester) async {
    // Đổi sang tab Shopping.
    store.selectTab(3);
    await tester.pumpAppWidget(const AppShellScene(), wrapInScaffold: false);
    await tester.pumpAndSettle();

    expect(find.text('Sắp ra mắt'), findsWidgets);
  });
}
