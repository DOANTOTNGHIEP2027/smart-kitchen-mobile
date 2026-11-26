import 'dart:async';

import 'package:dio/dio.dart';
// GetX cũng export một `FormData` riêng — ẩn đi để không lẫn với của Dio.
import 'package:get/get.dart' hide FormData;

import '../../../domain/auth/auth_refresh_usecase.dart';
import '../../../routing/app_routes.dart';
import '../../../stores/session_store.dart';
import '../../auth/token_storage.dart';
import '../../notification/cross_isolate_lock.dart';
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
    RefreshGate? refreshGate,
  }) : _refreshGate = refreshGate ??
            RefreshGate(lock: InProcessLock(), tokenStorage: _tokenStorage);

  /// Marker trên request gốc, giới hạn đúng một lần refresh-và-retry cho mỗi
  /// request. KHÔNG được xóa — xem §7.5.
  static const String retryFlag = '_authRetryAttempted';

  static const String refreshPath = '/api/v1/auth/refresh';

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Set<String> publicPaths;

  /// Mutex refresh liên isolate (inventory-management.md §20.3 Amendment #134
  /// A5.4). Single-flight in-process [_refreshCompleter] vẫn giữ BÊN NGOÀI.
  final RefreshGate _refreshGate;

  // null khi không có refresh nào đang chạy
  Completer<RefreshOutcome>? _refreshCompleter;

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

    final outcome = await _refreshOnce();
    if (outcome == RefreshOutcome.lockTimeout) {
      // A5.4/V2-6: hết chờ khoá KHÔNG phải hết phiên — không clear, không về
      // login, không để 401 gốc trồi lên (sẽ thành AuthExpiredException).
      // DioException không response ⇒ ErrorMappingInterceptor map thành
      // NetworkException (copy trung tính `networkError`).
      return handler.next(DioException(
        requestOptions: request,
        type: DioExceptionType.unknown,
        error: 'auth refresh lock timeout',
      ));
    }
    if (outcome != RefreshOutcome.refreshed) {
      await _tokenStorage.clear();
      if (Get.isRegistered<SessionStore>()) {
        await Get.find<SessionStore>().clear();
      }
      Get.offAllNamed(AppRoutes.login);
      return handler.next(err); // trồi lên thành AuthExpiredException
    }

    // Retry request gốc đúng một lần, với access token mới.
    if (!_rebuildBodyForRetry(request)) {
      // Không dựng lại được body → thà để 401 trồi lên còn hơn âm thầm gửi
      // một request thiếu dữ liệu.
      return handler.next(err);
    }
    try {
      request.extra[retryFlag] = true;
      request.headers['Authorization'] = 'Bearer ${_tokenStorage.accessToken}';
      final retryResponse = await _dio.fetch<dynamic>(request);
      return handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  /// Chuẩn bị body cho lần gửi lại. Trả `false` nếu không dựng lại được.
  ///
  /// Body multipart chỉ finalize được **một lần**: lần gửi đầu đã tiêu thụ
  /// stream của nó. Gửi lại đúng object cũ sẽ đi kèm body rỗng hoặc ném lỗi
  /// stream — triệu chứng cực khó lần ra vì URL, header, status đều bình
  /// thường. JSON thuần không dính vì `Map` gửi lại được bao nhiêu lần cũng được.
  ///
  /// `FormData.clone()` dựng lại từ danh sách field/file gốc, nên hoạt động
  /// với file tạo từ path hoặc bytes. Nó ném lỗi với `MultipartFile` tạo từ
  /// stream thuần (không tái tạo được nguồn) — trường hợp đó trả `false`.
  ///
  /// Đường này sẽ được dùng thật khi luồng nhập kho bằng ảnh (#56/#58) upload
  /// ảnh và access token hết hạn giữa chừng.
  bool _rebuildBodyForRetry(RequestOptions request) {
    final data = request.data;
    if (data is! FormData) return true;
    try {
      request.data = data.clone();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Single-flight: nếu đã có một refresh đang chạy, await nó thay vì khởi
  /// động refresh thứ hai (rotation của BE là single-use — một lệnh refresh
  /// đồng thời thứ hai sẽ revoke token đang in-flight của caller kia).
  Future<RefreshOutcome> _refreshOnce() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<RefreshOutcome>();
    _refreshCompleter = completer;
    unawaited(_runRefresh(completer));
    return completer.future;
  }

  /// Chạy refresh rồi hoàn tất [completer] — **mọi đường thoát đều phải
  /// complete nó và reset `_refreshCompleter`**.
  ///
  /// `_doRefresh()` hiện đã nuốt mọi lỗi và trả `failed`, nhưng không có gì ép
  /// buộc điều đó về sau. Nếu một thay đổi sau này để lọt exception ra ngoài
  /// mà thiếu `try/finally` ở đây, `_refreshCompleter` sẽ kẹt non-null vĩnh
  /// viễn và mọi 401 tiếp theo await một future không bao giờ resolve — treo
  /// toàn bộ request đã authenticate, không timeout, không lỗi.
  Future<void> _runRefresh(Completer<RefreshOutcome> completer) async {
    try {
      completer.complete(await _doRefresh());
    } catch (_) {
      completer.complete(RefreshOutcome.failed);
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Đọc RT / ghi cặp mới nằm trong [RefreshGate] (đọc SAU khi giữ khoá, ghi
  /// TRƯỚC khi nhả — Guard 19). Ngân sách tổng 8 s cắt bằng CancelToken.
  Future<RefreshOutcome> _doRefresh() async {
    final result = await _refreshGate.run(
      wait: RefreshGate.mainWait,
      budget: RefreshGate.mainBudget,
      refresh: _postRefresh,
    );
    final tokens = result.tokens;
    // Silent refresh là con đường duy nhất household_id/role/provider có thể
    // đổi giữa phiên, nên SessionStore phải được đồng bộ ở đây (§4, §8.1).
    if (result.outcome == RefreshOutcome.refreshed &&
        tokens != null &&
        Get.isRegistered<SessionStore>()) {
      Get.find<SessionStore>().applyRefreshedClaims(tokens.accessToken);
    }
    return result.outcome;
  }

  Future<AuthRefreshResult> _postRefresh(
    String refreshToken,
    Options options,
    CancelToken cancelToken,
  ) async {
    // Body dùng camelCase theo docs/contracts/naming-convention.md (chốt
    // 23/08/2026) — tài liệu đó thắng đoạn `refresh_token` còn sót trong
    // fe-app-shell.md §7.5.
    final response = await _dio.post<dynamic>(
      refreshPath,
      data: <String, dynamic>{'refreshToken': refreshToken},
      options: options,
      cancelToken: cancelToken,
    );
    final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (j) => j as Map<String, dynamic>,
    );
    final data = envelope.data;
    if (!envelope.success || data == null) {
      throw StateError('Refresh response without data');
    }
    // BẮT BUỘC ghi đè refresh token — token cũ đã bị revoke trong chính call
    // này (RefreshGate ghi trước khi nhả khoá).
    return AuthRefreshResult(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresIn: data['expiresIn'] as int? ?? 0,
    );
  }
}
