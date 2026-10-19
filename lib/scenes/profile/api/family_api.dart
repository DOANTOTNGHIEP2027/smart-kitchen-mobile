import 'package:dio/dio.dart';

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

class FamilyApiImpl implements FamilyApi {
  FamilyApiImpl(this._client);

  final DioClient _client;

  @override
  Future<HouseholdRoster> getMyHousehold() async {
    final response = await _client.dio
        .get<Map<String, dynamic>>('/api/v1/households/me');
    return _unwrap(response, HouseholdRosterMapper.fromJson);
  }

  @override
  Future<InviteResult> createInvite() async {
    final response = await _client.dio
        .post<Map<String, dynamic>>('/api/v1/households/invites');
    return _unwrap(response, InviteResultMapper.fromJson);
  }

  @override
  Future<void> removeMember(String userId) async {
    await _client.dio.delete<Map<String, dynamic>>(
      '/api/v1/households/members/$userId',
    );
  }

  @override
  Future<void> changeRole(String userId, String role) async {
    assert(role == 'MEMBER' || role == 'REMOTE_VIEWER');
    await _client.dio.patch<void>(
      '/api/v1/households/members/$userId/role',
      data: <String, dynamic>{'role': role},
    );
  }

  @override
  Future<TierUpdateResult> updateTier(HouseholdTier tier) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/api/v1/households/me/tier',
      data: <String, dynamic>{'tier': tier.toWire()},
    );
    return _unwrap(response, TierUpdateResult.fromJson);
  }

  @override
  Future<HouseholdBudget> getBudget() async {
    final response = await _client.dio
        .get<Map<String, dynamic>>('/api/v1/households/me/budget');
    return _unwrap(response, HouseholdBudget.fromJson);
  }

  @override
  Future<HouseholdBudget> upsertBudget(
      {required BudgetPeriod period, required double amount}) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/api/v1/households/me/budget',
      data: <String, dynamic>{'period': period.toWire(), 'amount': amount},
    );
    return _unwrap(response, HouseholdBudget.fromJson);
  }
}

T _unwrap<T>(Response<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) mapper) {
  final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
    response.data ?? const <String, dynamic>{},
    (Object? value) => Map<String, dynamic>.from(value! as Map),
  );
  if (!envelope.success || envelope.data == null) {
    throw const FormatException('Invalid successful API response');
  }
  return mapper(envelope.data!);
}
