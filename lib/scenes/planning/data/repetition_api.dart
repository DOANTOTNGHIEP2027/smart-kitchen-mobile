import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../../../utils/dio_exception_x.dart';
import '../domain/repetition_summary.dart';

/// `GET /api/v1/households/me/meal-plans/repetition-summary` (#106).
class RepetitionApi {
  RepetitionApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  /// `windowDays` chỉ 7 hoặc 14 — store validate trước khi gọi.
  Future<RepetitionSummary> get({required int windowDays}) => _unwrap(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/api/v1/households/me/meal-plans/repetition-summary',
          queryParameters: <String, dynamic>{'windowDays': windowDays},
        );
        final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const <String, dynamic>{},
          (Object? v) => Map<String, dynamic>.from(v! as Map),
        );
        if (!envelope.success || envelope.data == null) {
          throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
        }
        return RepetitionSummary.fromJson(envelope.data!);
      });

  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.apiException ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
