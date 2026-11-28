import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/cooking_session.dart';
import '../domain/cooking_session_result.dart';
import 'cooking_session_mapper.dart';

/// Endpoint vòng đời của cooking-session #76 (FE-6 §7.2 + OAS v1.0.0).
///
/// Đi cùng pattern `_unwrap` của [InventoryApi] (Fix CRITICAL-1, FE-5
/// Implementation Guard 11): convert `DioException` → `ApiException` BÊN
/// TRONG API layer, không để `Store` tự parse.
abstract interface class CookingSessionApi {
  /// [mealPlanDishId] — nấu từ 1 món trong thực đơn: server gắn phiên với món
  /// và trả 409 `ERR_DISH_ALREADY_COOKED` nếu món đã nấu xong.
  Future<CookingSession> start(String recipeId, {String? mealPlanDishId});
  /// Thiếu kho và `allowShortfall == false` → [BusinessException]
  /// `ERR_INSUFFICIENT_STOCK_FOR_RECIPE` (409, kho không đổi — OD-36).
  Future<CookingSessionResult> complete(String sessionId,
      {bool allowShortfall = false});
  Future<CookingSession> abandon(String sessionId);
  Future<CookingSessionResult> getById(String sessionId);
}

class CookingSessionApiImpl implements CookingSessionApi {
  CookingSessionApiImpl(this._client);

  final DioClient _client;

  @override
  Future<CookingSession> start(String recipeId, {String? mealPlanDishId}) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/cooking/sessions',
        data: <String, dynamic>{
          'recipeId': recipeId,
          if (mealPlanDishId != null) 'mealPlanDishId': mealPlanDishId,
        },
      );
      return mapCookingSession(_data(res.data));
    });
  }

  @override
  Future<CookingSessionResult> complete(String sessionId,
      {bool allowShortfall = false}) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/cooking/sessions/$sessionId/complete',
        queryParameters: allowShortfall
            ? const <String, dynamic>{'allowShortfall': true}
            : null,
      );
      return mapCompleteSessionData(_data(res.data));
    });
  }

  @override
  Future<CookingSession> abandon(String sessionId) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/cooking/sessions/$sessionId/abandon',
      );
      return mapCookingSession(_data(res.data));
    });
  }

  @override
  Future<CookingSessionResult> getById(String sessionId) {
    return _unwrap(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/v1/cooking/sessions/$sessionId',
      );
      return mapCompleteSessionData(_data(res.data));
    });
  }

  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }

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
}
