/// Envelope response dùng chung của BE.
/// Mirror đúng `docs/knowledge/contract/api-response-envelope.md` — không reshape.
class ApiResponse<T> {
  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.timestamp,
  });

  final bool success;
  final T? data;
  final ApiError? error;
  final DateTime timestamp;

  /// Ném lỗi khi body không đúng hình dạng envelope. Đây là hành vi có chủ
  /// đích: `ErrorMappingInterceptor` bắt lỗi đó và fallback về phân loại chỉ
  /// dựa trên HTTP status (fe-app-shell.md §14).
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ApiError {
  ApiError({
    required this.code,
    required this.message,
    this.fieldErrors,
    this.details,
  });

  final String code;
  final String message;
  final Map<String, String>? fieldErrors;

  /// `error.details` — payload riêng theo mã lỗi (vd.
  /// `ERR_INSUFFICIENT_STOCK_FOR_RECIPE` → `missingIngredients`). Sai kiểu
  /// thì bỏ, không làm hỏng việc parse envelope.
  final Map<String, dynamic>? details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    return ApiError(
      code: json['code'] as String,
      message: json['message'] as String,
      fieldErrors: (json['fieldErrors'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      details: details is Map ? Map<String, dynamic>.from(details) : null,
    );
  }
}
