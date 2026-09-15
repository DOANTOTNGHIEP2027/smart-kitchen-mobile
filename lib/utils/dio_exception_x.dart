import 'package:dio/dio.dart';

import '../data/network/api_exception.dart';

/// Đọc [ApiException] đã được [ErrorMappingInterceptor] gắn vào.
///
/// Code của feature bắt `DioException` rồi đọc `.apiException` — không bao giờ
/// tự parse raw JSON (fe-app-shell.md §7.6).
extension DioExceptionX on DioException {
  /// `null` chỉ khi exception chưa đi qua pipeline interceptor (ví dụ bị hủy
  /// trước khi gửi). Mọi lỗi từ [DioClient] đều có giá trị.
  ApiException? get apiException => error is ApiException ? error as ApiException : null;
}
