import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_matched_item.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_scan_result.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/domain/receipt_unmatched_item.dart';
import 'package:smart_kitchen_mobile/scenes/receipt/stores/receipt_scan_store.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import 'receipt_widget_harness.dart';

Finder _key(String value) => find.byKey(ValueKey<String>(value));

ReceiptMatchedItem _line(
  int index,
  String id, {
  required double confidence,
  double? totalPrice,
}) =>
    ReceiptMatchedItem(
      lineKey: 'm$index',
      shoppingItemId: id,
      shoppingItemName: 'Món $id',
      rawName: 'RAW $index',
      quantity: 1,
      unit: 'kg',
      totalPrice: totalPrice,
      matchConfidence: confidence,
    );

/// 5 dòng khớp (m0+m1 cùng si-1) · 4 món; badge chỉ ở m1 (0.87) và m2 (0.86);
/// m4 = 0.9 đúng ngưỡng → KHÔNG badge.
final List<ReceiptMatchedItem> _fiveLines = <ReceiptMatchedItem>[
  _line(0, 'si-1', confidence: 0.95, totalPrice: 25000),
  _line(1, 'si-1', confidence: 0.87, totalPrice: 12000),
  _line(2, 'si-2', confidence: 0.86, totalPrice: 5000),
  _line(3, 'si-3', confidence: 0.99),
  _line(4, 'si-4', confidence: 0.9, totalPrice: 8000),
];

const ReceiptUnmatchedItem _noUnit = ReceiptUnmatchedItem(
  itemId: 'u-1',
  name: 'Sữa chua',
  category: 'Sữa',
  quantity: 4,
  rawName: 'SUA CHUA',
  rawQuantity: 4,
  rawUnit: 'hũ',
  matchConfidence: 0.71,
);

const ReceiptUnmatchedItem _withUnit = ReceiptUnmatchedItem(
  itemId: 'u-2',
  name: 'Nước mắm',
  quantity: 1,
  unit: 'cái',
  rawName: 'NUOC MAM',
  rawQuantity: 1,
  rawUnit: 'chai',
);

ReceiptScanResult _result({
  List<ReceiptMatchedItem>? matched,
  List<ReceiptUnmatchedItem>? unmatched,
  ReceiptScanMeta? meta,
}) =>
    ReceiptScanResult(
      meta: meta ??
          ReceiptScanMeta(
            scanId: 'scan-1',
            storeName: 'Winmart+ Nguyễn Trãi',
            purchaseDate: DateTime(2026, 10, 14),
            totalAmount: 89000,
            currency: 'VND',
          ),
      matchedItems: matched ?? _fiveLines,
      unmatchedItems:
          unmatched ?? const <ReceiptUnmatchedItem>[_noUnit, _withUnit],
    );

void main() {
  late ReceiptHarness harness;

  setUp(() {
    Get.testMode = true;
    harness = ReceiptHarness();
  });
  tearDown(Get.reset);

  group('hiển thị', () {
    testWidgets('5 dòng khớp + 2 thẻ ngoài danh sách đều render, đếm đúng',
        (tester) async {
      await harness.pumpResult(tester, _result());

      expect(find.text(viL10n.receiptResultTitle), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        expect(_key('receipt-line-m$i'), findsOneWidget);
      }
      expect(_key('receipt-unmatched-u-1'), findsOneWidget);
      expect(_key('receipt-unmatched-u-2'), findsOneWidget);
      expect(find.text(viL10n.receiptMatchedCount(5, 4)), findsOneWidget);
      expect(find.text(viL10n.receiptUnmatchedCount(2)), findsOneWidget);
      expect(find.text(viL10n.receiptSummaryCounts(5, 2)), findsOneWidget);
      // Matched chọn sẵn hết, nút chung đếm theo MÓN (dedupe).
      expect(find.text(viL10n.receiptCommit(4)), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        final box = tester.widget<Checkbox>(_key('receipt-line-check-m$i'));
        expect(box.value, isTrue);
      }
    });

    testWidgets('badge "Kiểm tra lại" CHỈ ở dòng matched < 0.9',
        (tester) async {
      await harness.pumpResult(tester, _result());

      expect(find.text(viL10n.receiptBadgeReview), findsNWidgets(2));
      expect(_key('receipt-review-badge-m1'), findsOneWidget);
      expect(_key('receipt-review-badge-m2'), findsOneWidget);
      expect(_key('receipt-review-badge-m0'), findsNothing);
      expect(_key('receipt-review-badge-m3'), findsNothing);
      expect(_key('receipt-review-badge-m4'), findsNothing); // đúng 0.9
      // Thẻ unmatched có matchConfidence 0.71 → chỉ nhãn xám, không badge.
      expect(
        find.descendant(
          of: _key('receipt-unmatched-u-1'),
          matching: find.text(viL10n.receiptBadgeReview),
        ),
        findsNothing,
      );
      expect(find.text(viL10n.receiptCatalogHint(71)), findsOneWidget);
    });

    testWidgets('header đủ field: cửa hàng · ngày · tổng', (tester) async {
      await harness.pumpResult(tester, _result());

      expect(find.text('Winmart+ Nguyễn Trãi'), findsOneWidget);
      expect(
        find.text('14/10/2026 · ${viL10n.receiptSummaryTotal('89.000 ₫')}'),
        findsOneWidget,
      );
    });

    testWidgets('header chỉ có ngày → ẩn cửa hàng + tổng', (tester) async {
      await harness.pumpResult(
        tester,
        _result(
          meta: ReceiptScanMeta(
            scanId: 's',
            purchaseDate: DateTime(2026, 10, 14),
            currency: 'VND',
          ),
        ),
      );

      expect(_key('receipt-header-store'), findsNothing);
      expect(find.text('14/10/2026'), findsOneWidget);
      expect(find.textContaining('89.000'), findsNothing);
    });

    testWidgets('header cả 3 null → chỉ còn dòng đếm', (tester) async {
      await harness.pumpResult(
        tester,
        _result(meta: const ReceiptScanMeta(scanId: 's', currency: 'VND')),
      );

      expect(_key('receipt-header-store'), findsNothing);
      expect(_key('receipt-header-details'), findsNothing);
      expect(_key('receipt-header-counts'), findsOneWidget);
    });

    testWidgets('kết quả rỗng → copy empty + "Chụp lại" về màn scan idle',
        (tester) async {
      await harness.pumpResult(
        tester,
        _result(
          matched: const <ReceiptMatchedItem>[],
          unmatched: const <ReceiptUnmatchedItem>[],
        ),
      );

      expect(find.text(viL10n.receiptEmpty), findsOneWidget);
      await tester.tap(find.text(viL10n.receiptRetake));
      await tester.pumpAndSettle();

      expect(find.text(viL10n.receiptScanTitle), findsOneWidget);
      expect(find.text(viL10n.receiptScanHint), findsOneWidget);
      expect(harness.store.status, ReceiptScanStatus.idle);
      expect(harness.store.canResend, isFalse);
    });
  });

  group('cập nhật danh sách mua sắm', () {
    testWidgets('bỏ chọn 1 dòng → commit KHÔNG gửi id đó; còn thẻ mở → "Xong"',
        (tester) async {
      await harness.pumpResult(tester, _result());

      await tester.tap(_key('receipt-line-check-m2'));
      await tester.pump();
      expect(find.text(viL10n.receiptCommit(3)), findsOneWidget);

      await tester.tap(_key('receipt-commit'));
      await tester.pumpAndSettle();

      expect(harness.shopping.calls.single.keys.toSet(),
          <String>{'si-1', 'si-3', 'si-4'});
      expect(harness.shopping.calls.single['si-1'], 37000); // 25.000 + 12.000
      // Còn thẻ unmatched chưa thêm → ở lại, nút chung là "Xong" (Q9).
      expect(find.text(viL10n.receiptResultTitle), findsOneWidget);
      expect(_key('receipt-done'), findsOneWidget);
      expect(
        find.descendant(
          of: _key('receipt-line-outcome-m2'),
          matching: find.text(viL10n.receiptSkipped),
        ),
        findsOneWidget,
      );
      expect(find.text(viL10n.receiptMarkedBought), findsNWidgets(4));
      final box = tester.widget<Checkbox>(_key('receipt-line-check-m0'));
      expect(box.onChanged, isNull); // khoá sau commit
    });

    testWidgets('có món thất bại → ở lại + banner + "Chưa cập nhật được"',
        (tester) async {
      harness.shopping.failures = <String>['si-3'];
      await harness.pumpResult(
        tester,
        _result(unmatched: const <ReceiptUnmatchedItem>[]),
      );

      await tester.tap(_key('receipt-commit'));
      await tester.pumpAndSettle();

      expect(find.text(viL10n.receiptCommitFailedBanner(1)), findsOneWidget);
      expect(
        find.descendant(
          of: _key('receipt-line-outcome-m3'),
          matching: find.text(viL10n.receiptNotUpdated),
        ),
        findsOneWidget,
      );
      expect(find.text(kHomeText), findsNothing);
      expect(_key('receipt-done'), findsOneWidget);
    });

    testWidgets(
        'thành công, không còn thẻ mở → pop ĐÚNG 2 màn + snackbar + mở cất vào kho',
        (tester) async {
      await harness.pumpResult(
        tester,
        _result(unmatched: const <ReceiptUnmatchedItem>[]),
      );

      await tester.tap(_key('receipt-commit'));
      await tester.pumpAndSettle();

      // #239: pop result + scan rồi mở màn cất vào kho ngay trên shell.
      expect(find.text(kCheckoutText), findsOneWidget);
      expect(Get.currentRoute, AppRoutes.shoppingCheckout);
      expect(find.text(viL10n.receiptResultTitle), findsNothing);
      expect(find.text(viL10n.receiptScanTitle), findsNothing);
      expect(find.text(viL10n.receiptDoneToast(4)), findsOneWidget);
      expect(harness.store.status, ReceiptScanStatus.idle);
      await settleSnackbars(tester);
      Get.back<void>();
      await tester.pumpAndSettle();
      expect(find.text(kHomeText), findsOneWidget);
    });

    testWidgets('double-tap "Cập nhật" → bulkCheck 1 lần, không pop sớm/2 lần',
        (tester) async {
      final gate = Completer<List<String>>();
      harness.shopping.gate = gate;
      await harness.pumpResult(
        tester,
        _result(unmatched: const <ReceiptUnmatchedItem>[]),
      );

      await tester.tap(_key('receipt-commit'));
      await tester.tap(_key('receipt-commit'), warnIfMissed: false);
      await tester.pump();

      expect(harness.shopping.calls, hasLength(1));
      expect(harness.store.status, ReceiptScanStatus.committing);
      expect(find.text(viL10n.receiptResultTitle), findsOneWidget);
      expect(_key('receipt-restart'), findsNothing); // khoá khi committing

      gate.complete(<String>[]);
      await tester.pumpAndSettle();

      expect(find.text(kCheckoutText), findsOneWidget);
      await settleSnackbars(tester);
      Get.back<void>();
      await tester.pumpAndSettle();
      expect(find.text(kHomeText), findsOneWidget);
    });

    testWidgets('vào từ route /shopping độc lập → "Xong" về đúng /shopping',
        (tester) async {
      await harness.pumpResult(
        tester,
        _result(matched: const <ReceiptMatchedItem>[]),
        viaShopping: true,
      );
      expect(Get.currentRoute, AppRoutes.receiptScanResult);

      await tester.tap(_key('receipt-done'));
      await tester.pumpAndSettle();

      expect(find.text(kShoppingText), findsOneWidget);
      expect(find.text(viL10n.receiptScanTitle), findsNothing);
      expect(Get.currentRoute, AppRoutes.shopping);
      expect(harness.store.status, ReceiptScanStatus.idle);
    });

    testWidgets('double-tap "Xong" → vẫn còn shell (pop đúng 2 màn)',
        (tester) async {
      await harness.pumpResult(
        tester,
        _result(matched: const <ReceiptMatchedItem>[]),
      );
      expect(_key('receipt-done'), findsOneWidget);

      // Gọi thẳng onPressed 2 lần trong cùng frame: tap thứ 2 qua tester sẽ
      // bị IgnorePointer của route đang pop nuốt mất, không kiểm được guard.
      final onPressed =
          tester.widget<AppButton>(_key('receipt-done')).onPressed!;
      onPressed();
      onPressed();
      await tester.pumpAndSettle();

      expect(find.text(kHomeText), findsOneWidget);
      expect(Get.currentRoute, '/');
    });

    testWidgets('"Đặt lại" khi có snackbar → về màn scan ngay lần bấm đầu',
        (tester) async {
      await harness.pumpResult(tester, _result());
      Get.snackbar('t', 'm', snackPosition: SnackPosition.BOTTOM);
      await tester.pumpAndSettle();

      await tester.tap(_key('receipt-restart'));
      await tester.pumpAndSettle();

      expect(find.text(viL10n.receiptScanTitle), findsOneWidget);
      expect(find.text(viL10n.receiptResultTitle), findsNothing);
      expect(harness.store.status, ReceiptScanStatus.idle);
      await settleSnackbars(tester);
    });
  });

  group('thẻ ngoài danh sách', () {
    testWidgets('chưa có đơn vị → nút khoá + gợi ý; chọn đơn vị → bật',
        (tester) async {
      await harness.pumpResult(tester, _result());

      final card = _key('receipt-unmatched-u-1');
      expect(
        find.descendant(of: card, matching: find.text(viL10n.receiptUnitHint)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text(viL10n.receiptAddToInventory),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.descendant(
                of: _key('receipt-unmatched-action-u-1'),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(_key('receipt-unmatched-unit-u-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('cái / gói / hộp / chai / túi'));
      await tester.pumpAndSettle();

      expect(harness.store.unmatchedItems.first.unit, 'cái');
      expect(
        find.descendant(of: card, matching: find.text(viL10n.receiptUnitHint)),
        findsNothing,
      );
    });

    testWidgets('Thêm → đang thêm → "Đã thêm"; double-tap chỉ ghi 1 lần',
        (tester) async {
      final pending = Completer<bool>();
      harness.stubSave(() => pending.future);
      await harness.pumpResult(tester, _result());

      final action = _key('receipt-unmatched-action-u-2');
      await tester.tap(action);
      await tester.tap(action, warnIfMissed: false);
      await tester.pump();

      expect(harness.saveCallCount(), 1);
      expect(
        find.descendant(
          of: action,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      // Đang có thẻ confirming → "Đặt lại" ẩn.
      expect(_key('receipt-restart'), findsNothing);

      pending.complete(true);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: action, matching: find.text(viL10n.receiptAdded)),
        findsOneWidget,
      );
      await tester.tap(action, warnIfMissed: false);
      await tester.pump();
      harness.verifyNoSave(); // verify() trước đã reset số đếm
    });

    testWidgets('lỗi → "Thử lại" + copy lỗi; Thử lại thành công → "Đã thêm"',
        (tester) async {
      harness.stubSave(() async => false, error: NetworkException());
      await harness.pumpResult(tester, _result());

      final action = _key('receipt-unmatched-action-u-2');
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: action, matching: find.text(viL10n.retry)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _key('receipt-unmatched-u-2'),
          matching: find.text(viL10n.networkError),
        ),
        findsOneWidget,
      );

      harness.stubSave(() async => true);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: action, matching: find.text(viL10n.receiptAdded)),
        findsOneWidget,
      );
      expect(
        harness.store.unmatchedItems.last.confirmStatus,
        ReceiptConfirmStatus.confirmed,
      );
    });
  });
}
