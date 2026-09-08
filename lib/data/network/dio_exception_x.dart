import 'package:dio/dio.dart';

import 'api_exception.dart';

extension DioExceptionX on DioException {
  ApiException get apiException {
    final error = this.error;
    if (error is ApiException) return error;
    return const ServerException('ERR_UNKNOWN', 'Request failed');
  }
}
