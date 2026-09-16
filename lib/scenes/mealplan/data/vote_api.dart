import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/vote_session_summary.dart';

/// 4 endpoint thật của #43 sau amendment multi-dish (FE-7 §6b).
///
/// Path đều có dạng `.../dishes/{dishId}/vote[/...]` (đổi từ slot-scope sang
/// dish-scope). Mọi method dùng `_unwrap` convert `DioException` →
/// `ApiException` (Guard §15.8).
abstract interface class VoteApi {
  /// 201 → session mới (đầy đủ suggestions). 409 `ERR_PLAN_002` → ném
  /// `BusinessException`, caller (`MealPlanStore.openVoteSession`) bắt riêng.
  Future<VoteSessionSummary> open(
    String planId,
    String slotId,
    String dishId, {
    required int deadlineHours,
  });

  /// Trả **raw** `{votes, totalMembers, myVote}` — KHÔNG tự dựng
  /// `VoteSessionSummary`. Caller merge qua `applyVoteResultRaw`.
  Future<Map<String, dynamic>> cast(
    String planId,
    String slotId,
    String dishId, {
    required String recipeId,
  });

  /// Cùng shape với `cast` — trả raw Map cùng lý do.
  Future<Map<String, dynamic>> getResult(
    String planId,
    String slotId,
    String dishId,
  );

  /// Response `{sessionId, status, winnerRecipeId, ...}` — caller không đọc
  /// giá trị trả (winner tới qua WS).
  Future<void> close(
    String planId,
    String slotId,
    String dishId,
  );
}

class VoteApiImpl implements VoteApi {
  VoteApiImpl(this._client);

  final DioClient _client;

  @override
  Future<VoteSessionSummary> open(
    String planId,
    String slotId,
    String dishId, {
    required int deadlineHours,
  }) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/meal-plans/$planId/slots/$slotId/dishes/$dishId/vote/open',
        data: <String, dynamic>{'deadlineHours': deadlineHours},
      );
      final json = _data(res.data);
      return VoteSessionSummary.fromOpenResponse(slotId, dishId, json);
    });
  }

  @override
  Future<Map<String, dynamic>> cast(
    String planId,
    String slotId,
    String dishId, {
    required String recipeId,
  }) {
    return _unwrap(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/meal-plans/$planId/slots/$slotId/dishes/$dishId/vote',
        data: <String, dynamic>{'recipeId': recipeId},
      );
      return _data(res.data);
    });
  }

  @override
  Future<Map<String, dynamic>> getResult(
      String planId, String slotId, String dishId) {
    return _unwrap(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/v1/meal-plans/$planId/slots/$slotId/dishes/$dishId/vote/result',
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const <String, dynamic>{},
        (Object? v) => Map<String, dynamic>.from(v! as Map),
      );
      // `data: null` là response hợp lệ khi dish chưa từng mở vote (OAS).
      // Caller tự phân biệt và dựng empty summary.
      return envelope.data ?? const <String, dynamic>{'votes': <dynamic>[]};
    });
  }

  @override
  Future<void> close(String planId, String slotId, String dishId) {
    return _unwrap(() async {
      await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/meal-plans/$planId/slots/$slotId/dishes/$dishId/vote/close',
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
