import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/guest_diner.dart';

/// CRUD `/api/v1/meal-plans/{mealPlanId}/guest-diners` (#101,
/// `GuestDinerController`). `mealPlanId` = id kế hoạch tuần (OD-06).
class GuestDinerApi {
  GuestDinerApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<List<GuestDiner>> list(String mealPlanId) => _unwrap(() async {
        final res = await _dio.get<Map<String, dynamic>>(
            '/api/v1/meal-plans/$mealPlanId/guest-diners');
        final envelope = ApiResponse<List<dynamic>>.fromJson(
          res.data ?? const <String, dynamic>{},
          (Object? v) => List<dynamic>.from(v! as List),
        );
        if (!envelope.success || envelope.data == null) {
          throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
        }
        return envelope.data!
            .map((Object? e) =>
                GuestDiner.fromJson(Map<String, dynamic>.from(e! as Map)))
            .toList(growable: false);
      });

  Future<GuestDiner> add(
    String mealPlanId, {
    String? displayName,
    required List<int> allergenIds,
  }) =>
      _unwrap(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/api/v1/meal-plans/$mealPlanId/guest-diners',
          data: <String, dynamic>{
            'displayName': displayName,
            'allergenIds': allergenIds,
          },
        );
        return GuestDiner.fromJson(_data(res.data));
      });

  /// Full-replace — luôn gửi TOÀN BỘ `allergenIds` hiện tại.
  Future<GuestDiner> updateAllergens(
    String mealPlanId,
    String guestDinerId,
    List<int> allergenIds,
  ) =>
      _unwrap(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/api/v1/meal-plans/$mealPlanId/guest-diners/$guestDinerId/allergens',
          data: <String, dynamic>{'allergenIds': allergenIds},
        );
        return GuestDiner.fromJson(_data(res.data));
      });

  /// BE trả `204 No Content` — không parse body.
  Future<void> remove(String mealPlanId, String guestDinerId) =>
      _unwrap(() async {
        await _dio.delete<void>(
            '/api/v1/meal-plans/$mealPlanId/guest-diners/$guestDinerId');
      });

  Map<String, dynamic> _data(Map<String, dynamic>? raw) {
    final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
      raw ?? const <String, dynamic>{},
      (Object? v) => Map<String, dynamic>.from(v! as Map),
    );
    if (!envelope.success || envelope.data == null) {
      throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
    }
    return envelope.data!;
  }

  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
