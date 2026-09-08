import 'package:dio/dio.dart';

import '../api_exception.dart';
import '../api_response.dart';

class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response == null) {
      handler.reject(err.copyWith(error: const NetworkException()));
      return;
    }

    ApiError? apiError;
    final body = response.data;
    if (body is Map<String, dynamic>) {
      try {
        apiError = ApiResponse<dynamic>.fromJson(body, null).error;
      } on TypeError {
        apiError = null;
      }
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
    handler.reject(err.copyWith(error: mapped));
  }
}
