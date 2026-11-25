import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/ocr/data/ocr_image_service.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_scan_result.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_unmatched_item.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/stores/receipt_scan_store.dart';

import 'receipt_widget_harness.dart';

Finder _key(String value) => find.byKey(ValueKey<String>(value));

const _result = ReceiptScanResult(
  meta: ReceiptScanMeta(scanId: 'scan-1', currency: 'VND'),
  matchedItems: [],
  unmatchedItems: <ReceiptUnmatchedItem>[
    ReceiptUnmatchedItem(
      itemId: 'u-1',
      name: 'Sữa chua',
      quantity: 1,
      rawName: 'SUA CHUA',
      rawQuantity: 1,
      rawUnit: 'hũ',
    ),
  ],
);

void main() {
  late ReceiptHarness harness;

  setUp(() {
    Get.testMode = true;
    harness = ReceiptHarness();
  });
  tearDown(Get.reset);

  /// Chọn ảnh từ thư viện → API ném [error] → panel lỗi.
  Future<void> scanWithError(WidgetTester tester, Object error) async {
    harness.api.outcomes.add(error);
    await harness.pumpScan(tester);
    await tester.tap(_key('receipt-choose-gallery'));
    await tester.pumpAndSettle();
  }

  void expectBanner(String message) {
    expect(
      find.descendant(
        of: _key('receipt-scan-error'),
        matching: find.text(message),
      ),
      findsOneWidget,
    );
  }

  testWidgets('idle: gợi ý + Chụp ảnh + Chọn từ thư viện, chưa có Thử lại',
      (tester) async {
    await harness.pumpScan(tester);

    expect(find.text(viL10n.receiptScanTitle), findsOneWidget);
    expect(find.text(viL10n.receiptScanHint), findsOneWidget);
    expect(find.text(viL10n.inventoryOcrTakePhoto), findsOneWidget);
    expect(find.text(viL10n.inventoryOcrChooseGallery), findsOneWidget);
    expect(_key('receipt-scan-retry'), findsNothing);
    expect(_key('receipt-scan-error'), findsNothing);
  });

  testWidgets('đang đọc: overlay + Huỷ, X bị khoá; Huỷ → idle + Thử lại',
      (tester) async {
    final pending = Completer<ReceiptScanResult>();
    harness.api.outcomes.add(pending);
    await harness.pumpScan(tester);

    await tester.tap(_key('receipt-choose-gallery'));
    await tester.pump();

    expect(harness.store.status, ReceiptScanStatus.scanning);
    expect(find.text(viL10n.receiptScanning), findsOneWidget);
    expect(_key('receipt-scan-cancel'), findsOneWidget);
    expect(_key('receipt-take-photo'), findsNothing);
    final close = tester.widget<IconButton>(_key('receipt-scan-close'));
    expect(close.onPressed, isNull);

    await tester.tap(_key('receipt-scan-cancel'));
    pending.complete(_result); // response về sau Huỷ → bị bỏ
    await tester.pumpAndSettle();

    expect(harness.store.status, ReceiptScanStatus.idle);
    expect(_key('receipt-scan-error'), findsNothing);
    expect(find.text(viL10n.receiptScanHint), findsOneWidget);
    expect(_key('receipt-scan-retry'), findsOneWidget); // 1b — canResend
    expect(find.text(viL10n.receiptResultTitle), findsNothing);
  });

  testWidgets(
      'từ chối quyền → "Mở cài đặt" + "Thử lại"; cấp quyền rồi Thử lại → '
      'chọn lại ảnh và quét (L4)', (tester) async {
    harness.picker.error = const OcrPermissionDeniedException();
    await harness.pumpScan(tester);
    await tester.tap(_key('receipt-take-photo'));
    await tester.pumpAndSettle();

    expectBanner(viL10n.inventoryOcrPermissionDenied);
    expect(find.text(viL10n.openSettings), findsOneWidget);
    expect(_key('receipt-permission-retry'), findsOneWidget);
    expect(_key('receipt-scan-retry'), findsNothing); // không gửi lại ảnh cũ
    expect(_key('receipt-choose-another'), findsNothing);
    expect(harness.api.keys, isEmpty);

    // Quay lại từ Cài đặt đã cấp quyền.
    harness.picker.error = null;
    harness.api.outcomes.add(NetworkException());
    await tester.tap(_key('receipt-permission-retry'));
    await tester.pumpAndSettle();

    expect(harness.api.keys, <String>['key-1']);
    expectBanner(viL10n.networkError);
    expect(_key('receipt-open-settings'), findsNothing);
  });

  testWidgets('ảnh quá lớn (cục bộ) → không gọi API, chỉ "Chọn ảnh khác"',
      (tester) async {
    harness.compressor.error = const OcrImageTooLargeException();
    await harness.pumpScan(tester);
    await tester.tap(_key('receipt-choose-gallery'));
    await tester.pumpAndSettle();

    expectBanner(viL10n.inventoryOcrImageTooLarge);
    expect(find.text(viL10n.inventoryOcrChooseAnother), findsOneWidget);
    expect(_key('receipt-scan-retry'), findsNothing);
    expect(harness.api.keys, isEmpty);
  });

  testWidgets('ảnh hỏng (cục bộ) → copy ảnh hỏng, chỉ "Chọn ảnh khác"',
      (tester) async {
    harness.compressor.error = const OcrImageInvalidException();
    await harness.pumpScan(tester);
    await tester.tap(_key('receipt-choose-gallery'));
    await tester.pumpAndSettle();

    expectBanner(viL10n.inventoryOcrImageInvalid);
    expect(_key('receipt-choose-another'), findsOneWidget);
    expect(_key('receipt-scan-retry'), findsNothing);
  });

  testWidgets('mất mạng → networkError + Thử lại + Chọn ảnh khác',
      (tester) async {
    await scanWithError(tester, NetworkException());

    expectBanner(viL10n.networkError);
    expect(_key('receipt-scan-retry'), findsOneWidget);
    expect(_key('receipt-choose-another'), findsOneWidget);
  });

  for (final code in <String>[
    'ERR_AI_TIMEOUT',
    'ERR_AI_SERVICE_DOWN',
    'ERR_AI_RATE_LIMIT',
  ]) {
    testWidgets('$code → AI tạm thời + Thử lại + Chọn ảnh khác',
        (tester) async {
      await scanWithError(tester, ServerException(code, 'x'));

      expectBanner(viL10n.receiptErrorAiUnavailable);
      expect(_key('receipt-scan-retry'), findsOneWidget);
      expect(_key('receipt-choose-another'), findsOneWidget);
    });
  }

  testWidgets('503 → Thử lại gửi ĐÚNG key cũ → 200 → sang màn kết quả',
      (tester) async {
    await scanWithError(tester, ServerException('ERR_AI_SERVICE_DOWN', 'x'));
    harness.api.outcomes.add(_result);

    await tester.tap(_key('receipt-scan-retry'));
    await tester.pumpAndSettle();

    expect(harness.api.keys, <String>['key-1', 'key-1']);
    expect(find.text(viL10n.receiptResultTitle), findsOneWidget);
  });

  testWidgets('409 → "vẫn đang đọc" + chỉ Thử lại (không tự retry)',
      (tester) async {
    await scanWithError(
      tester,
      BusinessException('ERR_RECEIPT_SCAN_IN_PROGRESS', 'x'),
    );

    expectBanner(viL10n.receiptErrorInProgress);
    expect(_key('receipt-scan-retry'), findsOneWidget);
    expect(_key('receipt-choose-another'), findsNothing);
    expect(harness.api.keys, hasLength(1));
  });

  for (final error in <ApiException>[
    ServerException('ERR_AI_INVALID_OUTPUT', 'x'),
    BusinessException('ERR_AI_CONTENT_FILTERED', 'x'),
    BusinessException('ERR_RECEIPT_IMAGE_INVALID', 'x'),
    BusinessException('ERR_RECEIPT_IMAGE_TOO_LARGE', 'x'),
  ]) {
    testWidgets('${error.code} → ảnh không dùng được, chỉ "Chọn ảnh khác"',
        (tester) async {
      await scanWithError(tester, error);

      expectBanner(viL10n.receiptErrorImageRejected);
      expect(_key('receipt-choose-another'), findsOneWidget);
      expect(_key('receipt-scan-retry'), findsNothing);
    });
  }

  testWidgets('403 chưa có nhà → không retry, chỉ "Đóng" → về màn trước',
      (tester) async {
    await scanWithError(
      tester,
      BusinessException('ERR_RECEIPT_NO_HOUSEHOLD', 'x'),
    );

    expect(find.text(viL10n.receiptErrorNoHouseholdTitle), findsOneWidget);
    expect(find.text(viL10n.receiptErrorNoHousehold), findsOneWidget);
    expect(_key('receipt-scan-retry'), findsNothing);
    expect(_key('receipt-choose-another'), findsNothing);

    await tester.tap(_key('receipt-no-household-close'));
    await tester.pumpAndSettle();

    expect(find.text(kHomeText), findsOneWidget);
    expect(harness.store.scanError, isNull);
  });

  testWidgets('mã lạ → message của apiErrorMessage + "Chọn ảnh khác"',
      (tester) async {
    await scanWithError(tester, BusinessException('ERR_SOMETHING', 'Lỗi lạ'));

    expectBanner('Lỗi lạ');
    expect(_key('receipt-choose-another'), findsOneWidget);
    expect(_key('receipt-scan-retry'), findsNothing);
  });

  testWidgets('X khi đang có snackbar → pop màn ngay lần bấm đầu',
      (tester) async {
    await harness.pumpScan(tester);
    Get.snackbar('t', 'm', snackPosition: SnackPosition.BOTTOM);
    await tester.pumpAndSettle();
    expect(Get.isSnackbarOpen, isTrue);

    await tester.tap(_key('receipt-scan-close'));
    await tester.pumpAndSettle();

    expect(find.text(kHomeText), findsOneWidget);
    expect(find.text(viL10n.receiptScanTitle), findsNothing);
    await settleSnackbars(tester);
  });
}
