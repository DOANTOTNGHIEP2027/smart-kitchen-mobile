import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/constants/app_icons.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_empty_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AppErrorView', () {
    testWidgets('message + retry: nhấn retry gọi callback đúng 1 lần',
        (tester) async {
      var retries = 0;
      await tester.pumpAppWidget(
          AppErrorView(message: 'Lỗi mạng', onRetry: () => retries++));
      expect(find.text('Lỗi mạng'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(retries, 1);
    });

    testWidgets('không onRetry → không có nút, message mặc định',
        (tester) async {
      await tester.pumpAppWidget(const AppErrorView());
      expect(find.byType(AppButton), findsNothing);
      expect(find.text('Đã có lỗi xảy ra'), findsOneWidget);
    });

    testWidgets('icon lỗi lấy màu error theo theme', (tester) async {
      await tester.pumpAppWidget(const AppErrorView(), theme: AppTheme.dark);
      expect(tester.widget<Icon>(find.byIcon(AppIcons.error)).color,
          AppColors.darkError);
    });
  });

  group('AppEmptyView', () {
    testWidgets('không action → chỉ icon + message mặc định', (tester) async {
      await tester.pumpAppWidget(const AppEmptyView());
      expect(find.byIcon(AppIcons.empty), findsOneWidget);
      expect(find.text('Chưa có dữ liệu'), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('có action → hiện và bấm được', (tester) async {
      var taps = 0;
      await tester.pumpAppWidget(AppEmptyView(
        message: 'Kho trống',
        action:
            AppButton(label: 'Thêm', expanded: false, onPressed: () => taps++),
      ));
      expect(find.text('Kho trống'), findsOneWidget);
      await tester.tap(find.text('Thêm'));
      expect(taps, 1);
    });

    testWidgets('illustration thay chỗ icon', (tester) async {
      await tester.pumpAppWidget(const AppEmptyView(
        illustration: SizedBox(key: ValueKey<String>('art'), height: 400),
      ));
      expect(find.byKey(const ValueKey<String>('art')), findsOneWidget);
      expect(find.byIcon(AppIcons.empty), findsNothing);
      expect(
          tester.getSize(find.byKey(const ValueKey<String>('art'))).height, 160,
          reason: 'illustration bị giới hạn 160');
    });

    testWidgets('màn 320×480, chữ to ×2: không overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpAppWidget(AppEmptyView(
        message: 'Chưa có thực phẩm nào trong kho. Hãy thêm món đầu tiên '
            'để bắt đầu theo dõi hạn dùng và nhận gợi ý món ăn.',
        action: AppButton(label: 'Thêm', expanded: false, onPressed: () {}),
      ));
      expect(tester.takeException(), isNull);
      await tester
          .pumpAppWidget(AppErrorView(message: 'Lỗi ' * 60, onRetry: () {}));
      expect(tester.takeException(), isNull);
    });

    testWidgets('trong ListView (chiều cao vô hạn) không crash',
        (tester) async {
      await tester.pumpAppWidget(ListView(
        children: <Widget>[
          const AppEmptyView(),
          AppErrorView(onRetry: () {}),
        ],
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(AppEmptyView), findsOneWidget);
      expect(find.byType(AppErrorView), findsOneWidget);
    });
  });

  testWidgets('AppLoadingView dùng màu primary của theme', (tester) async {
    await tester.pumpAppWidget(const AppLoadingView());
    final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator));
    expect((indicator.valueColor! as AlwaysStoppedAnimation<Color>).value,
        AppColors.primary);
  });
}
