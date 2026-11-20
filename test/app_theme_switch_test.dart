import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_kitchen_mobile/app/app.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/auth_landing_scene.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/stores/theme_store.dart';

import 'helpers/fake_http_adapter.dart';
import 'helpers/secure_storage_channel.dart';
import 'helpers/shell_bindings_stub.dart';

/// `SmartKitchenApp` nối `ThemeStore` → `themeMode` (design-system.md §6,
/// AC "switch theme không crash app").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();
  late SessionStore session;

  setUp(() async {
    storageChannel.install();
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter(
        (_) async => jsonResponse(200, successEnvelope(null)),
      );
    session = SessionStore(TokenStorage(), AuthRefreshUseCase(dio));
    Get.put<SessionStore>(session, permanent: true);
    Get.put<AuthStore>(
      AuthStore(
        AuthApiImpl(DioClient.build(tokenStorage: TokenStorage())),
        session,
        const UnavailableGoogleAuthGateway(),
      ),
      permanent: true,
    );
    registerShellStubBindings(tokenStorage: TokenStorage());
    await session.clear();
  });

  tearDown(() {
    storageChannel.uninstall();
    Get.reset();
  });

  Brightness currentBrightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(AuthLandingScene))).brightness;

  testWidgets('ThemeStore.toggle → app đổi sang dark rồi về light, không crash',
      (WidgetTester tester) async {
    final themeStore = ThemeStore();
    Get.put<ThemeStore>(themeStore, permanent: true);

    await tester.pumpWidget(const SmartKitchenApp());
    await tester.pumpAndSettle();
    expect(currentBrightness(tester), Brightness.light);

    themeStore.toggle();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(currentBrightness(tester), Brightness.dark);
    expect(find.byType(AuthLandingScene), findsOneWidget,
        reason: 'đổi theme không reset điều hướng');

    themeStore.toggle();
    await tester.pumpAndSettle();
    expect(currentBrightness(tester), Brightness.light);
  });

  testWidgets('chưa đăng ký ThemeStore → app vẫn chạy ở light',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmartKitchenApp());
    await tester.pumpAndSettle();
    expect(currentBrightness(tester), Brightness.light);
  });
}
