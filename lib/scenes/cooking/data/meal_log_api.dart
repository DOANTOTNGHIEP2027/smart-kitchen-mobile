import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/meal_log_entry.dart';
import 'meal_log_mapper.dart';

/// 3 endpoint thật của meal-log #77 (`POST/GET /cooking/...`).
///
/// `memberId`/`sessionId` KHÔNG BAO GIỜ được gửi từ feature này (Decision
/// D6/D7) — luôn resolve về caller ở BE.
abstract interface class MealLogApi {
  Future<MealLogEntry> logMeal({
    required String description,
    String? imageBase64,
  });

  /// `from`/`to` là date (bid ngày) — đúng convention GET /cooking/logs.
  Future<List<MealLogEntry>> listLogs({
    required DateTime from,
    required DateTime to,
  });

  /// `caloriesKcal == null` => body rỗng (chấp nhận đúng như AI ước tính) —
  /// CHỈ hợp lệ khi entry hiện tại đã có `caloriesKcal` (Guard #10).
  Future<MealLogEntry> confirm({required String id, double? caloriesKcal});
}

class MealLogApiImpl implements MealLogApi {
  MealLogApiImpl(this._client);

  final DioClient _client;

  @override
  Future<MealLogEntry> logMeal({
    required String description,
    String? imageBase64,
  }) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/cooking/log-meal',
        data: <String, dynamic>{
          'description': description,
          if (imageBase64 != null) 'imageBase64': imageBase64,
        },
      );
      return MealLogMapper.fromJson(
        _data(res.data),
        status: MealEntryStatus.saved,
      );
    });
  }

  @override
  Future<List<MealLogEntry>> listLogs({
    required DateTime from,
    required DateTime to,
  }) {
    return _unwrap(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/v1/cooking/logs',
        queryParameters: <String, dynamic>{
          'from': _isoDate(from),
          'to': _isoDate(to),
          'size': 50,
        },
      );
      final envelopeData = _data(res.data);
      final items = envelopeData['items'] as List? ?? const <Object?>[];
      // Chỉ đọc `items` — bỏ qua page/size/totalElements/totalPages (không có
      // UI phân trang trong pass này; `size: 50` đủ cho quy mô 1 ngày).
      return items
          .map((e) => MealLogMapper.fromJson(
                e as Map<String, dynamic>,
                status: MealEntryStatus.saved,
              ))
          .toList(growable: false);
    });
  }

  @override
  Future<MealLogEntry> confirm({required String id, double? caloriesKcal}) {
    return _unwrap(() async {
      final res = await _client.dio.patch<Map<String, dynamic>>(
        '/api/v1/cooking/logs/$id/confirm',
        data: <String, dynamic>{
          if (caloriesKcal != null) 'caloriesKcal': caloriesKcal,
        },
      );
      return MealLogMapper.fromJson(
        _data(res.data),
        status: MealEntryStatus.saved,
      );
    });
  }

  /// Y HỆT pattern `_unwrap` đã REVIEWED (Fix CRITICAL-1): convert
  /// `DioException` → `ApiException` BÊN TRONG API layer, không để Store tự
  /// parse — bỏ bước này vô hiệu hoá mọi `on ApiException catch` ở store.
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

  static String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}