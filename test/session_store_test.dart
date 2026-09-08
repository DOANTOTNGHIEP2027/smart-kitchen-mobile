import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/interceptors/token_refresh_interceptor.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

void main() {
  test('bootstrap without refresh token becomes unauthenticated', () async {
    final store = SessionStore(_FakeTokenStorage());

    await store.bootstrap();

    expect(store.status, AuthStatus.unauthenticated);
  });

  test('bootstrap refreshes tokens and applies JWT UI claims', () async {
    final storage = _FakeTokenStorage(refreshToken: 'old-refresh');
    final store = SessionStore(storage);
    store.configureRefresh((_) async => TokenPair(
          accessToken: _jwt({
            'household_id': 'household-1',
            'role': 'OWNER',
            'provider': 'EMAIL',
          }),
          refreshToken: 'new-refresh',
        ));

    await store.bootstrap();

    expect(store.status, AuthStatus.authenticated);
    expect(store.householdId, 'household-1');
    expect(store.role, 'OWNER');
    expect(store.provider, 'EMAIL');
    expect(storage.accessToken, isNotNull);
    expect(storage.refreshToken, 'new-refresh');
  });
}

class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this.refreshToken});

  String? refreshToken;
  String? _accessToken;

  @override
  String? get accessToken => _accessToken;

  @override
  Future<void> clear() async {
    _accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

String _jwt(Map<String, dynamic> claims) {
  final payload =
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  return 'header.$payload.signature';
}
