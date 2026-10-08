import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/streak_counter_widget.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('loading → spinner, không hiện nút retry/flame', (tester) async {
    await tester.pumpAppWidget(StreakCounterWidget(
      loading: true,
      error: false,
      onRetry: () {},
      retryLabel: 'retry',
      streakLabel: '4 tuần',
      bestLabel: '9',
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(StreakFlameIcon), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('error → nút retry, gọi onRetry khi bấm', (tester) async {
    var retried = false;
    await tester.pumpAppWidget(StreakCounterWidget(
      loading: false,
      error: true,
      onRetry: () => retried = true,
      retryLabel: 'Thử lại',
      streakLabel: '4 tuần',
      bestLabel: '9',
    ));

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.error_outline));
    expect(retried, isTrue);
  });

  testWidgets('ready → flame + streak + best', (tester) async {
    await tester.pumpAppWidget(StreakCounterWidget(
      loading: false,
      error: false,
      onRetry: () {},
      retryLabel: 'retry',
      streakLabel: '4 tuần',
      bestLabel: '9',
    ));

    expect(find.byType(StreakFlameIcon), findsOneWidget);
    expect(find.text('4 tuần'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });
}