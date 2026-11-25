import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/ocr_image_service.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/data/receipt_api.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/scenes/receipt_routes.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/scenes/receipt_scan_binding.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/stores/receipt_scan_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/scenes/shopping_list_binding.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/scenes/shopping_list_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import '../../helpers/shell_bindings_stub.dart';
import 'receipt_widget_harness.dart';

/// §16 + Guard 8: nút vào trên `ShoppingListScene` → `AppRoutes.receiptScan`
/// qua `receiptPages` THẬT (AuthGuard + `ReceiptScanBinding`). Chỉ thay
/// phụ thuộc chạm thiết bị/mạng (ReceiptApi, picker, compressor) bằng fake —
/// binding giữ nguyên nhánh `isRegistered` nên không tự tạo bản thật.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();

  setUp(() async {
    storage.install();
    Get.testMode = true;
    registerShellStubBindings();
    await Get.find<SessionStore>().setSession(
      accessToken: fakeJwt(<String, dynamic>{'role': 'MEMBER'}),
      refreshToken: 'r1',
      user: const UserSummary(id: 'u1'),
    );
    Get.find<SessionStore>()
        .applyHouseholdContext(householdId: 'h1', role: 'MEMBER');
    Get
      ..put<ReceiptApi>(FakeReceiptApi())
      ..put<OcrImagePicker>(FakePicker())
      ..put<OcrImageCompressor>(FakeCompressor());
  });

  tearDown(() async {
    await Get.find<AppDatabase>().close();
    Get.reset();
    storage.uninstall();
  });

  testWidgets(
      'icon hoá đơn trên ShoppingListScene → push receiptScan qua binding thật',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: AppRoutes.shopping,
        getPages: <GetPage<dynamic>>[
          GetPage<void>(
            name: AppRoutes.shopping,
            page: () => const ShoppingListScene(),
            binding: ShoppingListBinding(),
          ),
          ...receiptPages,
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(Get.isRegistered<ReceiptScanStore>(), isFalse);

    await tester
        .tap(find.byKey(const ValueKey<String>('shopping-receipt-scan')));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.receiptScan);
    expect(find.text(viL10n.receiptScanTitle), findsOneWidget);
    expect(Get.find<ReceiptScanStore>().status, ReceiptScanStatus.idle);

    // X → về lại danh sách mua sắm.
    await tester.tap(find.byKey(const ValueKey<String>('receipt-scan-close')));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.shopping);
  });

  test('ReceiptScanBinding tự đăng ký ShoppingStore khi chưa mở Mua sắm', () {
    expect(Get.isRegistered<ShoppingStore>(), isFalse);

    ReceiptScanBinding().dependencies();

    expect(Get.find<ReceiptScanStore>(), isA<ReceiptScanStore>());
    expect(Get.isRegistered<ShoppingStore>(), isTrue);
  });
}
