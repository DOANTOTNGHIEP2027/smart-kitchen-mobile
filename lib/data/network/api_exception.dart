sealed class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.fieldErrors});

  final String code;
  final String message;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => '$runtimeType($code): $message';
}

class AuthExpiredException extends ApiException {
  const AuthExpiredException(super.code, super.message);
}

class ValidationException extends ApiException {
  const ValidationException(
    super.code,
    super.message, {
    required Map<String, String> super.fieldErrors,
  });
}

class NetworkException extends ApiException {
  const NetworkException() : super('ERR_NETWORK', 'No connection to the server');
}

class ServerException extends ApiException {
  const ServerException(super.code, super.message);
}

class BusinessException extends ApiException {
  const BusinessException(super.code, super.message);
}
