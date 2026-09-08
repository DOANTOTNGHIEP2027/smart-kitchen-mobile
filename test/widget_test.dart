// // This is a basic Flutter widget test.
// //
// // To perform an interaction with a widget in your test, use the WidgetTester
// // utility in the flutter_test package. For example, you can send tap and scroll
// // gestures. You can also use WidgetTester to find child widgets in the widget
// // tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:smart_kitchen_mobile/main.dart';

// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(const MyApp());

//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);

//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();

//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_state_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('AppStateView renders all four common states', (tester) async {
    await tester.pumpWidget(
      host(
        AppStateView<String>(
          state: const LoadingState(),
          onRetry: () {},
          successBuilder: (_, value) => Text(value),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      host(
        AppStateView<String>(
          state: const EmptyState(),
          onRetry: () {},
          successBuilder: (_, value) => Text(value),
          emptyMessage: 'No inventory',
        ),
      ),
    );
    expect(find.text('No inventory'), findsOneWidget);

    await tester.pumpWidget(
      host(
        AppStateView<String>(
          state: const ErrorState(BusinessException('ERR_TEST', 'Retry me')),
          onRetry: () {},
          successBuilder: (_, value) => Text(value),
        ),
      ),
    );
    expect(find.text('Retry me'), findsOneWidget);

    await tester.pumpWidget(
      host(
        AppStateView<String>(
          state: const SuccessState('Ready'),
          onRetry: () {},
          successBuilder: (_, value) => Text(value),
        ),
      ),
    );
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('AppButton disables the action and shows progress while loading',
      (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      host(
        AppButton(
          label: 'Save',
          isLoading: true,
          onPressed: () => presses++,
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    expect(presses, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
