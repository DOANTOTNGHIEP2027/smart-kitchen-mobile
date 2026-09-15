import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

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

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
