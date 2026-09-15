import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Log request/response — chỉ được gắn khi `EnvConfig.isDev`.
///
/// Không bao giờ log `Authorization` header hay body của `/auth/*`: token là
/// secret, và log của Flutter web đi thẳng ra console trình duyệt.
class LoggingInterceptor extends Interceptor {
  static const String _redacted = '<redacted>';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '→ ${options.method} ${options.uri}',
      name: 'http',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      name: 'http',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isAuthPath = err.requestOptions.path.startsWith('/api/v1/auth/');
    developer.log(
      '✗ ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.uri} — ${isAuthPath ? _redacted : err.message}',
      name: 'http',
    );
    handler.next(err);
  }
}
