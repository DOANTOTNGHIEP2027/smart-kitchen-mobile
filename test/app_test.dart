import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/app/app.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/domain/auth_models.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('renders all authentication entry actions', (tester) async {
    final session = SessionStore(_MemoryTokenStorage());
    final api = _UnusedAuthApi();
    Get.put<SessionStore>(session);
    Get.put<AuthApi>(api);
    Get.put<AuthStore>(AuthStore(api, session, const UnavailableGoogleAuthGateway()));

    await tester.pumpWidget(const SmartKitchenApp(initialRoute: AppRoutes.login));
    await tester.pumpAndSettle();

    expect(find.text('Smart Kitchen'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(find.text('Register with email'), findsOneWidget);
    expect(find.text('Scan a household QR code'), findsOneWidget);
  });
}

class _MemoryTokenStorage implements TokenStorage {
  @override
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

class _UnusedAuthApi implements AuthApi {
  Never _unused() => throw UnimplementedError();

  @override
  Future<GuestJoinSession> joinAsGuest({required String inviteCode, String? displayName}) async => _unused();
  @override
  Future<AuthSession> login({required String email, required String password}) async => _unused();
  @override
  Future<AuthSession> loginWithGoogle(String idToken) async => _unused();
  @override
  Future<RegisterResult> register({required String email, required String password, required String fullName}) async => _unused();
  @override
  Future<void> sendOtp(String email) async => _unused();
  @override
  Future<UpgradeResult> upgrade({required String email, required String password, String? fullName}) async => _unused();
  @override
  Future<AuthSession> verifyOtp({required String email, required String otp}) async => _unused();
}
