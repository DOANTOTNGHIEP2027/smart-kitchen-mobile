import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/recap_badge.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/weekly_recap_summary.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/insight_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  MemberWeeklyInsight insight(String id) => MemberWeeklyInsight(
        memberId: id,
        calorieAvg: 1800,
        calorieGoal: 2000,
        compliancePct: 95,
        badge: RecapBadge.onTrack,
        topNutrientGap: 'protein',
        highlight: 'highlight $id',
        tip: 'tip $id',
      );

  testWidgets('renders compliance% + highlight/tip/nutrient gap (1 card)',
      (tester) async {
    await tester.pumpAppWidget(InsightCard(insight: insight('m1')));

    expect(find.text('95%'), findsOneWidget);
    expect(find.text('highlight m1'), findsOneWidget);
    expect(find.text('tip m1'), findsOneWidget);
  });

  testWidgets('InsightCardList rỗng → hiện emptyText, không render card',
      (tester) async {
    await tester.pumpAppWidget(
      const InsightCardList(
        insights: <MemberWeeklyInsight>[],
        emptyText: 'ko ai',
      ),
    );

    expect(find.text('ko ai'), findsOneWidget);
    expect(find.byType(InsightCard), findsNothing);
  });
}