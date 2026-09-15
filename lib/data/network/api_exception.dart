/// Hệ thống exception có kiểu (fe-app-shell.md §7.2, quyết định D4).
///
/// Phân loại theo HTTP status + hình dạng envelope, KHÔNG theo một enum đóng
/// liệt kê từng chuỗi `ERR_*` của BE. Code gốc luôn được giữ nguyên ở [code]
/// để feature tự diễn giải code của module mình.
sealed class ApiException implements Exception {
  ApiException(this.code, this.message, {this.fieldErrors});

  /// Error code gốc từ BE, luôn được giữ nguyên.
  final String code;
  final String message;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => '$runtimeType($code): $message';
}

/// 401 trên một request có mang `Authorization` header, sau khi refresh đã
/// thất bại hoặc chưa từng được thử (§7.4). Ý nghĩa ở cấp shell: "phiên đã hết".
class AuthExpiredException extends ApiException {
  AuthExpiredException(super.code, super.message);
}

/// 400/422 có kèm `fieldErrors`. Ý nghĩa ở cấp shell: "cho form hiển thị các lỗi này".
class ValidationException extends ApiException {
  ValidationException(
    super.code,
    super.message, {
    required Map<String, String> super.fieldErrors,
  });
}

/// Hoàn toàn không có response HTTP — offline, lỗi DNS, timeout connect/receive.
class NetworkException extends ApiException {
  NetworkException() : super('ERR_NETWORK', 'No connection to the server');
}

/// 5xx, hoặc một response parse thất bại thành [ApiResponse].
class ServerException extends ApiException {
  ServerException(super.code, super.message);
}

/// Mọi trường hợp còn lại có envelope hợp lệ: 403/404/409/429/4xx khác chưa
/// được liệt kê ở trên. Code của feature switch theo [code] để xử lý chi tiết.
class BusinessException extends ApiException {
  BusinessException(super.code, super.message);
}
