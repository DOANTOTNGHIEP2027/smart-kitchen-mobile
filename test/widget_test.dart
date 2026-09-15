import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_empty_view.dart';

import 'helpers/pump_app.dart';

/// Khung shell bottom-nav (fe-app-shell.md §12).
void main() {
  late AppShellStore store;

  setUp(() {
    store = AppShellStore();
    Get.put<AppShellStore>(store);
  });

  tearDown(Get.reset);

  testWidgets('render 5 tab, mặc định chọn tab đầu', (WidgetTester tester) async {
    await tester.pumpAppWidget(const AppShellScene());

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(store.selectedIndex, 0);
  });

  testWidgets('chạm tab đổi selectedIndex và đổi tiêu đề',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(const AppShellScene());

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();

    expect(store.selectedIndex, 1);
    expect(find.widgetWithText(AppBar, 'Inventory'), findsOneWidget);
  });

  testWidgets('mỗi tab hiện placeholder "Coming soon"',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(const AppShellScene());

    // skipOffstage: false — IndexedStack build cả 5 tab, chỉ 1 tab onstage.
    expect(find.byType(AppEmptyView, skipOffstage: false), findsNWidgets(5));
    expect(find.text('Coming soon'), findsWidgets);
  });
}
