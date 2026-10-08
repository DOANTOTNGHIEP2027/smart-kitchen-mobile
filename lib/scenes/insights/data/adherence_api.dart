import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/streak_summary.dart';

/// Fetch tuân thủ/weekly + streak household (#84) cho tab "Mức Độ Tuân Thủ"
/// (nutrition-trend-history.md §6).
class AdherenceApi {
  AdherenceApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  /// `null` khi BE trả `404 ERR_ADHERENCE_NOT_FOUND` (tuần chưa được batch
  /// tính) — map NGAY tại đây, KHÔNG coi là lỗi trang (Guard §12.6). Bất kỳ
  /// `ApiException` nào khác (network/5xx/403) vẫn propagate thật.
  Future<double?> getWeeklyAdherencePercent(DateTime weekStart) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/insights/adherence',
        queryParameters: <String, dynamic>{
          'weekStart': _isoDate(weekStart),
        },
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const <String, dynamic>{},
        (Object? v) => Map<String, dynamic>.from(v! as Map),
      );
      return (envelope.data!['adherencePercent'] as num).toDouble();
    } on DioException catch (e) {
      final err = e.error as ApiException?;
      if (err is BusinessException && err.code == 'ERR_ADHERENCE_NOT_FOUND') {
        return null;
      }
      throw err ?? ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }

  /// `memberId` (self) CHỈ dùng để BE validate quyền — kết quả LUÔN là streak
  /// của HOUSEHOLD (Decision D1 của adherence-streak.md, Guard §12.7).
  Future<StreakSummary> getStreak(String memberId) {
    return _unwrap(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/insights/streaks',
        queryParameters: <String, dynamic>{'memberId': memberId},
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const <String, dynamic>{},
        (Object? v) => Map<String, dynamic>.from(v! as Map),
      );
      final d = envelope.data!;
      return StreakSummary(
        currentStreak: (d['currentStreak'] as num?)?.toInt() ?? 0,
        bestStreak: (d['bestStreak'] as num?)?.toInt() ?? 0,
        lastComputedWeekStart: d['lastComputedWeekStart'] != null
            ? DateTime.parse(d['lastComputedWeekStart'] as String)
            : null,
      );
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

  static String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}