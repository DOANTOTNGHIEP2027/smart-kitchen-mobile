import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../../../utils/dio_exception_x.dart';
import '../domain/meal_plan_candidate.dart';

/// `GET /api/v1/meal-plans/{mealPlanId}/candidates` (#105,
/// `MealPlanCandidateController`). `mealPlanId` = id kế hoạch TUẦN (OD-06/OD-08).
///
/// Không có `generate()` riêng: sinh gợi ý CHÍNH LÀ `POST .../vote/open` —
/// dùng lại `MealPlanStore.openVoteSession` (đã xử lý 409 `ERR_PLAN_002`).
class CandidateApi {
  CandidateApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<List<MealPlanCandidate>> list(String mealPlanId) => _unwrap(() async {
        final res = await _dio.get<Map<String, dynamic>>(
            '/api/v1/meal-plans/$mealPlanId/candidates');
        final envelope = ApiResponse<List<dynamic>>.fromJson(
          res.data ?? const <String, dynamic>{},
          (Object? v) => List<dynamic>.from(v! as List),
        );
        if (!envelope.success || envelope.data == null) {
          throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
        }
        return envelope.data!
            .map((Object? e) => MealPlanCandidate.fromJson(
                Map<String, dynamic>.from(e! as Map)))
            .toList(growable: false);
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
