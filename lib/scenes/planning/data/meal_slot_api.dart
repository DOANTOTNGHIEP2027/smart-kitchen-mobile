import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../../../utils/dio_exception_x.dart';
import '../domain/meal_slot_template_item.dart';

/// `GET`/`PUT /api/v1/households/me/meal-slots` (#101, `MealSlotController`).
class MealSlotApi {
  MealSlotApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<List<MealSlotTemplateItem>> getTemplate() => _unwrap(() async {
        final res = await _dio
            .get<Map<String, dynamic>>('/api/v1/households/me/meal-slots');
        return _parseList(res.data);
      });

  /// Full-replace: luôn gửi TOÀN BỘ draft. `sortOrder` phải đã được resequence
  /// theo nhóm `dayOfWeek` trước khi gọi (`MealSlotStore.save`).
  Future<List<MealSlotTemplateItem>> putTemplate(
          List<MealSlotTemplateItem> slots) =>
      _unwrap(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/api/v1/households/me/meal-slots',
          data: <String, dynamic>{
            'slots': slots.map((MealSlotTemplateItem s) => s.toPutJson()).toList(),
          },
        );
        return _parseList(res.data);
      });

  List<MealSlotTemplateItem> _parseList(Map<String, dynamic>? raw) {
    final envelope = ApiResponse<List<dynamic>>.fromJson(
      raw ?? const <String, dynamic>{},
      (Object? v) => List<dynamic>.from(v! as List),
    );
    if (!envelope.success || envelope.data == null) {
      throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
    }
    return envelope.data!
        .map((Object? e) =>
            MealSlotTemplateItem.fromJson(Map<String, dynamic>.from(e! as Map)))
        .toList(growable: false);
  }

  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.apiException ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
