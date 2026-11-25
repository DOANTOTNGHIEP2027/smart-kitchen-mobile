import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/domain/auth_models.dart';
import 'package:smart_kitchen_mobile/scenes/auth/email_login_scene.dart';
import 'package:smart_kitchen_mobile/scenes/auth/email_register_scene.dart';
import 'package:smart_kitchen_mobile/scenes/auth/forgot_password_scene.dart';
import 'package:smart_kitchen_mobile/scenes/auth/reset_password_scene.dart';
import 'package:smart_kitchen_mobile/scenes/auth/upgrade_profile_scene.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/scenes/household/api/household_api.dart';
import 'package:smart_kitchen_mobile/scenes/household/create_household_scene.dart';
import 'package:smart_kitchen_mobile/scenes/household/domain/household_models.dart';
import 'package:smart_kitchen_mobile/scenes/household/household_setup_scene.dart';
import 'package:smart_kitchen_mobile/scenes/household/join_household_scene.dart';
import 'package:smart_kitchen_mobile/scenes/household/stores/household_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../helpers/fake_http_adapter.dart';

/// Harness widget test cho onboarding (#28): fake API + SessionStore thật
/// trên storage trong RAM + GetMaterialApp với đúng tên route thật nhưng
/// không guard, để test từng màn độc lập.
class OnboardingHarness {
  OnboardingHarness() {
    session = SessionStore(storage, AuthRefreshUseCase(_refreshDio()));
    authStore = AuthStore(authApi, session, const UnavailableGoogleAuthGateway());
    householdStore = HouseholdStore(householdApi, authApi, session);
    Get.put<SessionStore>(session, permanent: true);
    Get.put<AuthApi>(authApi, permanent: true);
    Get.put<AuthStore>(authStore, permanent: true);
    Get.put<HouseholdStore>(householdStore, permanent: true);
  }

  final FakeAuthApi authApi = FakeAuthApi();
  final FakeHouseholdApi householdApi = FakeHouseholdApi();
  final MemoryTokenStorage storage = MemoryTokenStorage();

  /// Claim mà `/auth/refresh` giả trả về (vd. sau khi tạo/tham gia Nhà).
  Map<String, dynamic> refreshClaims = <String, dynamic>{
    'household_id': 'h1',
    'role': 'OWNER',
    'provider': 'EMAIL',
  };

  late final SessionStore session;
  late final AuthStore authStore;
  late final HouseholdStore householdStore;

  Dio _refreshDio() => Dio()
    ..httpClientAdapter = FakeHttpAdapter(
      (_) async => jsonResponse(
        200,
        successEnvelope(<String, dynamic>{
          'accessToken': fakeJwt(refreshClaims),
          'refreshToken': 'refresh-2',
          'expiresIn': 900,
        }),
      ),
    );

  /// Đăng nhập sẵn với [householdId] (null = chưa có Nhà).
  Future<void> signIn({String? householdId}) => session.setSession(
        accessToken: fakeJwt(<String, dynamic>{
          'household_id': householdId,
          'role': householdId == null ? null : 'MEMBER',
          'provider': 'EMAIL',
        }),
        refreshToken: 'refresh',
        user: const UserSummary(id: 'u1', fullName: 'An', email: 'a@example.com'),
      );

  Future<void> pump(WidgetTester tester, String initialRoute) async {
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: initialRoute,
      getPages: <GetPage<dynamic>>[
        GetPage<void>(name: '/', page: () => const Text('SHELL')),
        GetPage<void>(name: AppRoutes.login, page: () => const Text('LOGIN')),
        GetPage<void>(name: AppRoutes.emailLogin, page: () => const EmailLoginScene()),
        GetPage<void>(name: AppRoutes.register, page: () => const EmailRegisterScene()),
        GetPage<void>(name: AppRoutes.otp, page: () => const Text('OTP')),
        GetPage<void>(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScene()),
        GetPage<void>(name: AppRoutes.resetPassword, page: () => const ResetPasswordScene()),
        GetPage<void>(name: AppRoutes.profileUpgrade, page: () => const UpgradeProfileScene()),
        GetPage<void>(name: AppRoutes.householdSetup, page: () => const HouseholdSetupScene()),
        GetPage<void>(name: AppRoutes.householdCreate, page: () => const CreateHouseholdScene()),
        GetPage<void>(name: AppRoutes.qrJoin, page: () => const JoinHouseholdScene()),
        GetPage<void>(name: AppRoutes.qrJoinCode, page: () => const JoinHouseholdScene()),
      ],
    ));
    await tester.pumpAndSettle();
  }
}

String fakeJwt(Map<String, dynamic> claims) {
  final payload =
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  return 'header.$payload.signature';
}

class FakeAuthApi implements AuthApi {
  ApiException? loginError;
  ApiException? registerError;
  ApiException? upgradeError;
  ApiException? resetError;
  int resetCalls = 0;
  int upgradeCalls = 0;
  int loginCalls = 0;
  int registerCalls = 0;
  int guestJoinCalls = 0;
  String? lastGuestDisplayName;

  AuthSession _session({String? householdId}) => AuthSession(
        accessToken: fakeJwt(<String, dynamic>{
          'household_id': householdId,
          'role': householdId == null ? null : 'MEMBER',
          'provider': 'EMAIL',
        }),
        refreshToken: 'refresh',
        user: const UserSummary(id: 'u1', fullName: 'An', email: 'a@example.com'),
      );

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    return _session();
  }

  @override
  Future<RegisterResult> register({required String email, required String password, required String fullName}) async {
    registerCalls++;
    if (registerError != null) throw registerError!;
    return RegisterResult(email: email, requiresOtp: true);
  }

  @override
  Future<GuestJoinSession> joinAsGuest({required String inviteCode, String? displayName}) async {
    guestJoinCalls++;
    lastGuestDisplayName = displayName;
    return GuestJoinSession(
      session: AuthSession(
        accessToken: fakeJwt(<String, dynamic>{'household_id': 'h2', 'role': 'MEMBER', 'provider': 'GUEST'}),
        refreshToken: 'guest-refresh',
        user: UserSummary(id: 'guest', fullName: displayName ?? 'Thành viên'),
      ),
      requiresProfileCompletion: true,
    );
  }

  @override
  Future<AuthSession> verifyOtp({required String email, required String otp}) async => _session();
  @override
  Future<AuthSession> loginWithGoogle(String idToken) async => _session();
  @override
  Future<void> sendOtp(String email) async {}
  @override
  Future<void> forgotPassword(String email) async {}
  @override
  Future<void> resetPassword({required String email, required String otp, required String newPassword}) async {
    resetCalls++;
    if (resetError != null) throw resetError!;
  }

  @override
  Future<UpgradeResult> upgrade({required String email, required String password, String? fullName}) async {
    upgradeCalls++;
    if (upgradeError != null) throw upgradeError!;
    return const UpgradeResult(accessToken: 'access', refreshToken: 'refresh', requiresOtp: true);
  }
}

class FakeHouseholdApi implements HouseholdApi {
  InvitePreview previewResult = InvitePreview(
    householdName: 'Nhà An',
    ownerName: 'An',
    memberCount: 2,
    expiresAt: DateTime.utc(2026, 12, 31),
    isValid: true,
  );
  ApiException? joinError;
  ApiException? createError;
  ApiException? previewError;

  /// Đặt để giữ response preview của một mã cụ thể (test response về muộn).
  final Map<String, Completer<InvitePreview>> pendingPreviews =
      <String, Completer<InvitePreview>>{};
  final List<String> previewCodes = <String>[];
  int joinCalls = 0;
  int createCalls = 0;

  @override
  Future<HouseholdCreated> create(String name) async {
    createCalls++;
    if (createError != null) throw createError!;
    return HouseholdCreated(id: 'h1', name: name, inviteCode: 'ABC12345');
  }

  @override
  Future<HouseholdJoinResult> join(String code) async {
    joinCalls++;
    if (joinError != null) throw joinError!;
    return const HouseholdJoinResult(
        householdId: 'h1', householdName: 'Nhà An', role: 'MEMBER', requiresTokenRefresh: true);
  }

  @override
  Future<InvitePreview> preview(String code) async {
    previewCodes.add(code);
    if (previewError != null) throw previewError!;
    final pending = pendingPreviews[code];
    if (pending != null) return pending.future;
    return previewResult;
  }
}

class MemoryTokenStorage implements TokenStorage {
  @override
  String? accessToken;
  String? refreshToken;
  Map<String, dynamic>? user;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    user = null;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<Map<String, dynamic>?> readUser() async => user;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> saveUser(Map<String, dynamic> json) async => user = json;
}
