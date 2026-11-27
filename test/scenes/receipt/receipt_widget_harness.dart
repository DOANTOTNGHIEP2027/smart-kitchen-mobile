import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/ocr_image_service.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/domain/ocr_scan_result.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/stores/inventory_form_store.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/data/receipt_api.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_scan_result.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/scenes/receipt_result_scene.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/scenes/receipt_scan_scene.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/stores/receipt_scan_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';

/// Hạ tầng widget test chung cho 2 màn quét hoá đơn (#68): fake phụ thuộc của
/// `ReceiptScanStore` + GetMaterialApp có stack giống thật
/// (`'/'` = shell → scan → result) để kiểm điều hướng `Get.close(2)`.

const String kHomeText = 'HOME-SHELL';
const String kShoppingText = 'SHOPPING-STANDALONE';

/// #239: màn cất vào kho mở sau khi cập nhật món khớp — stub trong harness.
const String kCheckoutText = 'CHECKOUT-STUB';

class FakeReceiptApi implements ReceiptApi {
  final List<String> keys = <String>[];

  /// Mỗi lần gọi lấy 1 phần tử: ReceiptScanResult → trả; Completer → chờ;
  /// còn lại → throw.
  final List<Object> outcomes = <Object>[];

  @override
  Future<ReceiptScanResult> scan({
    required Uint8List imageBytes,
    required String idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    keys.add(idempotencyKey);
    final outcome = outcomes.removeAt(0);
    if (outcome is ReceiptScanResult) return outcome;
    if (outcome is Completer<ReceiptScanResult>) return outcome.future;
    throw outcome;
  }
}

class FakePicker implements OcrImagePicker {
  Object? error;

  @override
  Future<Uint8List?> pick(OcrImageSource source) async {
    if (error != null) throw error!;
    return Uint8List.fromList(<int>[1, 2, 3]);
  }
}

class FakeCompressor implements OcrImageCompressor {
  Object? error;

  @override
  Future<Uint8List> compress(Uint8List bytes) async {
    if (error != null) throw error!;
    return bytes;
  }
}

class SpyShoppingStore implements ShoppingStore {
  final List<Map<String, double?>> calls = <Map<String, double?>>[];
  List<String> failures = <String>[];
  Completer<List<String>>? gate;

  @override
  Future<List<String>> bulkCheck(Map<String, double?> priceById) async {
    calls.add(Map<String, double?>.of(priceById));
    final pending = gate;
    if (pending != null) return pending.future;
    return failures;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockInventoryFormStore extends Mock implements InventoryFormStore {}

class ReceiptHarness {
  ReceiptHarness() {
    store = ReceiptScanStore(
      api: api,
      imagePicker: picker,
      imageCompressor: compressor,
      shoppingStore: shopping,
      formStoreFactory: () => formStore,
      idempotencyKeyGenerator: () => 'key-${++_keyCounter}',
    );
    Get.put<ReceiptScanStore>(store);
  }

  final FakeReceiptApi api = FakeReceiptApi();
  final FakePicker picker = FakePicker();
  final FakeCompressor compressor = FakeCompressor();
  final SpyShoppingStore shopping = SpyShoppingStore();
  final MockInventoryFormStore formStore = MockInventoryFormStore();
  late final ReceiptScanStore store;
  var _keyCounter = 0;

  void stubSave(Future<bool> Function() answer, {ApiException? error}) {
    when(() => formStore.saveError).thenReturn(error);
    when(
      () => formStore.save(
        name: any(named: 'name'),
        category: any(named: 'category'),
        quantity: any(named: 'quantity'),
        unit: any(named: 'unit'),
        lowStockThreshold: any(named: 'lowStockThreshold'),
        expiryDate: any(named: 'expiryDate'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) => answer());
  }

  int saveCallCount() => verify(
        () => formStore.save(
          name: any(named: 'name'),
          category: any(named: 'category'),
          quantity: any(named: 'quantity'),
          unit: any(named: 'unit'),
          lowStockThreshold: any(named: 'lowStockThreshold'),
          expiryDate: any(named: 'expiryDate'),
          note: any(named: 'note'),
        ),
      ).callCount;

  void verifyNoSave() => verifyNever(
        () => formStore.save(
          name: any(named: 'name'),
          category: any(named: 'category'),
          quantity: any(named: 'quantity'),
          unit: any(named: 'unit'),
          lowStockThreshold: any(named: 'lowStockThreshold'),
          expiryDate: any(named: 'expiryDate'),
          note: any(named: 'note'),
        ),
      );

  /// Dựng app ở `'/'` (đóng vai shell) rồi push màn scan. [viaShopping]:
  /// push route `/shopping` độc lập trước (shell → /shopping → scan).
  Future<void> pumpScan(
    WidgetTester tester, {
    bool viaShopping = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: AppRoutes.shellRoot,
        getPages: <GetPage<dynamic>>[
          GetPage<void>(
            name: AppRoutes.shellRoot,
            page: () => const Scaffold(body: Center(child: Text(kHomeText))),
          ),
          GetPage<void>(
            name: AppRoutes.shopping,
            page: () =>
                const Scaffold(body: Center(child: Text(kShoppingText))),
          ),
          GetPage<void>(
            name: AppRoutes.shoppingCheckout,
            page: () =>
                const Scaffold(body: Center(child: Text(kCheckoutText))),
          ),
          GetPage<void>(
            name: AppRoutes.receiptScan,
            page: () => const ReceiptScanScene(),
          ),
          GetPage<void>(
            name: AppRoutes.receiptScanResult,
            page: () => const ReceiptResultScene(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    if (viaShopping) {
      unawaited(Get.toNamed<void>(AppRoutes.shopping));
      await tester.pumpAndSettle();
    }
    unawaited(Get.toNamed<void>(AppRoutes.receiptScan));
    await tester.pumpAndSettle();
  }

  /// shell → scan → (chọn ảnh, API trả [result]) → result.
  Future<void> pumpResult(
    WidgetTester tester,
    ReceiptScanResult result, {
    bool viaShopping = false,
  }) async {
    api.outcomes.add(result);
    await pumpScan(tester, viaShopping: viaShopping);
    await tester
        .tap(find.byKey(const ValueKey<String>('receipt-choose-gallery')));
    await tester.pumpAndSettle();
  }
}

/// Chuỗi tiếng Việt thật của app — test so câu chữ, không hardcode.
final AppLocalizations viL10n = lookupAppLocalizations(const Locale('vi'));

/// Chờ snackbar GetX tự đóng để không còn timer treo khi test kết thúc.
Future<void> settleSnackbars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}
