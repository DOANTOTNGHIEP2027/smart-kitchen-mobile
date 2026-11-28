import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/widgets/calorie_goal_widget.dart';

import '../../helpers/pump_app.dart';

/// R3 mục 13: nhãn dinh dưỡng tiếng Việt, không viết tắt/không tiếng Anh.
void main() {
  final l10n = AppLocalizationsVi();

  test('l10n vi: tên chất dinh dưỡng + dòng macro không viết tắt', () {
    expect(l10n.nutritionProtein, 'Chất đạm');
    expect(l10n.nutritionCarbs, 'Tinh bột');
    expect(l10n.nutritionFat, 'Chất béo');
    expect(l10n.nutritionMacroLine('1', '2', '3'),
        'Đạm 1 g · Tinh bột 2 g · Béo 3 g');
    expect(l10n.nutritionAvgPerDay('1800', 3), startsWith('Trung bình'));
    expect(l10n.insightsAvgCalories(1800), startsWith('Trung bình'));
    expect(l10n.nutritionNoMacroData, 'Chưa có dữ liệu dinh dưỡng');
    expect(l10n.insightsTitleMacro, 'Chất dinh dưỡng');
    expect(l10n.recapTitle, 'Tổng kết tuần');
    expect(l10n.insightsMacroTooltip(1, 2, '3.0', '4.0', '5.0', '12.0'),
        allOf(contains('Tinh bột: 4.0 g'), isNot(contains('Carbs'))));
  });

  for (final width in <double>[320, 360, 400]) {
    testWidgets('chip macro: "Tinh bột", không tràn ở rộng $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpAppWidget(
        const SingleChildScrollView(
          child: CalorieGoalWidget(
            remainingKcal: 500,
            targetKcal: 2000,
            consumedKcal: 1500,
            proteinG: 123.4,
            carbsG: 234.5,
            fatG: 56.7,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tinh bột'), findsOneWidget);
      expect(find.text('Đạm'), findsOneWidget);
      expect(find.text('Béo'), findsOneWidget);
      expect(find.text('Carbs'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
