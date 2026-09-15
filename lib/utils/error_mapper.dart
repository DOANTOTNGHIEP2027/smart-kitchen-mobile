import 'package:dio/dio.dart';

import '../data/network/api_exception.dart';
import 'dio_exception_x.dart';

/// Quy mọi thứ bị ném ra về đúng một kiểu [ApiException] để store chỉ phải
/// rẽ nhánh theo `.code`.
///
/// Catch trần là có chủ đích: ngoài `DioException`, đường gọi API còn có thể
/// ném `TypeError` từ các cast trong `fromJson` khi BE trả body lệch shape.
/// Nếu để lọt, một `@action` của MobX sẽ ném ra ngoài và làm chết màn hình —
/// cùng loại lỗi với H3 của vòng review FE-1.
ApiException toApiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException) {
    return error.apiException ??
        ServerException('ERR_UNKNOWN', error.message ?? 'Request failed');
  }
  return ServerException('ERR_CLIENT_PARSE', 'Phản hồi không hợp lệ');
}
