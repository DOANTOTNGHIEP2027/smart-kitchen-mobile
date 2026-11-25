import 'package:dio/dio.dart';

import '../../data/network/api_response.dart';

/// Kết quả của `POST /api/v1/auth/refresh` (schema `RefreshResponse`).
class AuthRefreshResult {
  const AuthRefreshResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;

  /// Giá trị MỚI — token cũ đã bị revoke trong chính call này. Caller BẮT BUỘC
  /// ghi đè token đã lưu.
  final String refreshToken;

  /// TTL của access token, tính bằng giây.
  final int expiresIn;
}

/// Silent refresh lúc cold start (fe-app-shell.md §5).
///
/// Khác với [TokenRefreshInterceptor] — interceptor xử lý refresh *giữa phiên*
/// khi một request bất kỳ nhận 401; use case này chỉ chạy một lần trong
/// `SessionStore.bootstrap()`.
class AuthRefreshUseCase {
  const AuthRefreshUseCase(this._dio);

  static const String path = '/api/v1/auth/refresh';

  final Dio _dio;

  /// Ném [DioException] (đã mang [ApiException] ở `.error`) khi refresh thất bại.
  ///
  /// [options]/[cancelToken] do `RefreshGate` truyền để cắt ngân sách tổng
  /// của vùng găng (inventory-management.md §20.3 Amendment #134 A5.2).
  Future<AuthRefreshResult> call(
    String refreshToken, {
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<dynamic>(
      path,
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
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Refresh response without data',
      );
    }
    return AuthRefreshResult(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresIn: data['expiresIn'] as int? ?? 0,
    );
  }
}
