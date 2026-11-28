import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_dimens.dart';
import 'package:smart_kitchen_mobile/widgets/feedback/app_toast.dart';

import '../helpers/pump_app.dart';

void main() {
  tearDown(AppToast.hide);

  testWidgets('hiện text ở góc trên-trái rồi tự ẩn sau duration',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(const SizedBox());

    AppToast.show('Đã sao chép', type: AppToastType.success);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Đã sao chép'), findsOneWidget);
    final card = find
        .ancestor(of: find.text('Đã sao chép'), matching: find.byType(Material))
        .first;
    expect(tester.getTopLeft(card), const Offset(AppDimens.md, AppDimens.md));

    await tester.pump(AppToast.defaultDuration);
    await tester.pumpAndSettle();
    expect(find.text('Đã sao chép'), findsNothing);
  });

  testWidgets('toast mới thay toast đang hiện, không xếp chồng',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(const SizedBox());

    AppToast.show('Một');
    await tester.pump();
    AppToast.show('Hai', type: AppToastType.error);
    await tester.pump();
    expect(find.text('Một'), findsNothing);
    expect(find.text('Hai'), findsOneWidget);
    expect(find.byKey(AppToast.toastKey), findsOneWidget);
  });

  testWidgets('nằm trên bottom sheet (Overlay gốc)',
      (WidgetTester tester) async {
    await tester.pumpAppWidget(Builder(
      builder: (context) => TextButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const SizedBox(height: 200, child: Text('Sheet')),
        ),
        child: const Text('Mở'),
      ),
    ));
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    AppToast.show('Trên sheet');
    await tester.pump();
    expect(find.text('Trên sheet'), findsOneWidget);
    expect(find.text('Sheet'), findsOneWidget);
  });
}
