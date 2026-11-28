import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/recap/scenes/monthly_recap_scene.dart';
import 'package:smart_kitchen_mobile/scenes/recap/stores/monthly_recap_store.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/insight_card.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/monthly_recap_widgets.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/shareable_recap_card.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/waste_spend_sections.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';

import '../../helpers/pump_app.dart';
import 'monthly_recap_store_test.dart' show FakeMonthlyRecapApi, makeSession;

void main() {
  final today = DateTime(2026, 11, 28);
  late FakeMonthlyRecapApi api;

  setUp(() {
    api = FakeMonthlyRecapApi(
      current: DateTime(2026, 11),
      earliest: DateTime(2026, 10),
    );
  });
  tearDown(Get.reset);

  Future<MonthlyRecapStore> pumpScene(WidgetTester tester) async {
    final store = MonthlyRecapStore(api, makeSession(), now: () => today);
    Get.put<MonthlyRecapStore>(store);
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAppWidget(const MonthlyRecapScene(),
        wrapInScaffold: false);
    await tester.pump();
    await tester.pump();
    return store;
  }

  IconButton navButton(WidgetTester tester, Key key) =>
      tester.widget<IconButton>(find.byKey(key));

  testWidgets('tháng hiện tại: đủ các khối, nút tháng sau tắt, tháng trước bật',
      (tester) async {
    await pumpScene(tester);

    expect(find.text('Tổng kết tháng'), findsOneWidget);
    expect(find.text('Tháng 11/2026'), findsOneWidget);
    expect(find.byType(MonthlyRecapShareCard), findsOneWidget);
    expect(find.text('Calo trung bình mỗi ngày'), findsOneWidget);
    expect(find.text('1850'), findsOneWidget);
    expect(find.text('Chuỗi tuần đạt mục tiêu'), findsOneWidget);
    expect(find.text('2 tuần'), findsOneWidget);
    expect(find.byType(MonthlyMemberInsightCard), findsOneWidget);
    expect(find.byType(WasteSection), findsOneWidget);
    expect(find.byType(SpendSection), findsOneWidget);
    expect(find.byType(SpendDetailSection), findsOneWidget);
    expect(find.text('Lãng phí trong tháng'), findsOneWidget);
    expect(find.text('Chi tiêu trong tháng'), findsOneWidget);
    expect(find.text('Từ 01/11 đến 30/11'), findsNWidgets(2));
    // Ngân sách tháng 2.500.000, chi 1.250.000 → 50% ngân sách THÁNG.
    expect(find.text('50% ngân sách tháng'), findsOneWidget);

    expect(navButton(tester, MonthNavigator.nextKey).onPressed, isNull);
    expect(navButton(tester, MonthNavigator.previousKey).onPressed, isNotNull);

    // Số tiền không nằm trong vùng chụp ảnh chia sẻ.
    final shareBoundary = find
        .ancestor(
            of: find.byType(MonthlyRecapShareCard),
            matching: find.byType(RepaintBoundary))
        .first;
    expect(
        find.descendant(of: shareBoundary, matching: find.byType(SpendSection)),
        findsNothing);
  });

  testWidgets('mở danh sách tuần của thành viên → hiện "Tuần dd/MM"',
      (tester) async {
    await pumpScene(tester);
    expect(find.byType(InsightCard), findsOneWidget);
    expect(find.text('Tuần 02/11'), findsNothing);

    await tester.tap(find.text('Xem chi tiết từng tuần (1)'));
    await tester.pump();
    expect(find.text('Tuần 02/11'), findsOneWidget);
    expect(find.byType(InsightCard), findsNWidgets(2));
    expect(find.text('Ẩn chi tiết từng tuần'), findsOneWidget);
  });

  testWidgets('lùi về tháng sớm nhất: tháng trước tắt, tháng sau bật',
      (tester) async {
    await pumpScene(tester);
    await tester.tap(find.byKey(MonthNavigator.previousKey));
    await tester.pump();
    await tester.pump();

    expect(find.text('Tháng 10/2026'), findsOneWidget);
    expect(api.calls.last, DateTime(2026, 10));
    expect(navButton(tester, MonthNavigator.previousKey).onPressed, isNull);
    expect(navButton(tester, MonthNavigator.nextKey).onPressed, isNotNull);
  });

  testWidgets('isStale: hero fallback + câu trống insight, vẫn có lãng phí',
      (tester) async {
    api.extra = <String, dynamic>{
      'isStale': true,
      'memberInsights': <dynamic>[],
      'householdSummary': null,
      'suggestedFocus': null,
    };
    await pumpScene(tester);
    expect(find.byKey(ShareableRecapCard.recapHeroFallbackKey), findsOneWidget);
    expect(find.text('Chưa có nhận xét cá nhân hoá nào cho tháng này.'),
        findsOneWidget);
    expect(find.byType(WasteSection), findsOneWidget);
  });

  testWidgets('lỗi → màn lỗi có Thử lại, bấm thì tải lại thành công',
      (tester) async {
    api.error = BusinessException('ERR_RECAP_MONTH_INVALID', 'invalid');
    await pumpScene(tester);
    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('Tháng này chưa có tổng kết. Hãy chọn tháng khác.'),
        findsOneWidget);
    expect(navButton(tester, MonthNavigator.previousKey).onPressed, isNull);

    api.error = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppErrorView), findsNothing);
    expect(find.byType(MonthlyRecapShareCard), findsOneWidget);
  });
}
