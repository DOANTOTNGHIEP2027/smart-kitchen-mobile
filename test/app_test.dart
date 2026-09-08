import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/app/app.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';

void main() {
  testWidgets('renders the login route seam for an unauthenticated app',
      (tester) async {
    await tester
        .pumpWidget(const SmartKitchenApp(initialRoute: AppRoutes.login));

    expect(find.text('Smart Kitchen'), findsOneWidget);
    expect(find.text('Sign-in screens will be available soon'), findsOneWidget);
  });
}
