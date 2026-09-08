import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';

void main() {
  test('two concurrent authenticated 401 responses share one refresh request',
      () async {
    final storage = _FakeTokenStorage(
      accessToken: 'old-access-token',
      refreshToken: 'old-refresh-token',
    );
    var refreshCalls = 0;
    var protectedCalls = 0;
    final client = DioClient.build(
      tokenStorage: storage,
      onAccessTokenRefreshed: (_) async {},
      onRefreshFailure: () async {},
    );
    client.dio.httpClientAdapter = _HandlerAdapter((options) async {
      if (options.path == '/v1/auth/refresh') {
        refreshCalls++;
        expect(options.headers.containsKey('Authorization'), isFalse);
        return _jsonResponse(200, {
          'success': true,
          'data': {
            'access_token': 'new-access-token',
            'refresh_token': 'new-refresh-token',
          },
          'error': null,
          'timestamp': '2026-09-08T00:00:00Z',
        });
      }

      protectedCalls++;
      if (options.headers['Authorization'] == 'Bearer old-access-token') {
        return _jsonResponse(401, {
          'success': false,
          'data': null,
          'error': {'code': 'ERR_AUTH_001', 'message': 'Expired'},
          'timestamp': '2026-09-08T00:00:00Z',
        });
      }
      expect(options.headers['Authorization'], 'Bearer new-access-token');
      return _jsonResponse(200, {
        'success': true,
        'data': {'ok': true},
        'error': null,
        'timestamp': '2026-09-08T00:00:00Z',
      });
    });

    final responses = await Future.wait([
      client.dio.get<Map<String, dynamic>>('/v1/protected'),
      client.dio.get<Map<String, dynamic>>('/v1/protected'),
    ]);

    expect(responses, hasLength(2));
    expect(refreshCalls, 1);
    expect(protectedCalls, 4);
    expect(storage.accessToken, 'new-access-token');
    expect(storage.refreshToken, 'new-refresh-token');
  });
}

class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({this.accessToken, this.refreshToken});

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
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

class _HandlerAdapter implements HttpClientAdapter {
  _HandlerAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);
}

ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': ['application/json']},
  );
}
