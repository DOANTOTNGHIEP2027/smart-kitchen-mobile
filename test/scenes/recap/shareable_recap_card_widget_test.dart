import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/household_streak.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/recap_badge.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/weekly_recap_summary.dart';
import 'package:smart_kitchen_mobile/scenes/recap/stores/weekly_recap_store.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/shareable_recap_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  WeeklyRecapSummary summary({bool stale = false, bool emptyInsights = false}) =>
      WeeklyRecapSummary(
        householdId: 'h1',
        weekStart: DateTime(2026, 3, 2),
        mealsLoggedCount: 12,
        avgCaloriesKcal: 1900,
        adherencePercent: 88,
        memberInsights: emptyInsights
            ? const <MemberWeeklyInsight>[]
            : <MemberWeeklyInsight>[
                const MemberWeeklyInsight(
                  memberId: 'me',
                  calorieAvg: 1800,
                  calorieGoal: 2000,
                  compliancePct: 95,
                  badge: RecapBadge.onTrack,
                  topNutrientGap: 'protein',
                  highlight: 'hl me',
                  tip: 'tip me',
                ),
              ],
        householdSummary: stale ? null : 'Cả nhà tốt',
        suggestedFocus: 'Rau',
        isStale: stale,
        computedAt: DateTime.utc(2026, 3, 8, 7),
      );

  const streak = HouseholdStreak(
    householdId: 'h1',
    currentStreak: 4,
    bestStreak: 9,
    lastComputedWeekStart: null,
  );

  Widget build({
    bool stale = false,
    RecapLoadStatus streakStatus = RecapLoadStatus.ready,
    HouseholdStreak? streak = streak,
  }) =>
      ShareableRecapCard(
        summary: summary(stale: stale),
        ownInsight: stale ? null : summary().memberInsights.first,
        streakStatus: streakStatus,
        streak: streak,
        onRetryStreak: () {},
      );

  testWidgets('isStale + ownInsight null → hero fallback, vẫn hiển thị streak',
      (tester) async {
    await tester.pumpAppWidget(build(stale: true));

    expect(find.byKey(ShareableRecapCard.recapHeroFallbackKey), findsOneWidget);
    expect(find.text('4 tuần'), findsOneWidget);
    expect(find.text('Kỷ lục 9'), findsOneWidget);
  });

  testWidgets('streakStatus loading → spinner, không có flame', (tester) async {
    await tester.pumpAppWidget(build(streakStatus: RecapLoadStatus.loading));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('streakStatus error → nút retry streak', (tester) async {
    var retried = false;
    await tester.pumpAppWidget(ShareableRecapCard(
      summary: summary(),
      ownInsight: summary().memberInsights.first,
      streakStatus: RecapLoadStatus.error,
      streak: null,
      onRetryStreak: () => retried = true,
    ));
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.error_outline));
    expect(retried, isTrue);
  });
}