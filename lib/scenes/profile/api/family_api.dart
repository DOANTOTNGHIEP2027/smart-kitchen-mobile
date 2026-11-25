import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../../../domain/shared/budget_period.dart';
import '../domain/household_budget.dart';
import '../domain/household_roster.dart';
import '../domain/household_tier.dart';
import '../domain/invite_result.dart';
import '../domain/profile_mappers.dart';

abstract interface class FamilyApi {
  Future<HouseholdRoster> getMyHousehold();
  Future<InviteResult> createInvite();
  Future<void> removeMember(String userId);

  /// `PATCH /households/members/{userId}/role` — OWNER only, BE trả 204.
  /// `role` CHỈ 'MEMBER' | 'REMOTE_VIEWER' (Guard 3). Vượt ghế → 403
  /// `ERR_TIER_SEAT_LIMIT`.
  Future<void> changeRole(String userId, String role);

  /// `PATCH /households/me/tier` — OWNER only, self-serve demo (KHÔNG billing).
  Future<TierUpdateResult> updateTier(HouseholdTier tier);

  /// `GET /households/me/budget` — mọi thành viên. Chưa đặt → 200 field null.
  Future<HouseholdBudget> getBudget();

  /// `PATCH /households/me/budget` — OWNER only, upsert (KHÔNG có nhánh 404,
  /// Guard #13). KHÔNG gửi `currency` — BE mặc định VND (Guard #15).
  Future<HouseholdBudget> upsertBudget(
      {required BudgetPeriod period, required double amount});
}

/// Mọi phương thức convert [DioException] → [ApiException] BÊN TRONG qua
/// `_unwrap` (Guard 5) — giống `ProfileApiImpl`.
class FamilyApiImpl implements FamilyApi {
  FamilyApiImpl(this._client);

  final DioClient _client;

  @override
  Future<HouseholdRoster> getMyHousehold() => _unwrap(() async {
        final response = await _client.dio
            .get<Map<String, dynamic>>('/api/v1/households/me');
        return HouseholdRosterMapper.fromJson(_data(response));
      });

  @override
  Future<InviteResult> createInvite() => _unwrap(() async {
        final response = await _client.dio
            .post<Map<String, dynamic>>('/api/v1/households/invites');
        return InviteResultMapper.fromJson(_data(response));
      });

  @override
  Future<void> removeMember(String userId) => _unwrap(() async {
        await _client.dio.delete<Map<String, dynamic>>(
          '/api/v1/households/members/$userId',
        );
      });

  @override
  Future<void> changeRole(String userId, String role) {
    assert(role == 'MEMBER' || role == 'REMOTE_VIEWER');
    return _unwrap(() async {
      await _client.dio.patch<void>(
        '/api/v1/households/members/$userId/role',
        data: <String, dynamic>{'role': role},
      );
    });
  }

  @override
  Future<TierUpdateResult> updateTier(HouseholdTier tier) => _unwrap(() async {
        final response = await _client.dio.patch<Map<String, dynamic>>(
          '/api/v1/households/me/tier',
          data: <String, dynamic>{'tier': tier.toWire()},
        );
        return TierUpdateResult.fromJson(_data(response));
      });

  @override
  Future<HouseholdBudget> getBudget() => _unwrap(() async {
        final response = await _client.dio
            .get<Map<String, dynamic>>('/api/v1/households/me/budget');
        return HouseholdBudget.fromJson(_data(response));
      });

  @override
  Future<HouseholdBudget> upsertBudget(
          {required BudgetPeriod period, required double amount}) =>
      _unwrap(() async {
        final response = await _client.dio.patch<Map<String, dynamic>>(
          '/api/v1/households/me/budget',
          data: <String, dynamic>{'period': period.toWire(), 'amount': amount},
        );
        return HouseholdBudget.fromJson(_data(response));
      });
}

Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
  final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
    response.data ?? const <String, dynamic>{},
    (Object? value) => Map<String, dynamic>.from(value! as Map),
  );
  if (!envelope.success || envelope.data == null) {
    throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
  }
  return envelope.data!;
}

/// Đọc [ApiException] mà `ErrorMappingInterceptor` đã gắn vào
/// `DioException.error` rồi ném tiếp đúng kiểu.
Future<T> _unwrap<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    final error = e.error;
    throw error is ApiException
        ? error
        : ServerException('ERR_UNKNOWN', 'Unexpected response');
  }
}
