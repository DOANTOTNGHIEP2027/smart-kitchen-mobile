import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/scenes/inventory_form_scene.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_form_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/secure_storage_channel.dart';
import 'fake_connectivity_service.dart';
import 'fake_inventory_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  late AppDatabase db;
  late InventoryDao dao;

  setUp(() {
    storage.install();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = InventoryDao(db);
  });
  tearDown(() async {
    Get.reset();
    await db.close();
    storage.uninstall();
  });

  Finder field(String suffix) => find.byKey(ValueKey('inventory-$suffix'));

  Future<void> pumpForm(WidgetTester tester,
      {InventoryItemModel? item, double width = 375, double scale = 1}) async {
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = SessionStore(TokenStorage(),
        AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))))
      ..currentUser = const UserSummary(id: 'me', fullName: 'Tôi')
      ..applyHouseholdContext(householdId: 'h1', role: 'OWNER');
    Get.put(InventoryFormStore(
      mode: item == null ? InventoryFormMode.create : InventoryFormMode.edit,
      itemId: item?.id,
      dao: dao,
      api: FakeInventoryApi(),
      connectivity: FakeConnectivityService(online: false),
      sessionStore: session,
      localIdGen: () => 'local-ui-test',
    ));
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
          body: TextButton(
        onPressed: () =>
            Get.to<void>(() => const InventoryFormScene(), arguments: item),
        child: const Text('Mở form'),
      )),
    ));
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();
  }

  testWidgets('chọn phân loại rồi lưu vào dữ liệu của form', (tester) async {
    await pumpForm(tester);
    await tester.enterText(field('name'), 'Muối');
    await tester.tap(find.byTooltip('Nhóm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gia vị'));
    await tester.pumpAndSettle();
    await tester.enterText(field('quantity'), '100');
    await tester.tap(field('unit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('g (gram)'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(field('quantity')).dy,
        tester.getTopLeft(field('unit')).dy);
    expect(tester.getSize(field('quantity')).height,
        closeTo(tester.getSize(field('unit')).height, 2));
    await tester.ensureVisible(find.text('Thêm vào kho'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Thêm vào kho'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(() => dao.getById('local-ui-test'));
    expect(saved?.category, 'Gia vị');
    expect(saved?.quantity, 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'sửa mặt hàng giữ phân loại hiện tại; form vừa màn hình nhỏ và chữ lớn',
      (tester) async {
    final item = InventoryItemModel(
      id: 'existing',
      householdId: 'h1',
      name: 'Tôm',
      category: 'Hải sản',
      quantity: 500,
      unit: 'GRAM',
      displayQuantity: 500,
      displayUnit: 'g',
      version: 1,
      isLowStock: false,
      isExpiringSoon: false,
      createdBy: 'me',
      createdAt: DateTime(2026, 11, 28),
      updatedAt: DateTime(2026, 11, 28),
    );
    await pumpForm(tester, item: item, width: 320, scale: 2);
    expect(tester.widget<TextField>(field('category')).controller!.text,
        'Hải sản');
    expect(tester.getTopLeft(field('unit')).dy,
        greaterThan(tester.getBottomLeft(field('quantity')).dy));
    expect(tester.takeException(), isNull);
  });
}
