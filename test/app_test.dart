import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_kitchen_mobile/app/app.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/auth/auth_landing_scene.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import 'helpers/fake_http_adapter.dart';
import 'helpers/secure_storage_channel.dart';
import 'helpers/shell_bindings_stub.dart';

/// Smoke test chuỗi splash → redirect theo `SessionStore.status`
/// (fe-app-shell.md §5 và §15 "Routing").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();
  late SessionStore store;

  setUp(() {
    storageChannel.install();
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter(
        (_) async => jsonResponse(200, successEnvelope(null)),
      );
    store = SessionStore(TokenStorage(), AuthRefreshUseCase(dio));
    Get.put<SessionStore>(store, permanent: true);
    Get.put<AuthStore>(
      AuthStore(
        AuthApiImpl(DioClient.build(tokenStorage: TokenStorage())),
        store,
        const UnavailableGoogleAuthGateway(),
      ),
      permanent: true,
    );
    // Stub các binding mà AppShellScene._ensureBindings() cần — tránh
    // Get.find<"AppDatabase"> ném "not found" khi shell render.
    registerShellStubBindings(tokenStorage: TokenStorage());
  });

  tearDown(() {
    storageChannel.uninstall();
    Get.reset();
  });

  testWidgets('unauthenticated → splash redirect sang màn hình login',
      (WidgetTester tester) async {
    await store.clear();

    await tester.pumpWidget(const SmartKitchenApp());
    await tester.pumpAndSettle();

    expect(find.byType(AuthLandingScene), findsOneWidget);
  });

  testWidgets('authenticated → splash redirect vào shell bottom-nav',
      (WidgetTester tester) async {
    await store.setSession(
      accessToken: fakeJwt(<String, dynamic>{'household_id': 'h1'}),
      refreshToken: 'r1',
      user: const UserSummary(id: 'u1'),
    );

    await tester.pumpWidget(const SmartKitchenApp());
    await tester.pumpAndSettle();

    expect(find.byType(AppShellScene), findsOneWidget);
  });
}
