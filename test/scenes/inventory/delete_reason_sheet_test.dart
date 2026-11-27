import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/widgets/delete_confirm_dialog.dart';

import '../../helpers/pump_app.dart';

/// Luồng xoá mặt hàng (#201): dialog chỉ Huỷ/Xoá, sau đó MỘT sheet lý do.
void main() {
  Future<void> pumpOpener(
      WidgetTester tester, Future<void> Function(BuildContext) open) async {
    await tester.pumpAppWidget(Builder(
      builder: (context) => TextButton(
        onPressed: () => open(context),
        child: const Text('open'),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('dialog xác nhận chỉ có Huỷ / Xoá', (tester) async {
    bool? confirmed;
    await pumpOpener(
        tester, (c) async => confirmed = await showDeleteConfirmDialog(c));
    expect(find.byType(TextButton), findsNWidgets(2)); // 'open' + Huỷ
    expect(find.byKey(const ValueKey<String>('inventory-delete-cancel')),
        findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey<String>('inventory-delete-confirm')));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('chọn "Đã dùng hết" → COOKED, không wasteCause', (tester) async {
    DeleteReasonChoice? choice;
    await pumpOpener(
        tester, (c) async => choice = await showDeleteReasonSheet(c));
    await tester.tap(find.byKey(const ValueKey<String>('delete-reason-cooked')));
    await tester.pumpAndSettle();
    expect(choice?.wire, 'COOKED');
    expect(choice?.wasteCause, isNull);
  });

  testWidgets('chọn nguyên nhân bỏ đi → WASTE + wasteCause', (tester) async {
    DeleteReasonChoice? choice;
    await pumpOpener(
        tester, (c) async => choice = await showDeleteReasonSheet(c));
    final tile =
        find.byKey(const ValueKey<String>('delete-reason-waste-forgotten'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(choice?.wire, 'WASTE');
    expect(choice?.wasteCause, 'FORGOTTEN');
  });

  testWidgets('đóng sheet không chọn → CORRECTED', (tester) async {
    DeleteReasonChoice? choice;
    await pumpOpener(
        tester, (c) async => choice = await showDeleteReasonSheet(c));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(choice?.wire, 'CORRECTED');
    expect(choice?.wasteCause, isNull);
  });
}
