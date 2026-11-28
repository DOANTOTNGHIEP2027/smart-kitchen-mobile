import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/monthly_recap_summary.dart';
import 'monthly_recap_mapper.dart';

/// Endpoint Tổng kết tháng — tách khỏi `RecapApi` để không đụng màn Tổng kết
/// tuần.
class MonthlyRecapApi {
  MonthlyRecapApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  /// `GET /api/v1/insights/monthly?month=yyyy-MM` — [month] `null` = tháng
  /// hiện tại (BE tự chọn). Lỗi nghiệp vụ ném `BusinessException`.
  Future<MonthlyRecapSummary> getMonthlyRecap({DateTime? month}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/insights/monthly',
        queryParameters: month == null
            ? null
            : <String, dynamic>{'month': MonthlyRecapMapper.formatMonth(month)},
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const <String, dynamic>{},
        (Object? v) => Map<String, dynamic>.from(v! as Map),
      );
      return MonthlyRecapMapper.summaryFromJson(envelope.data!);
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
