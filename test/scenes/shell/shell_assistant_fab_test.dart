import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_store.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/shell_bindings_stub.dart';

/// #204 KA-FE-1 — FAB trợ lý bếp GLOBAL trên shell, góc trái để không đè FAB
/// của tab Kho/Đi chợ.
void main() {
  setUp(() {
    Get.put<AppShellStore>(AppShellStore());
    registerShellStubBindings();
  });

  tearDown(Get.reset);

  Finder fab() => find.byTooltip('Hỏi trợ lý bếp');

  testWidgets('FAB trợ lý hiện ở mọi tab, nằm ở góc trái', (tester) async {
    await tester.pumpAppWidget(const AppShellScene(), wrapInScaffold: false);
    await tester.pump();

    expect(fab(), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(
        find.ancestor(of: fab(), matching: find.byType(Scaffold)).first);
    expect(scaffold.floatingActionButtonLocation,
        FloatingActionButtonLocation.startFloat);

    for (var i = 1; i < 5; i++) {
      Get.find<AppShellStore>().selectTab(i);
      await tester.pump();
      expect(fab(), findsOneWidget, reason: 'tab $i');
    }
    await tester.pumpWidget(const SizedBox());
  });
}
