import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_icons.dart';
import 'package:smart_kitchen_mobile/widgets/inputs/app_text_field.dart';

import '../helpers/pump_app.dart';

void main() {
  String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null;

  testWidgets('label nằm trên ô + hint', (tester) async {
    await tester.pumpAppWidget(
        const AppTextField(label: 'Tên thực phẩm', hint: 'Cà chua'));
    expect(find.text('Tên thực phẩm'), findsOneWidget);
    expect(find.text('Cà chua'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Tên thực phẩm')).dy,
      lessThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
  });

  testWidgets('nhập hợp lệ → không hiện lỗi', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpAppWidget(AppTextField(
        label: 'Tên', controller: controller, validator: required));
    await tester.enterText(find.byType(TextField), 'Cà chua');
    await tester.pump();
    expect(find.text('Bắt buộc'), findsNothing);
    expect(controller.text, 'Cà chua');
  });

  testWidgets('nhập rồi xoá (không hợp lệ) → hiện message lỗi', (tester) async {
    await tester.pumpAppWidget(AppTextField(label: 'Tên', validator: required));
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Bắt buộc'), findsOneWidget);
  });

  testWidgets('Form.validate() hiện lỗi khi chưa nhập', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpAppWidget(Form(
      key: formKey,
      child: AppTextField(label: 'Tên', validator: required),
    ));
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Bắt buộc'), findsOneWidget);
  });

  testWidgets('errorText từ ngoài thắng kết quả validator', (tester) async {
    await tester.pumpAppWidget(AppTextField(
      label: 'Email',
      validator: (_) => 'Lỗi validator',
      errorText: 'Email đã tồn tại',
    ));
    await tester.enterText(find.byType(TextField), 'a@b.c');
    await tester.pump();
    expect(find.text('Email đã tồn tại'), findsOneWidget);
    expect(find.text('Lỗi validator'), findsNothing);
  });

  testWidgets('mật khẩu: ẩn mặc định, bấm nút → hiện', (tester) async {
    await tester.pumpAppWidget(
        const AppTextField(label: 'Mật khẩu', obscureText: true));
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.tap(find.byIcon(AppIcons.visibility));
    await tester.pump();
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    expect(find.byIcon(AppIcons.visibilityOff), findsOneWidget);
  });

  testWidgets('disabled → TextField không cho nhập', (tester) async {
    await tester
        .pumpAppWidget(const AppTextField(label: 'Đơn vị', enabled: false));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('semantics: label được gộp với ô nhập', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppWidget(const AppTextField(label: 'Tên thực phẩm'));
    expect(
      tester.getSemantics(find.byType(TextField)),
      isSemantics(label: 'Tên thực phẩm', isTextField: true),
    );
    handle.dispose();
  });

  testWidgets('M1: nút ẩn/hiện mật khẩu tới được bằng semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAppWidget(
        const AppTextField(label: 'Mật khẩu', obscureText: true));
    final toggle =
        find.semantics.byPredicate((node) => node.tooltip == 'Hiện mật khẩu');
    expect(toggle, findsOne);
    tester.semantics.tap(toggle);
    await tester.pump();
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    handle.dispose();
  });

  testWidgets('L4: đổi obscureText lúc chạy → ô cập nhật theo', (tester) async {
    await tester
        .pumpAppWidget(const AppTextField(label: 'Mã', obscureText: true));
    await tester.pumpAppWidget(const AppTextField(label: 'Mã'));
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
  });
}
