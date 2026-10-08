import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../../cooking/data/meal_log_mapper.dart';
import '../../cooking/domain/meal_log_entry.dart';
import '../domain/week_quick_stat.dart';

/// Fetch log dinh dưỡng theo khoảng + stat "7 ngày gần nhất" cho
/// `HistoryStore` (nutrition-trend-history.md §6).
class HistoryApi {
  HistoryApi(this._client);

  final DioClient _client;

  /// Safety cap ~2000 log/tháng — cùng pattern `maxPages` của
  /// `inventory-management.md` §7 (Q5), lớn hơn vì là dữ liệu 1 tháng.
  static const _maxPages = 20;

  Dio get _dio => _client.dio;

  /// Gộp TOÀN BỘ log trong [from, to] (inclusive) của [memberId] — tự lặp phân
  /// trang nội bộ, ẩn khỏi UI/Store. Tái dùng `MealLogMapper.fromJson` (#82) —
  /// KHÔNG viết lại coercion logic (Guard §12.1).
  Future<List<MealLogEntry>> listAllLogsInRange({
    required String memberId,
    required DateTime from,
    required DateTime to,
  }) {
    return _unwrap(() async {
      final all = <MealLogEntry>[];
      var page = 0;
      while (page < _maxPages) {
        final res = await _dio.get<Map<String, dynamic>>(
          '/api/v1/cooking/logs',
          queryParameters: <String, dynamic>{
            'memberId': memberId,
            'from': _isoDate(from),
            'to': _isoDate(to),
            'page': page,
            'size': 100,
          },
        );
        final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const <String, dynamic>{},
          (Object? v) => Map<String, dynamic>.from(v! as Map),
        );
        final data = envelope.data ?? const <String, dynamic>{};
        all.addAll((data['items'] as List? ?? const <Object?>[])
            .map((e) => MealLogMapper.fromJson(
                  e as Map<String, dynamic>,
                  status: MealEntryStatus.saved,
                )));
        final totalPages = data['totalPages'] as int? ?? 1;
        if (page + 1 >= totalPages) break;
        page++;
      }
      return all;
    });
  }

  /// Stat phụ "7 ngày gần nhất" — GỌI ĐÚNG `GET /cooking/nutrition/weekly`.
  /// BE trả DANH SÁCH TOÀN HOUSEHOLD, không có tham số filter member — FE tự
  /// lọc theo [memberId] phía client (Guard §12.9). `mine == null` khi self
  /// chưa log gì trong 7 ngày qua (list-omission).
  Future<WeekQuickStat> getSelfWeekQuickStat(String memberId) {
    return _unwrap(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/cooking/nutrition/weekly',
      );
      final envelope = ApiResponse<List<dynamic>>.fromJson(
        res.data ?? const <String, dynamic>{},
        (Object? v) => (v as List).cast<dynamic>(),
      );
      final list = envelope.data ?? const <dynamic>[];
      // Guard §12.9 + #11: coerce qua num; `firstOrNull` khi không có member.
      final mine = list
          .map((r) => Map<String, dynamic>.from(r as Map))
          .where((r) => r['memberId'] == memberId)
          .firstOrNull;
      if (mine == null) return const WeekQuickStat();
      return WeekQuickStat(
        avgCaloriesKcal: (mine['avgCaloriesKcal'] as num?)?.toDouble(),
        loggedCount: (mine['loggedCount'] as num?)?.toInt(),
      );
    });
  }

  /// Pattern `_unwrap` bắt buộc (Fix CRITICAL-1): convert `DioException` →
  /// `ApiException` BÊN TRONG API layer.
  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }

  static String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}