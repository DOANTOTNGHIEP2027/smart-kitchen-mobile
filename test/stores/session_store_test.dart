import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../helpers/fake_http_adapter.dart';
import '../helpers/secure_storage_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final storageChannel = FakeSecureStorageChannel();
  late TokenStorage tokenStorage;

  setUp(() {
    storageChannel.install();
    tokenStorage = TokenStorage();
  });

  tearDown(storageChannel.uninstall);

  SessionStore buildStore(FakeHttpAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    return SessionStore(tokenStorage, AuthRefreshUseCase(dio));
  }

  test('cold start không có refresh token → unauthenticated, không gọi network',
      () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(200, successEnvelope(null)),
    );
    final store = buildStore(adapter);

    await store.bootstrap();

    expect(store.status, AuthStatus.unauthenticated);
    expect(adapter.requests, isEmpty);
  });

  test('cold start có refresh token hợp lệ → authenticated + điền claim từ JWT',
      () async {
    await tokenStorage.saveTokens('access-old', 'refresh-1');
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(
        200,
        successEnvelope(<String, dynamic>{
          'accessToken': fakeJwt(<String, dynamic>{
            'sub': 'u1',
            'household_id': 'h1',
            'role': 'MEMBER',
            'provider': 'GOOGLE',
          }),
          'refreshToken': 'refresh-2',
          'expiresIn': 900,
        }),
      ),
    );
    final store = buildStore(adapter);

    await store.bootstrap();

    expect(store.status, AuthStatus.authenticated);
    expect(store.householdId, 'h1');
    expect(store.role, 'MEMBER');
    expect(store.provider, 'GOOGLE');
    expect(store.needsHousehold, isFalse);
    expect(await tokenStorage.readRefreshToken(), 'refresh-2');
  });

  test('refresh token đã revoke → clear token, unauthenticated', () async {
    await tokenStorage.saveTokens('access-old', 'refresh-1');
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(
        401,
        errorEnvelope('ERR_AUTH_005', 'Refresh token revoked'),
      ),
    );
    final store = buildStore(adapter);

    await store.bootstrap();

    expect(store.status, AuthStatus.unauthenticated);
    expect(await tokenStorage.readRefreshToken(), isNull);
  });

  // H3 — bootstrap() được await TRƯỚC runApp(); nếu nó throw thì app không bao
  // giờ vẽ frame nào (màn hình trắng). Mọi body lệch shape phải quy về
  // unauthenticated, không được ném ra ngoài.
  group('bootstrap() không bao giờ throw dù body refresh lệch shape', () {
    final malformedBodies = <String, Map<String, dynamic>>{
      'thiếu accessToken': <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'refreshToken': 'r2', 'expiresIn': 900},
        'error': null,
        'timestamp': '2026-09-15T10:00:00Z',
      },
      'accessToken sai kiểu': <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'accessToken': 12345,
          'refreshToken': 'r2',
          'expiresIn': 900,
        },
        'error': null,
        'timestamp': '2026-09-15T10:00:00Z',
      },
      'thiếu timestamp': <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'accessToken': 'a',
          'refreshToken': 'r2',
          'expiresIn': 900,
        },
        'error': null,
      },
      'success null': <String, dynamic>{
        'success': null,
        'data': null,
        'error': null,
        'timestamp': '2026-09-15T10:00:00Z',
      },
    };

    malformedBodies.forEach((String label, Map<String, dynamic> body) {
      test('$label → unauthenticated, không throw', () async {
        await tokenStorage.saveTokens('access-old', 'refresh-1');
        final store = buildStore(
          FakeHttpAdapter((_) async => jsonResponse(200, body)),
        );

        await expectLater(store.bootstrap(), completes);

        expect(store.status, AuthStatus.unauthenticated);
        expect(await tokenStorage.readRefreshToken(), isNull);
      });
    });

    test('body không phải JSON object → unauthenticated, không throw', () async {
      await tokenStorage.saveTokens('access-old', 'refresh-1');
      final store = buildStore(
        FakeHttpAdapter((_) async => ResponseBody.fromString('<html>hi</html>', 200)),
      );

      await expectLater(store.bootstrap(), completes);

      expect(store.status, AuthStatus.unauthenticated);
    });
  });

  test('setSession điền user + claim; clear() xoá sạch', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(200, successEnvelope(null)),
    );
    final store = buildStore(adapter);

    await store.setSession(
      accessToken: fakeJwt(<String, dynamic>{'role': 'OWNER'}),
      refreshToken: 'refresh-1',
      user: const UserSummary(id: 'u1', fullName: 'Phúc'),
    );

    expect(store.isAuthenticated, isTrue);
    expect(store.currentUser?.displayName, 'Phúc');
    expect(store.role, 'OWNER');
    // JWT không có household_id → cần luồng tạo/join Nhà.
    expect(store.needsHousehold, isTrue);

    await store.clear();

    expect(store.status, AuthStatus.unauthenticated);
    expect(store.currentUser, isNull);
    expect(store.role, isNull);
    expect(await tokenStorage.readRefreshToken(), isNull);
  });

  test('applyRefreshedClaims cập nhật householdId sau khi join Nhà', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse(200, successEnvelope(null)),
    );
    final store = buildStore(adapter);
    await store.setSession(
      accessToken: fakeJwt(<String, dynamic>{'role': 'OWNER'}),
      refreshToken: 'refresh-1',
      user: const UserSummary(id: 'u1'),
    );
    expect(store.householdId, isNull);

    store.applyRefreshedClaims(
      fakeJwt(<String, dynamic>{'role': 'OWNER', 'household_id': 'h9'}),
    );

    expect(store.householdId, 'h9');
    expect(store.needsHousehold, isFalse);
  });
}
