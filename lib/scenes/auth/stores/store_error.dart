import 'package:dio/dio.dart';

import '../../../data/auth/google_auth_gateway.dart';
import '../../../data/network/api_exception.dart';
import '../../../utils/dio_exception_x.dart';

ApiException storeApiException(Object error) {
  if (error is DioException) {
    return error.apiException ??
        ServerException('ERR_UNKNOWN', 'Unexpected response');
  }
  if (error is ApiException) return error;
  if (error is GoogleAuthUnavailableException) {
    return BusinessException(
      'ERR_AUTH_FIREBASE_UNAVAILABLE',
      'Google sign-in is unavailable',
    );
  }
  if (error is GoogleAuthTokenMissingException) {
    return BusinessException(
      'ERR_AUTH_GOOGLE_TOKEN_MISSING',
      'Google sign-in returned no ID token',
    );
  }
  return ServerException('ERR_UNKNOWN', 'Unexpected response');
}
