import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_kitchen_mobile/app/app.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/onboarding/auth_landing_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import 'helpers/fake_http_adapter.dart';
import 'helpers/onboarding_harness.dart';
import 'helpers/secure_storage_channel.dart';

/// Smoke test chuỗi splash → redirect theo `SessionStore.status`
/// (fe-app-shell.md §5 và §15 "Routing").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();
  late OnboardingHarness harness;

  setUp(() {
    storageChannel.install();
    harness = OnboardingHarness(
      FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null))),
    );
    // Singleton toàn app mà `OnboardingBinding` tra cứu qua Get.find.
    Get.put<TokenStorage>(harness.tokenStorage, permanent: true);
    Get.put<DioClient>(harness.dioClient, permanent: true);
    Get.put<SessionStore>(harness.sessionStore, permanent: true);
    // Gateway thật sẽ chạm Firebase khi *dùng*; đăng ký bản giả để binding
    // không tự tạo bản thật.
    Get.put<GoogleAuthGateway>(FakeGoogleAuthGateway(), permanent: true);
  });

  tearDown(() {
    storageChannel.uninstall();
    Get.reset();
  });

  testWidgets('unauthenticated → splash redirect sang màn hình login',
      (WidgetTester tester) async {
    await harness.sessionStore.clear();

    await tester.pumpWidget(const SmartKitchenApp());
    await tester.pumpAndSettle();

    expect(find.byType(AuthLandingScene), findsOneWidget);
  });

  testWidgets('authenticated → splash redirect vào shell bottom-nav',
      (WidgetTester tester) async {
    await harness.sessionStore.setSession(
      accessToken: fakeJwt(<String, dynamic>{'household_id': 'h1'}),
      refreshToken: 'r1',
      user: const UserSummary(id: 'u1'),
    );

    await tester.pumpWidget(const SmartKitchenApp());
    await tester.pumpAndSettle();

    expect(find.byType(AppShellScene), findsOneWidget);
  });
}
