import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/google_auth_gateway.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/domain/auth_models.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/auth_store.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/form_status.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/otp_store.dart';
import 'package:smart_kitchen_mobile/scenes/household/api/household_api.dart';
import 'package:smart_kitchen_mobile/scenes/household/domain/household_models.dart';
import 'package:smart_kitchen_mobile/scenes/household/stores/household_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import 'helpers/fake_http_adapter.dart';

void main() {
  group('feature 1 mappers', () {
    test('maps nullable user fields and numeric member count defensively', () {
      final session = AuthSession.fromJson({
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'user': {'id': 'user-1', 'email': null, 'fullName': null, 'avatarUrl': null},
      });
      final preview = InvitePreview.fromJson({
        'householdName': 'Nhà An',
        'ownerName': 'An',
        'memberCount': 2.0,
        'expiresAt': '2026-09-13T00:00:00Z',
        'isValid': true,
      });

      expect(session.user.fullName, 'Thành viên');
      expect(session.user.email, isNull);
      expect(preview.memberCount, 2);
    });
  });

  group('AuthStore', () {
    test('client validation prevents register request', () async {
      final api = _FakeAuthApi();
      final store = AuthStore(api, _session(_MemoryTokenStorage()), const UnavailableGoogleAuthGateway());

      final result = await store.register(email: 'bad', password: 'short', fullName: '');

      expect(result, isNull);
      expect(api.registerCalls, 0);
      expect(store.fieldErrors.keys, containsAll(['email', 'password', 'fullName']));
    });

    test('network retry reuses the exact registration payload', () async {
      final api = _FakeAuthApi()..registerFailures = 1;
      final store = AuthStore(api, _session(_MemoryTokenStorage()), const UnavailableGoogleAuthGateway());

      await store.register(email: ' an@example.com ', password: 'password1', fullName: ' An ');
      final email = await store.retryRegister();

      expect(email, 'an@example.com');
      expect(api.registerCalls, 2);
      expect(api.lastRegister, {'email': 'an@example.com', 'password': 'password1', 'fullName': 'An'});
    });

    test('maps bad credentials to one non-enumerating field error', () async {
      final api = _FakeAuthApi()..loginError = AuthExpiredException('ERR_AUTH_004', 'bad');
      final store = AuthStore(api, _session(_MemoryTokenStorage()), const UnavailableGoogleAuthGateway());

      await store.login(email: 'a@example.com', password: 'password1');

      expect(store.fieldErrors['password'], 'auth_bad_credentials');
      expect(store.fieldErrors['email'], isNull);
    });

    test('logout xoá phiên và trả status về idle', () async {
      final storage = _MemoryTokenStorage();
      final session = _session(storage);
      await session.setSession(
        accessToken: _jwt(<String, dynamic>{'provider': 'EMAIL'}),
        refreshToken: 'refresh-1',
        user: const UserSummary(id: 'u1', fullName: 'An'),
      );
      final store = AuthStore(
        _FakeAuthApi(),
        session,
        const UnavailableGoogleAuthGateway(),
      );

      await store.logout();

      expect(session.status, AuthStatus.unauthenticated);
      expect(store.status, FormStatus.idle);
      expect(storage.refreshToken, isNull);
    });
  });

  group('HouseholdStore', () {
    test('normalizes code and maps preview success', () async {
      final authApi = _FakeAuthApi();
      final householdApi = _FakeHouseholdApi();
      final store = HouseholdStore(householdApi, authApi, _session(_MemoryTokenStorage()));

      await store.preview('ab-c 12345');

      expect(householdApi.lastPreviewCode, 'ABC12345');
      expect(store.previewState, isA<SuccessState<InvitePreview>>());
    });

    test('never calls join API when session already has a household', () async {
      final storage = _MemoryTokenStorage();
      final session = _session(storage);
      await session.setSession(
        accessToken: _jwt({'household_id': 'existing', 'role': 'MEMBER', 'provider': 'EMAIL'}),
        refreshToken: 'refresh',
        user: const UserSummary(id: 'u1', fullName: 'An'),
      );
      final authApi = _FakeAuthApi();
      final householdApi = _FakeHouseholdApi();
      final store = HouseholdStore(householdApi, authApi, session);
      await store.preview('ABC12345');

      final joined = await store.join();

      expect(joined, isFalse);
      expect(householdApi.joinCalls, 0);
      expect(authApi.guestJoinCalls, 0);
      expect(store.error?.code, 'CLIENT_ALREADY_IN_HOUSEHOLD');
    });

    test('member join silently refreshes household claims', () async {
      final storage = _MemoryTokenStorage();
      final session = _session(
        storage,
        refreshedAccessToken: _jwt({'household_id': 'new-household', 'role': 'MEMBER', 'provider': 'EMAIL'}),
      );
      await session.setSession(
        accessToken: _jwt({'household_id': null, 'role': null, 'provider': 'EMAIL'}),
        refreshToken: 'refresh-1',
        user: const UserSummary(id: 'u1', fullName: 'An'),
      );
      final store = HouseholdStore(_FakeHouseholdApi(), _FakeAuthApi(), session);
      await store.preview('ABC12345');

      expect(await store.join(), isTrue);
      expect(session.householdId, 'new-household');
      expect(storage.refreshToken, 'refresh-2');
    });

    test('guest join stores issued session without refresh', () async {
      final session = _session(_MemoryTokenStorage());
      final store = HouseholdStore(_FakeHouseholdApi(), _FakeAuthApi(), session);
      await store.preview('ABC12345');

      expect(await store.join(displayName: 'Bình'), isTrue);
      expect(session.status, AuthStatus.authenticated);
      expect(session.provider, 'GUEST');
      expect(session.householdId, 'guest-household');
    });
  });

  test('OTP rejects non-six-digit input without an API request and disposes timer', () async {
    final api = _FakeAuthApi();
    final store = OtpStore(api, _session(_MemoryTokenStorage()), email: 'a@example.com', flow: OtpFlow.register);

    expect(await store.verify('123'), isFalse);
    expect(api.verifyCalls, 0);
    expect(store.error?.code, 'ERR_AUTH_OTP_INVALID');
    store.dispose();
  });
}

class _FakeAuthApi implements AuthApi {
  int registerCalls = 0;
  int registerFailures = 0;
  int guestJoinCalls = 0;
  int verifyCalls = 0;
  Map<String, String>? lastRegister;
  ApiException? loginError;

  @override
  Future<RegisterResult> register({required String email, required String password, required String fullName}) async {
    registerCalls++;
    lastRegister = {'email': email, 'password': password, 'fullName': fullName};
    if (registerFailures-- > 0) throw NetworkException();
    return RegisterResult(email: email, requiresOtp: true);
  }

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    if (loginError != null) throw loginError!;
    return _emailSession();
  }

  @override
  Future<GuestJoinSession> joinAsGuest({required String inviteCode, String? displayName}) async {
    guestJoinCalls++;
    return GuestJoinSession(
      session: AuthSession(
        accessToken: _jwt({'household_id': 'guest-household', 'role': 'MEMBER', 'provider': 'GUEST'}),
        refreshToken: 'guest-refresh',
        user: UserSummary(id: 'guest', fullName: displayName ?? 'Thành viên'),
      ),
      requiresProfileCompletion: true,
    );
  }

  @override
  Future<AuthSession> verifyOtp({required String email, required String otp}) async {
    verifyCalls++;
    return _emailSession();
  }

  AuthSession _emailSession() => AuthSession(
        accessToken: _jwt({'household_id': null, 'role': null, 'provider': 'EMAIL'}),
        refreshToken: 'refresh',
        user: const UserSummary(id: 'u1', fullName: 'An', email: 'a@example.com'),
      );

  @override
  Future<AuthSession> loginWithGoogle(String idToken) async => _emailSession();
  @override
  Future<void> sendOtp(String email) async {}
  @override
  Future<UpgradeResult> upgrade({required String email, required String password, String? fullName}) async => const UpgradeResult(accessToken: 'access', refreshToken: 'refresh', requiresOtp: true);
}

class _FakeHouseholdApi implements HouseholdApi {
  int joinCalls = 0;
  String? lastPreviewCode;

  @override
  Future<HouseholdCreated> create(String name) async => HouseholdCreated(id: 'h1', name: name, inviteCode: 'ABC12345');

  @override
  Future<HouseholdJoinResult> join(String code) async {
    joinCalls++;
    return const HouseholdJoinResult(householdId: 'new-household', householdName: 'Nhà An', role: 'MEMBER', requiresTokenRefresh: true);
  }

  @override
  Future<InvitePreview> preview(String code) async {
    lastPreviewCode = code;
    return InvitePreview(householdName: 'Nhà An', ownerName: 'An', memberCount: 2, expiresAt: DateTime.utc(2026, 9, 13), isValid: true);
  }
}

class _MemoryTokenStorage implements TokenStorage {
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

SessionStore _session(
  _MemoryTokenStorage storage, {
  String? refreshedAccessToken,
}) {
  final dio = Dio()
    ..httpClientAdapter = FakeHttpAdapter(
      (_) async => jsonResponse(
        200,
        successEnvelope(<String, dynamic>{
          'accessToken': refreshedAccessToken ?? _jwt(<String, dynamic>{}),
          'refreshToken': 'refresh-2',
          'expiresIn': 900,
        }),
      ),
    );
  return SessionStore(storage, AuthRefreshUseCase(dio));
}

String _jwt(Map<String, dynamic> claims) {
  final payload = base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  return 'header.$payload.signature';
}
