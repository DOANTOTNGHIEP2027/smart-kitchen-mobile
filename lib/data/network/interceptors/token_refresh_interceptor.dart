import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../routing/app_routes.dart';
import '../../../stores/session_store.dart';
import '../../auth/token_storage.dart';
import '../api_response.dart';

/// Thuật toán 401 → refresh → retry (fe-app-shell.md §7.5, quyết định D5).
/// Single-flight, an toàn trước race concurrent-401.
///
/// KHÔNG được đơn giản hóa: xem §7.5 "implementation guard" trước khi sửa
/// bất cứ nhánh nào trong file này.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(
    this._dio,
    this._tokenStorage, {
    required this.publicPaths,
  });

  /// Marker trên request gốc, giới hạn đúng một lần refresh-và-retry cho mỗi
  /// request. KHÔNG được xóa — xem §7.5.
  static const String retryFlag = '_authRetryAttempted';

  static const String refreshPath = '/api/v1/auth/refresh';

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Set<String> publicPaths;

  Completer<bool>? _refreshCompleter; // null khi không có refresh nào đang chạy

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final request = err.requestOptions;
    final hadAuthHeader = request.headers.containsKey('Authorization');
    final alreadyRetried = request.extra[retryFlag] == true;

    // Guard: chỉ 401 trên request mà ta thực sự đã authenticate mới là trigger
    // để refresh. 401 ở endpoint public (ví dụ sai credential trên
    // /email/login) không bao giờ mang Authorization header nên không tới đây.
    if (response?.statusCode != 401 || !hadAuthHeader || alreadyRetried) {
      return handler.next(err); // ErrorMappingInterceptor phân loại (§7.3)
    }

    final refreshed = await _refreshOnce();
    if (!refreshed) {
      await _tokenStorage.clear();
      if (Get.isRegistered<SessionStore>()) {
        await Get.find<SessionStore>().clear();
      }
      Get.offAllNamed(AppRoutes.login);
      return handler.next(err); // trồi lên thành AuthExpiredException
    }

    // Retry request gốc đúng một lần, với access token mới.
    try {
      request.extra[retryFlag] = true;
      request.headers['Authorization'] = 'Bearer ${_tokenStorage.accessToken}';
      final retryResponse = await _dio.fetch<dynamic>(request);
      return handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  /// Single-flight: nếu đã có một refresh đang chạy, await nó thay vì khởi
  /// động refresh thứ hai (rotation của BE là single-use — một lệnh refresh
  /// đồng thời thứ hai sẽ revoke token đang in-flight của caller kia).
  Future<bool> _refreshOnce() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    unawaited(_runRefresh(completer));
    return completer.future;
  }

  /// Chạy refresh rồi hoàn tất [completer] — **mọi đường thoát đều phải
  /// complete nó và reset `_refreshCompleter`**.
  ///
  /// `_doRefresh()` hiện đã nuốt mọi lỗi và trả `false`, nhưng không có gì ép
  /// buộc điều đó về sau. Nếu một thay đổi sau này để lọt exception ra ngoài
  /// mà thiếu `try/finally` ở đây, `_refreshCompleter` sẽ kẹt non-null vĩnh
  /// viễn và mọi 401 tiếp theo await một future không bao giờ resolve — treo
  /// toàn bộ request đã authenticate, không timeout, không lỗi.
  Future<void> _runRefresh(Completer<bool> completer) async {
    try {
      completer.complete(await _doRefresh());
    } catch (_) {
      completer.complete(false);
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _doRefresh() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null) return false;

      // Body dùng camelCase theo docs/contracts/naming-convention.md (chốt
      // 23/08/2026) — tài liệu đó thắng đoạn `refresh_token` còn sót trong
      // fe-app-shell.md §7.5.
      final response = await _dio.post<dynamic>(
        refreshPath,
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (j) => j as Map<String, dynamic>,
      );
      if (!envelope.success || envelope.data == null) return false;

      final newAccessToken = envelope.data!['accessToken'] as String;
      await _tokenStorage.saveTokens(
        newAccessToken,
        // BẮT BUỘC ghi đè — token cũ đã bị revoke trong chính call này.
        envelope.data!['refreshToken'] as String,
      );
      // Silent refresh là con đường duy nhất household_id/role/provider có thể
      // đổi giữa phiên, nên SessionStore phải được đồng bộ ở đây (§4, §8.1).
      if (Get.isRegistered<SessionStore>()) {
        Get.find<SessionStore>().applyRefreshedClaims(newAccessToken);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
