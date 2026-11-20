import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/widgets/app_scaffold.dart';
import 'package:smart_kitchen_mobile/widgets/loading_overlay.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('isLoading=false → không có lớp phủ, nội dung bấm được',
      (tester) async {
    var taps = 0;
    await tester.pumpAppWidget(LoadingOverlay(
      isLoading: false,
      child: TextButton(onPressed: () => taps++, child: const Text('Lưu')),
    ));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Lưu'));
    expect(taps, 1);
  });

  testWidgets('isLoading=true → spinner + message, chặn chạm nội dung',
      (tester) async {
    var taps = 0;
    await tester.pumpAppWidget(LoadingOverlay(
      isLoading: true,
      message: 'Đang lưu',
      child: Center(
        child: TextButton(onPressed: () => taps++, child: const Text('Lưu')),
      ),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Đang lưu'), findsOneWidget);
    await tester.tap(find.text('Lưu'), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('semantics: đọc message 1 lần, ẩn nội dung đang khoá',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppWidget(const LoadingOverlay(
      isLoading: true,
      message: 'Đang lưu',
      child: Text('Nội dung form'),
    ));
    expect(find.bySemanticsLabel('Đang lưu'), findsOneWidget);
    expect(find.bySemanticsLabel('Nội dung form'), findsNothing);
    handle.dispose();
  });

  group('không chặn back navigation (AC4)', () {
    Future<void> openLoadingRoute(WidgetTester tester) async {
      await tester.pumpAppWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AppScaffold(
                  title: 'Thêm thực phẩm',
                  body: LoadingOverlay(isLoading: true, child: Text('form')),
                ),
              ),
            ),
            child: const Text('route-1'),
          ),
        ),
      );
      await tester.tap(find.text('route-1'));
      // Spinner chạy vô hạn nên không pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Thêm thực phẩm'), findsOneWidget);
    }

    testWidgets('nút back trên AppBar vẫn bấm được', (tester) async {
      await openLoadingRoute(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Thêm thực phẩm'), findsNothing);
      expect(find.text('route-1'), findsOneWidget);
    });

    testWidgets('back hệ thống (Android) vẫn pop route', (tester) async {
      await openLoadingRoute(tester);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Thêm thực phẩm'), findsNothing);
      expect(find.text('route-1'), findsOneWidget);
    });
  });

  testWidgets('M2: ô đang focus không submit được khi overlay bật',
      (tester) async {
    var submits = 0;
    Widget build(bool loading) => LoadingOverlay(
          isLoading: loading,
          child: SizedBox(
            height: 300,
            child: TextField(
              autofocus: true,
              onSubmitted: (_) => submits++,
            ),
          ),
        );
    await tester.pumpAppWidget(build(false));
    await tester.pump();
    await tester.pumpAppWidget(build(true));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submits, 0);
  });

  testWidgets('vùng bọc thấp hơn card loading → không overflow',
      (tester) async {
    await tester.pumpAppWidget(const Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 40,
        child: LoadingOverlay(
            isLoading: true, message: 'Đang lưu', child: SizedBox.expand()),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
