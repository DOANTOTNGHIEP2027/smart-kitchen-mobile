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
  ApiError({required this.code, required this.message, this.fieldErrors});

  final String code;
  final String message;
  final Map<String, String>? fieldErrors;

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: json['code'] as String,
        message: json['message'] as String,
        fieldErrors: (json['fieldErrors'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())),
      );
}
