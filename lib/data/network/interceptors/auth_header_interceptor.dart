import 'package:dio/dio.dart';

import '../../auth/token_storage.dart';

class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor(this._tokenStorage, {required this.publicPaths});

  final TokenStorage _tokenStorage;
  final Set<String> publicPaths;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final isPublic = publicPaths.contains(options.path) ||
        (options.method == 'GET' &&
            options.path.startsWith('/v1/households/invites/'));
    final token = _tokenStorage.accessToken;
    if (!isPublic && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
