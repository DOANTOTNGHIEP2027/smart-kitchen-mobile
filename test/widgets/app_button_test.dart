import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/constants/app_dimens.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';
import 'package:smart_kitchen_mobile/widgets/cards/app_card.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('isLoading thay label bằng spinner và chặn tap',
      (WidgetTester tester) async {
    var taps = 0;
    await tester.pumpAppWidget(
      AppButton(label: 'Save', onPressed: () => taps++, isLoading: true),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('trạng thái thường → hiện label và nhận tap',
      (WidgetTester tester) async {
    var taps = 0;
    await tester.pumpAppWidget(
      AppButton(label: 'Save', onPressed: () => taps++),
    );

    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('onPressed null → disabled', (WidgetTester tester) async {
    await tester.pumpAppWidget(
      const AppButton(label: 'Save', onPressed: null),
    );

    final button = tester.widget<ButtonStyleButton>(
        find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(button.onPressed, isNull);
  });

  group('design-system §7.1', () {
    Finder materialButton() =>
        find.byWidgetPredicate((w) => w is ButtonStyleButton);

    testWidgets('6 variant đều render đúng widget M3 và nhận tap 1 lần',
        (WidgetTester tester) async {
      final expectedType = <AppButtonVariant, Type>{
        AppButtonVariant.primary: FilledButton,
        AppButtonVariant.secondary: FilledButton,
        AppButtonVariant.destructive: FilledButton,
        AppButtonVariant.outline: OutlinedButton,
        AppButtonVariant.google: OutlinedButton,
        AppButtonVariant.text: TextButton,
      };
      for (final entry in expectedType.entries) {
        var taps = 0;
        await tester.pumpAppWidget(AppButton(
          label: 'Lưu',
          variant: entry.key,
          onPressed: () => taps++,
        ));
        expect(tester.widget(materialButton()).runtimeType, entry.value,
            reason: '${entry.key}');
        await tester.tap(find.byType(AppButton));
        await tester.pump();
        expect(taps, 1, reason: '${entry.key}');
      }
    });

    testWidgets('loading: nhấn nhanh nhiều lần không gọi callback lần nào',
        (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpAppWidget(
        AppButton(label: 'Lưu', isLoading: true, onPressed: () => taps++),
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(AppButton), warnIfMissed: false);
      }
      await tester.pump();
      expect(taps, 0);
      expect(
          tester.widget<ButtonStyleButton>(materialButton()).onPressed, isNull);
    });

    testWidgets('chiều cao chuẩn 52dp, expanded chiếm hết bề ngang',
        (WidgetTester tester) async {
      await tester.pumpAppWidget(AppButton(label: 'Lưu', onPressed: () {}));
      final size = tester.getSize(find.byType(AppButton));
      expect(size.height, AppDimens.buttonHeight);
      expect(size.width, 800);
    });

    testWidgets('semantics: label đọc đúng 1 lần, là button, enabled',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpAppWidget(AppButton(label: 'Lưu', onPressed: () {}));
      expect(find.bySemanticsLabel('Lưu'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(
            label: 'Lưu', isButton: true, isEnabled: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('semantics loading: có hint "đang xử lý", không enabled',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpAppWidget(
          AppButton(label: 'Lưu', isLoading: true, onPressed: () {}));
      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(
            label: 'Lưu',
            hint: 'Đang xử lý…',
            isEnabled: false,
            hasTapAction: false),
      );
      handle.dispose();
    });

    testWidgets('semantics tap kích hoạt callback (TalkBack double-tap)',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester
          .pumpAppWidget(AppButton(label: 'Lưu', onPressed: () => taps++));
      tester.semantics.tap(find.semantics.byLabel('Lưu'));
      await tester.pump();
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('icon + label hiển thị cùng nhau', (WidgetTester tester) async {
      await tester.pumpAppWidget(
          AppButton(label: 'Thêm', icon: Icons.add, onPressed: () {}));
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Thêm'), findsOneWidget);
    });

    testWidgets('dark: outline lấy màu chữ dark, destructive lấy error dark',
        (WidgetTester tester) async {
      await tester.pumpAppWidget(
        Column(children: <Widget>[
          AppButton(
              label: 'Lọc',
              variant: AppButtonVariant.outline,
              onPressed: () {}),
          AppButton(
              label: 'Xoá',
              variant: AppButtonVariant.destructive,
              onPressed: () {}),
        ]),
        theme: AppTheme.dark,
      );
      expect(tester.widget<Text>(find.text('Lọc')).style?.color,
          AppColors.darkTextPrimary);
      expect(tester.widget<Text>(find.text('Xoá')).style?.color,
          AppColors.darkError);
    });

    testWidgets('light: outline giữ màu chữ #1C1C1E như trước',
        (WidgetTester tester) async {
      await tester.pumpAppWidget(AppButton(
          label: 'Lọc', variant: AppButtonVariant.outline, onPressed: () {}));
      expect(tester.widget<Text>(find.text('Lọc')).style?.color,
          AppColors.textPrimary);
    });
  });

  group('code review 2026-11-20 (hồi quy)', () {
    testWidgets('H1: nút trong AppCard có node semantics riêng',
        (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpAppWidget(AppCard(
        child: Column(children: <Widget>[
          const Text('Món A'),
          AppButton(label: 'Nấu', onPressed: () => taps++),
        ]),
      ));
      final buttonNode = tester.getSemantics(find.byType(AppButton));
      expect(buttonNode.label, 'Nấu');
      final textNode = tester.getSemantics(find.text('Món A'));
      expect(textNode.label, isNot(contains('Nấu')));
      expect(
          textNode.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(taps, 0);
      handle.dispose();
    });

    testWidgets('M3: light giữ màu chữ cũ khi disabled theo variant',
        (tester) async {
      final expected = <AppButtonVariant, Color>{
        AppButtonVariant.primary: AppColors.textOnPrimary,
        AppButtonVariant.secondary: AppColors.primary,
        AppButtonVariant.outline: AppColors.textPrimary,
        AppButtonVariant.google: AppColors.textPrimary,
        AppButtonVariant.text: AppColors.primary,
      };
      for (final e in expected.entries) {
        await tester.pumpAppWidget(
            AppButton(label: 'X', variant: e.key, onPressed: null));
        expect(tester.widget<Text>(find.text('X')).style?.color, e.value,
            reason: '${e.key}');
      }
    });

    testWidgets('L1: label nút filled giữ textStyle cũ (không letterSpacing)',
        (tester) async {
      await tester.pumpAppWidget(AppButton(label: 'Lưu', onPressed: () {}));
      final style = DefaultTextStyle.of(tester.element(find.text('Lưu'))).style;
      expect(style.fontSize, 15);
      expect(style.letterSpacing, isNot(0.1));
    });

    testWidgets('L3: loading không cần AppLocalizations trong cây',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: AppButton(label: 'Lưu', isLoading: true, onPressed: () {})),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
