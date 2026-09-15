import 'package:dio/dio.dart';

import '../../auth/token_storage.dart';

/// Gắn `Authorization: Bearer <access token>` vào mọi request không-public
/// (fe-app-shell.md §7.4).
///
/// Chỉ implement `onRequest`, nên vị trí của nó trong list interceptor chỉ có
/// ý nghĩa ở phía request — phải đứng đầu tiên.
class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor(this._tokenStorage, {required this.publicPaths});

  /// `GET /api/v1/households/invites/{code}` cũng public nhưng path có
  /// template nên khớp theo prefix, không khớp theo tập hợp.
  static const String invitePathPrefix = '/api/v1/households/invites/';

  final TokenStorage _tokenStorage;
  final Set<String> publicPaths;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isPublic = publicPaths.contains(options.path) ||
        (options.method == 'GET' && options.path.startsWith(invitePathPrefix));

    if (!isPublic) {
      final accessToken = _tokenStorage.accessToken; // in-memory, đọc sync
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }
}
