import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/meal_log_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/widgets/calorie_confirm_sheet.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/widgets/confidence_badge.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/widgets/meal_log_card.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/form_status.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import '../../helpers/pump_app.dart';

class _MockStore extends Mock implements MealLogStore {}

MealLogEntry entry({
  String id = 'id1',
  double? caloriesKcal,
  MealEntryStatus status = MealEntryStatus.saved,
  bool requiresConfirmation = false,
}) {
  return MealLogEntry(
    id: id,
    householdId: 'h1',
    memberId: 'u1',
    loggedBy: 'u1',
    description: '[Bữa trưa] Phở',
    caloriesKcal: caloriesKcal,
    requiresConfirmation: requiresConfirmation,
    confirmedByUser: false,
    loggedAt: DateTime.parse('2026-09-16T07:00:00Z'),
    status: status,
  );
}

void main() {
  group('ConfidenceBadge', () {
    testWidgets('confident → green dot, không text', (tester) async {
      await tester.pumpAppWidget(
          const ConfidenceBadge(badge: MealConfidenceBadge.confident));
      // không nhãn text
      expect(find.text('Cần xác nhận'), findsNothing);
      expect(find.text('Chưa có ước tính'), findsNothing);
    });

    testWidgets('needsReview → nhãn "Cần xác nhận"', (tester) async {
      await tester.pumpAppWidget(
          const ConfidenceBadge(badge: MealConfidenceBadge.needsReview));
      expect(find.text('Cần xác nhận'), findsOneWidget);
    });

    testWidgets('noEstimate → nhãn "Chưa có ước tính"', (tester) async {
      await tester.pumpAppWidget(
          const ConfidenceBadge(badge: MealConfidenceBadge.noEstimate));
      expect(find.text('Chưa có ước tính'), findsOneWidget);
    });

    testWidgets('KHÔNG BAO GIỜ trả SizedBox.shrink (safety regression)',
        (tester) async {
      for (final badge in MealConfidenceBadge.values) {
        await tester.pumpAppWidget(ConfidenceBadge(badge: badge));
        // luôn render content có visual (dot/pill), không phải shrink
        expect(find.byType(Container).evaluate(), isNotEmpty);
      }
    });
  });

  group('MealLogCard', () {
    testWidgets('saved + calories → hiện số calo + badge', (tester) async {
      await tester.pumpAppWidget(
        Material(child: MealLogCard(entry: entry(caloriesKcal: 480), onTap: () {})),
      );
      expect(find.text('Bữa trưa'), findsOneWidget);
      expect(find.textContaining('480'), findsOneWidget);
      expect(find.byType(ConfidenceBadge), findsOneWidget);
    });

    testWidgets('pending → spinner + "Đang lưu…", không badge', (tester) async {
      await tester.pumpAppWidget(
        Material(child: MealLogCard(
            entry: entry(status: MealEntryStatus.pending), onTap: () {})),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang lưu…'), findsOneWidget);
      expect(find.byType(ConfidenceBadge), findsNothing);
    });

    testWidgets('failed → "Lưu thất bại" + Retry/Delete khi có callback',
        (tester) async {
      await tester.pumpAppWidget(
        Material(child: MealLogCard(
            entry: entry(status: MealEntryStatus.failed),
            onTap: () {},
            onRetry: () {},
            onDelete: () {})),
      );
      expect(find.text('Lưu thất bại'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.text('Xoá'), findsOneWidget);
    });

    testWidgets('saved + needsReview → tappable gọi onTap', (tester) async {
      var tapped = false;
      await tester.pumpAppWidget(
        Material(child: MealLogCard(
            entry: entry(caloriesKcal: null, requiresConfirmation: true),
            onTap: () => tapped = true)),
      );
      await tester.tap(find.byType(MealLogCard));
      expect(tapped, isTrue);
    });

    testWidgets('saved + confident → KHÔNG tappable', (tester) async {
      var tapped = false;
      await tester.pumpAppWidget(
        Material(child: MealLogCard(
            entry: entry(caloriesKcal: 480),
            onTap: () => tapped = true)),
      );
      await tester.tap(find.byType(MealLogCard));
      expect(tapped, isFalse);
    });
  });

  group('CalorieConfirmSheet', () {
    testWidgets('no-estimate branch: field rỗng, nút Xác nhận chưa enable',
        (tester) async {
      final store = _MockStore();
      when(() => store.confirmStatus).thenReturn(FormStatus.idle);
      when(() => store.confirmError).thenReturn(null);
      await tester.pumpAppWidget(
          CalorieConfirmSheet(
              entry: entry(id: 'x1'), store: store));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('low-confidence branch: pre-fill, có "Chấp nhận như AI ước tính"',
        (tester) async {
      final store = _MockStore();
      when(() => store.confirmStatus).thenReturn(FormStatus.idle);
      when(() => store.confirmError).thenReturn(null);
      await tester.pumpAppWidget(
          CalorieConfirmSheet(
              entry: entry(caloriesKcal: 380, requiresConfirmation: true),
              store: store));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, '380');
      expect(find.text('Chấp nhận như AI ước tính'), findsOneWidget);
    });
  });
}