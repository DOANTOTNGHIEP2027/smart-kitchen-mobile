import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/main.dart';

void main() {
  testWidgets('renders app shell', (tester) async {
    await tester.pumpWidget(const SmartKitchenApp());

    expect(find.text('Smart Kitchen'), findsOneWidget);
    expect(find.text('Kitchen control center'), findsOneWidget);
  });
}
