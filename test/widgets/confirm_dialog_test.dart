import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';
import 'package:smart_kitchen_mobile/widgets/dialogs/confirm_dialog.dart';

import '../helpers/pump_app.dart';

void main() {
  Future<bool?> Function() openDialog(
    WidgetTester tester, {
    bool isDestructive = false,
  }) {
    bool? result;
    var done = false;
    return () async {
      await tester.pumpAppWidget(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showConfirmDialog(
              context,
              title: 'Xoá mục này?',
              message: 'Không thể hoàn tác.',
              isDestructive: isDestructive,
            );
            done = true;
          },
          child: const Text('open'),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return done ? result : null;
    };
  }

  testWidgets('hiện title, message, nhãn mặc định Huỷ/Xác nhận',
      (tester) async {
    await openDialog(tester)();
    expect(find.text('Xoá mục này?'), findsOneWidget);
    expect(find.text('Không thể hoàn tác.'), findsOneWidget);
    expect(find.text('Huỷ'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
  });

  Future<bool?> runAndClose(
    WidgetTester tester,
    Future<void> Function() close, {
    bool isDestructive = false,
  }) async {
    bool? result;
    await tester.pumpAppWidget(Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          result = await showConfirmDialog(
            context,
            title: 'T',
            message: 'M',
            isDestructive: isDestructive,
          );
        },
        child: const Text('open'),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await close();
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('xác nhận → true', (tester) async {
    final result = await runAndClose(tester,
        () => tester.tap(find.byKey(const ValueKey('confirm-dialog-confirm'))));
    expect(result, isTrue);
  });

  testWidgets('huỷ → false', (tester) async {
    final result = await runAndClose(tester,
        () => tester.tap(find.byKey(const ValueKey('confirm-dialog-cancel'))));
    expect(result, isFalse);
  });

  testWidgets('chạm ra ngoài (barrier) → false, không null', (tester) async {
    final result =
        await runAndClose(tester, () => tester.tapAt(const Offset(5, 5)));
    expect(result, isFalse);
  });

  testWidgets('back hệ thống → false', (tester) async {
    final result =
        await runAndClose(tester, () => tester.binding.handlePopRoute());
    expect(result, isFalse);
  });

  testWidgets('destructive dùng variant destructive, thường dùng primary',
      (tester) async {
    AppButtonVariant confirmVariant() => tester
        .widget<AppButton>(find.byKey(const ValueKey('confirm-dialog-confirm')))
        .variant;

    await tester.pumpAppWidget(
        const ConfirmDialog(title: 'T', message: 'M', isDestructive: true));
    expect(confirmVariant(), AppButtonVariant.destructive);

    await tester.pumpAppWidget(const ConfirmDialog(title: 'T', message: 'M'));
    expect(confirmVariant(), AppButtonVariant.primary);
  });

  testWidgets('nhãn tuỳ chỉnh thay nhãn mặc định', (tester) async {
    await tester.pumpAppWidget(const ConfirmDialog(
      title: 'T',
      message: 'M',
      confirmLabel: 'Xoá',
      cancelLabel: 'Giữ lại',
    ));
    expect(find.text('Xoá'), findsOneWidget);
    expect(find.text('Giữ lại'), findsOneWidget);
  });
}
