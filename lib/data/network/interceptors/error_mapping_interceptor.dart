import 'package:dio/dio.dart';

import '../api_exception.dart';
import '../api_response.dart';

/// Parse envelope lỗi và map thành [ApiException] có kiểu
/// (fe-app-shell.md §7.6).
///
/// Đến lúc interceptor này thấy một 401, [TokenRefreshInterceptor] đã thử (và
/// thất bại) khôi phục nó — xem §7.3 về thứ tự unwind của Dio và §7.7.
class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (response == null) {
      handler.reject(_wrap(err, NetworkException()));
      return;
    }

    ApiError? apiError;
    try {
      final envelope = ApiResponse<dynamic>.fromJson(
        response.data as Map<String, dynamic>,
        null,
      );
      apiError = envelope.error;
    } catch (_) {
      // Body không có envelope (ví dụ raw proxy 502) — fallback về phân loại
      // chỉ dựa trên status. Không bao giờ crash ở đây.
    }

    final status = response.statusCode ?? 0;
    final ApiException mapped;
    if (status == 401) {
      mapped = AuthExpiredException(
        apiError?.code ?? 'ERR_AUTH_UNKNOWN',
        apiError?.message ?? 'Session expired',
      );
    } else if (apiError?.fieldErrors != null) {
      mapped = ValidationException(
        apiError!.code,
        apiError.message,
        fieldErrors: apiError.fieldErrors!,
      );
    } else if (status >= 500) {
      mapped = ServerException(
        apiError?.code ?? 'ERR_INTERNAL',
        apiError?.message ?? 'Server error',
      );
    } else {
      mapped = BusinessException(
        apiError?.code ?? 'ERR_UNKNOWN',
        apiError?.message ?? 'Request failed',
      );
    }
    handler.reject(_wrap(err, mapped));
  }

  DioException _wrap(DioException original, ApiException mapped) =>
      original.copyWith(error: mapped);
}
