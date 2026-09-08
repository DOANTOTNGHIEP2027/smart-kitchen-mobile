import 'dart:async';

import 'package:dio/dio.dart';

import '../../auth/token_storage.dart';
import '../api_response.dart';

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(
    this._dio,
    this._tokenStorage, {
    required this.onAccessTokenRefreshed,
    required this.onRefreshFailure,
  });

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final FutureOr<void> Function(String accessToken) onAccessTokenRefreshed;
  final FutureOr<void> Function() onRefreshFailure;
  Completer<bool>? _refreshCompleter;

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh = err.response?.statusCode == 401 &&
        request.headers.containsKey('Authorization') &&
        request.extra['_authRetryAttempted'] != true;
    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    if (!await _refreshOnce()) {
      await _tokenStorage.clear();
      await onRefreshFailure();
      handler.next(err);
      return;
    }

    try {
      request.extra['_authRetryAttempted'] = true;
      request.headers['Authorization'] = 'Bearer ${_tokenStorage.accessToken}';
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshOnce() async {
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null) {
        completer.complete(false);
        return false;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const {},
        (value) => Map<String, dynamic>.from(value! as Map),
      );
      final data = envelope.data;
      final accessToken = data?['access_token'] as String?;
      final nextRefreshToken = data?['refresh_token'] as String?;
      if (!envelope.success || accessToken == null || nextRefreshToken == null) {
        completer.complete(false);
        return false;
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken,
      );
      await onAccessTokenRefreshed(accessToken);
      completer.complete(true);
      return true;
    } on DioException {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}
