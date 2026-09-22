import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_kitchen_mobile/app/app.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/forgot_password_scene.dart';
import 'package:smart_kitchen_mobile/scenes/auth/reset_password_scene.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

/// Widget test cho luồng đặt lại mật khẩu (design FE-3, design §9):
/// link ở màn đăng nhập và guard thiếu email của màn reset.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();
  late SessionStore session;

  setUp(() {
    storageChannel.install();
    final dio = Dio()
      ..httpClientAdapter = FakeHttpAdapter(
        (_) async => jsonResponse(200, successEnvelope(null)),
      );
    session = SessionStore(TokenStorage(), AuthRefreshUseCase(dio));
    Get.put<SessionStore>(session, permanent: true);
    Get.put<AuthApi>(
      AuthApiImpl(DioClient.build(tokenStorage: TokenStorage())),
      permanent: true,
    );
    Get.put<AuthStore>(
      AuthStore(Get.find<AuthApi>(), session, const UnavailableGoogleAuthGateway()),
      permanent: true,
    );
  });

  tearDown(() {
    storageChannel.uninstall();
    Get.reset();
  });

  testWidgets('link "Quên mật khẩu?" trên màn đăng nhập mở ForgotPasswordScene',
      (WidgetTester tester) async {
    await session.clear();
    await tester.pumpWidget(const SmartKitchenApp());
    await tester.pumpAndSettle();

    Get.toNamed(AppRoutes.emailLogin);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScene), findsOneWidget);
  });

  testWidgets('ResetPasswordScene thiếu email → quay lại ForgotPasswordScene',
      (WidgetTester tester) async {
    await session.clear();
    await tester.pumpWidget(const SmartKitchenApp());
    await tester.pumpAndSettle();

    Get.toNamed(AppRoutes.resetPassword);
    await tester.pumpAndSettle();

    expect(find.byType(ResetPasswordScene), findsNothing);
    expect(find.byType(ForgotPasswordScene), findsOneWidget);
  });
}
