import 'package:dio/dio.dart';

import '../../app/env_config.dart';
import '../auth/token_storage.dart';
import 'interceptors/auth_header_interceptor.dart';
import 'interceptors/error_mapping_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/token_refresh_interceptor.dart';

class DioClient {
  DioClient._(this.dio);

  final Dio dio;

  static DioClient build({
    required TokenStorage tokenStorage,
    required Future<void> Function(String accessToken) onAccessTokenRefreshed,
    required Future<void> Function() onRefreshFailure,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );
    const publicPaths = <String>{
      '/v1/auth/google',
      '/v1/auth/email/register',
      '/v1/auth/email/send-otp',
      '/v1/auth/email/verify-otp',
      '/v1/auth/email/login',
      '/v1/auth/refresh',
      '/v1/auth/qr-join',
    };
    // Dio 5.11 runs error handlers in FIFO order. Refresh must therefore be
    // registered before error mapping so a recoverable 401 is retried before
    // the caller receives an AuthExpiredException.
    dio.interceptors.addAll([
      AuthHeaderInterceptor(tokenStorage, publicPaths: publicPaths),
      TokenRefreshInterceptor(
        dio,
        tokenStorage,
        onAccessTokenRefreshed: onAccessTokenRefreshed,
        onRefreshFailure: onRefreshFailure,
      ),
      ErrorMappingInterceptor(),
      if (EnvConfig.isDev) LoggingInterceptor(),
    ]);
    return DioClient._(dio);
  }

  Future<TokenPair> refreshTokens(String refreshToken) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'];
    if (body['success'] != true || data is! Map) {
      throw const FormatException('Invalid refresh response');
    }
    final accessToken = data['access_token'] as String?;
    final nextRefreshToken = data['refresh_token'] as String?;
    if (accessToken == null || nextRefreshToken == null) {
      throw const FormatException('Refresh response is missing tokens');
    }
    return TokenPair(accessToken: accessToken, refreshToken: nextRefreshToken);
  }
}
