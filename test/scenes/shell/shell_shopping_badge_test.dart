import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_dao.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/shell_bindings_stub.dart';

/// `ShoppingStore` thật nhưng số "giao cho tôi" điều khiển bằng tay — test chỉ
/// quan tâm shell đọc ĐÚNG nguồn này và dựng lại đúng phần cần dựng.
class _BadgeShoppingStore extends ShoppingStore {
  _BadgeShoppingStore()
      : super(
          dao: ShoppingDao(Get.find<AppDatabase>()),
          api: Get.find<ShoppingApi>(),
          connectivity: Get.find<ConnectivityService>(),
          session: Get.find<SessionStore>(),
        );

  final Observable<int> count = Observable<int>(0);

  @override
  int get assignedToMeCount => count.value;

  @override
  Future<void> init() async {}
}

/// #134 — badge tab Đi chợ trong shell (shopping-list-screen §9.7(a)).
void main() {
  const badgeKey = ValueKey<String>('app-bottom-nav-badge');
  late _BadgeShoppingStore shopping;

  setUp(() {
    Get.put<AppShellStore>(AppShellStore());
    registerShellStubBindings();
    shopping = _BadgeShoppingStore();
    // Đăng ký TRƯỚC khi shell chạy binding — binding bỏ qua khi đã có.
    Get.put<ShoppingStore>(shopping, permanent: true);
  });

  tearDown(Get.reset);

  void setCount(int value) => runInAction(() => shopping.count.value = value);

  testWidgets('số > 0 → badge trên tab Đi chợ, thấy cả khi đang ở tab khác',
      (tester) async {
    setCount(2);
    await tester.pumpAppWidget(const AppShellScene(), wrapInScaffold: false);

    expect(Get.find<AppShellStore>().selectedIndex, 0);
    expect(find.descendant(of: find.byKey(badgeKey), matching: find.text('2')),
        findsOneWidget);
  });

  testWidgets('số = 0 → không có badge', (tester) async {
    await tester.pumpAppWidget(const AppShellScene(), wrapInScaffold: false);
    expect(find.byKey(badgeKey), findsNothing);
  });

  testWidgets('đổi số → badge cập nhật, KHÔNG dựng lại IndexedStack',
      (tester) async {
    setCount(1);
    await tester.pumpAppWidget(const AppShellScene(), wrapInScaffold: false);
    final stackBefore = tester.widget<IndexedStack>(find.byType(IndexedStack));

    setCount(120);
    await tester.pump();
    expect(
        find.descendant(of: find.byKey(badgeKey), matching: find.text('99+')),
        findsOneWidget);
    expect(
        identical(tester.widget<IndexedStack>(find.byType(IndexedStack)),
            stackBefore),
        isTrue,
        reason: 'Observer của shell (Scaffold/IndexedStack) không được '
            'theo dõi số badge');

    setCount(0);
    await tester.pump();
    expect(find.byKey(badgeKey), findsNothing);
  });

  testWidgets('semantics tab Đi chợ có số món được giao', (tester) async {
    final handle = tester.ensureSemantics();
    setCount(2);
    await tester.pumpAppWidget(const AppShellScene(), wrapInScaffold: false);
    expect(find.bySemanticsLabel('Đi chợ, 2 món được giao cho bạn'),
        findsOneWidget);
    handle.dispose();
  });

  test('ShoppingStore chưa đăng ký → 0, không ném', () {
    Get.reset();
    expect(Get.isRegistered<ShoppingStore>(), isFalse);
    expect(shoppingAssignedBadgeCount(), 0);
  });
}
