import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/scenes/auth/api/auth_api.dart';
import 'package:smart_kitchen_mobile/scenes/auth/domain/auth_models.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/form_status.dart';
import 'package:smart_kitchen_mobile/scenes/auth/stores/upgrade_profile_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

/// Chỉ cài `upgrade`; các method khác không được gọi trong store này.
class _FakeAuthApi implements AuthApi {
  int upgradeCalls = 0;
  Map<String, String?>? lastUpgrade;
  Object? upgradeError;
  UpgradeResult result = UpgradeResult(
    accessToken: fakeJwt(<String, dynamic>{
      'sub': 'u1',
      'household_id': 'h1',
      'role': 'MEMBER',
      'provider': 'EMAIL',
    }),
    refreshToken: 'refresh-new',
    requiresOtp: true,
  );

  @override
  Future<UpgradeResult> upgrade({
    required String email,
    required String password,
    String? fullName,
  }) async {
    upgradeCalls++;
    lastUpgrade = <String, String?>{
      'email': email,
      'password': password,
      'fullName': fullName,
    };
    if (upgradeError != null) throw upgradeError!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// #93 §10.3 — UpgradeProfileStore (nâng cấp GUEST → tài khoản email) chưa
/// có test store.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(storage.uninstall);

  late _FakeAuthApi api;
  late SessionStore session;
  late UpgradeProfileStore store;

  setUp(() {
    api = _FakeAuthApi();
    session = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
    );
    store = UpgradeProfileStore(api, session);
  });

  test('form sai → không gọi API, fieldErrors theo từng ô, status idle',
      () async {
    final ok = await store.submit(email: 'bad', password: '123');

    expect(ok, isFalse);
    expect(api.upgradeCalls, 0);
    expect(store.fieldErrors['email'], 'auth_email_invalid');
    expect(store.fieldErrors['password'], 'auth_password_short');
    expect(store.fieldErrors.containsKey('fullName'), isFalse,
        reason: 'họ tên tuỳ chọn với GUEST');
    expect(store.status, FormStatus.idle);
  });

  test('họ tên quá 100 ký tự → lỗi fullName', () async {
    final ok = await store.submit(
      email: 'a@example.com',
      password: 'password1',
      fullName: 'x' * 101,
    );
    expect(ok, isFalse);
    expect(store.fieldErrors['fullName'], 'auth_name_too_long');
  });

  test('thành công → trim email, thay token + claim, success, trả requiresOtp',
      () async {
    final ok = await store.submit(
      email: '  a@example.com ',
      password: 'password1',
      fullName: 'An',
    );

    expect(ok, isTrue);
    expect(api.lastUpgrade, <String, String?>{
      'email': 'a@example.com',
      'password': 'password1',
      'fullName': 'An',
    });
    expect(store.status, FormStatus.success);
    expect(store.error, isNull);
    expect(session.isAuthenticated, isTrue);
    expect(session.householdId, 'h1');
    expect(await TokenStorage().readRefreshToken(), 'refresh-new');
  });

  test('requiresOtp=false → submit trả false nhưng vẫn success', () async {
    api.result = UpgradeResult(
      accessToken: fakeJwt(<String, dynamic>{'sub': 'u1'}),
      refreshToken: 'r',
      requiresOtp: false,
    );
    final ok =
        await store.submit(email: 'a@example.com', password: 'password1');
    expect(ok, isFalse);
    expect(store.status, FormStatus.success);
  });

  test('ERR_AUTH_003 → failure + lỗi email đã tồn tại', () async {
    api.upgradeError = BusinessException('ERR_AUTH_003', 'exists');

    final ok =
        await store.submit(email: 'a@example.com', password: 'password1');

    expect(ok, isFalse);
    expect(store.status, FormStatus.failure);
    expect(store.error?.code, 'ERR_AUTH_003');
    expect(store.fieldErrors['email'], 'auth_email_exists');
  });

  test('lỗi mạng → failure, không gắn lỗi ô; clearFieldError xoá đúng ô',
      () async {
    api.upgradeError = NetworkException();
    final ok =
        await store.submit(email: 'a@example.com', password: 'password1');
    expect(ok, isFalse);
    expect(store.error?.code, 'ERR_NETWORK');
    expect(store.fieldErrors, isEmpty);

    await store.submit(email: 'bad', password: 'password1');
    expect(store.fieldErrors.containsKey('email'), isTrue);
    store.clearFieldError('email');
    expect(store.fieldErrors.containsKey('email'), isFalse);
    store.clearFieldError('missing'); // không có → no-op
  });

  test('đang submitting → lần submit thứ hai bị chặn', () async {
    final first = store.submit(email: 'a@example.com', password: 'password1');
    expect(store.isSubmitting, isTrue);
    final second =
        await store.submit(email: 'a@example.com', password: 'password1');
    expect(second, isFalse);
    await first;
    expect(api.upgradeCalls, 1);
  });
}
