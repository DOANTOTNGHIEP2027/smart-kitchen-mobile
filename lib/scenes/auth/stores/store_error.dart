import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/dio_exception_x.dart';

ApiException storeApiException(Object error) {
  if (error is DioException) return error.apiException;
  if (error is ApiException) return error;
  return const ServerException('ERR_UNKNOWN', 'Unexpected response');
}
