import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/household_streak.dart';
import '../domain/weekly_recap_summary.dart';
import 'recap_mapper.dart';

/// 2 endpoint thật của Weekly Recap (#86) — đọc snapshot đã tính sẵn, FE không
/// tính lại con số nào (weekly-recap-screen.md §6).
class RecapApi {
  RecapApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  /// `GET /api/v1/insights/weekly` — luôn snapshot mới nhất (không truyền
  /// `weekStart` ở pass này, open-questions Q3). `404 ERR_RECAP_NOT_FOUND` ném
  /// ra như `BusinessException` bình thường — Store tự switch theo `.code`.
  Future<WeeklyRecapSummary> getWeeklyRecap() => _unwrap(() async {
        final res = await _dio.get<Map<String, dynamic>>('/api/v1/insights/weekly');
        final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const <String, dynamic>{},
          (Object? v) => Map<String, dynamic>.from(v! as Map),
        );
        return RecapMapper.summaryFromJson(envelope.data!);
      });

  /// `GET /api/v1/insights/streaks?memberId=` — `memberId` BẮT BUỘC (Guard
  /// #11), luôn là `sessionStore.currentUser?.id`. Kết quả LUÔN là streak
  /// household (decision D1 của adherence-streak.md).
  Future<HouseholdStreak> getHouseholdStreak({required String memberId}) =>
      _unwrap(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/api/v1/insights/streaks',
          queryParameters: <String, dynamic>{'memberId': memberId},
        );
        final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const <String, dynamic>{},
          (Object? v) => Map<String, dynamic>.from(v! as Map),
        );
        return RecapMapper.streakFromJson(envelope.data!);
      });

  /// Y hệt pattern `_unwrap` đã REVIEWED xuyên repo (inventory-management.md/
  /// nutrition-summary-widget.md) — `DioException` → `ApiException` BÊN TRONG
  /// (Guard #10). Thiếu bước này, mọi `catch (BusinessException e) when
  /// (e.code == ...)` ở Store không bao giờ match.
  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}