class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.timestamp,
    this.data,
    this.error,
  });

  final bool success;
  final T? data;
  final ApiError? error;
  final DateTime timestamp;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value)? fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] == true,
      data: rawData == null
          ? null
          : fromJsonT != null
              ? fromJsonT(rawData)
              : rawData as T,
      error: json['error'] is Map<String, dynamic>
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    this.fieldErrors,
  });

  final String code;
  final String message;
  final Map<String, String>? fieldErrors;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final rawFieldErrors = json['fieldErrors'];
    return ApiError(
      code: json['code'] as String? ?? 'ERR_UNKNOWN',
      message: json['message'] as String? ?? 'Request failed',
      fieldErrors: rawFieldErrors is Map
          ? rawFieldErrors.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : null,
    );
  }
}
