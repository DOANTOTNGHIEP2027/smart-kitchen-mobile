import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adapter giả cho Dio — thay tầng transport để test được pipeline
/// interceptor mà không cần network và không cần thêm dependency mock nào.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  /// Mọi request đã đi qua transport, theo thứ tự. Dùng để đếm số lần gọi
  /// `/auth/refresh`.
  final List<RequestOptions> requests = <RequestOptions>[];

  int countPath(String path) =>
      requests.where((RequestOptions r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Body JSON đúng hình dạng envelope của BE.
ResponseBody jsonResponse(int statusCode, Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

Map<String, dynamic> successEnvelope(Object? data) => <String, dynamic>{
      'success': true,
      'data': data,
      'error': null,
      'timestamp': '2026-09-15T10:00:00Z',
    };

Map<String, dynamic> errorEnvelope(
  String code,
  String message, {
  Map<String, String>? fieldErrors,
}) =>
    <String, dynamic>{
      'success': false,
      'data': null,
      'error': <String, dynamic>{
        'code': code,
        'message': message,
        if (fieldErrors != null) 'fieldErrors': fieldErrors,
      },
      'timestamp': '2026-09-15T10:00:00Z',
    };

/// JWT không ký, chỉ có payload đọc được — đủ cho `decodeJwtPayload`.
String fakeJwt(Map<String, dynamic> claims) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  return '${encode(<String, dynamic>{'alg': 'none'})}.${encode(claims)}.sig';
}
