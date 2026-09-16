import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/meal_plan_slot.dart';
import 'meal_plan_mapper.dart';

/// 6 endpoint thật của #42 sau amendment multi-dish (FE-7 §6).
///
/// `_unwrap` convert `DioException` → `ApiException` BÊN TRONG (Fix CRITICAL-1,
/// Implementation Guard §15.8). Thiếu bước này → mọi `catch` ở store k matching.
abstract interface class MealPlanApi {
  Future<MealPlanDto> getCurrent();
  Future<MealPlanDto> getById(String id);
  Future<MealPlanDto> create(DateTime weekStart);
  Future<MealPlanDish> addDish(String planId, String slotId);
  Future<void> removeDish(String planId, String slotId, String dishId);
  Future<MealPlanDish> assignDishRecipe(
    String planId,
    String slotId,
    String dishId, {
    required String recipeId,
    required String recipeName,
  });
}

class MealPlanApiImpl implements MealPlanApi {
  MealPlanApiImpl(this._client);

  final DioClient _client;

  @override
  Future<MealPlanDto> getCurrent() {
    return _unwrap(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/v1/meal-plans/current',
      );
      return MealPlanMapper.planFromJson(_data(res.data));
    });
  }

  @override
  Future<MealPlanDto> getById(String id) {
    return _unwrap(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/v1/meal-plans/$id',
      );
      return MealPlanMapper.planFromJson(_data(res.data));
    });
  }

  @override
  Future<MealPlanDto> create(DateTime weekStart) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/meal-plans',
        data: <String, dynamic>{
          'weekStart': _isoDate(weekStart),
        },
      );
      return MealPlanMapper.planFromJson(_data(res.data));
    });
  }

  @override
  Future<MealPlanDish> addDish(String planId, String slotId) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/meal-plans/$planId/slots/$slotId/dishes',
      );
      return MealPlanMapper.dishFromJson(_data(res.data));
    });
  }

  @override
  Future<void> removeDish(String planId, String slotId, String dishId) {
    return _unwrap(() async {
      await _client.dio.delete<Map<String, dynamic>>(
        '/api/v1/meal-plans/$planId/slots/$slotId/dishes/$dishId',
      );
    });
  }

  @override
  Future<MealPlanDish> assignDishRecipe(
    String planId,
    String slotId,
    String dishId, {
    required String recipeId,
    required String recipeName,
  }) {
    return _unwrap(() async {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/api/v1/meal-plans/$planId/slots/$slotId/dishes/$dishId',
        data: <String, dynamic>{
          'recipeId': recipeId,
          'recipeName': recipeName,
        },
      );
      return MealPlanMapper.dishFromJson(_data(res.data));
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

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
