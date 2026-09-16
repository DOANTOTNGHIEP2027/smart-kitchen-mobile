import 'package:dio/dio.dart';

import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/household_roster.dart';
import '../domain/invite_result.dart';
import '../domain/profile_mappers.dart';

abstract interface class FamilyApi {
  Future<HouseholdRoster> getMyHousehold();
  Future<InviteResult> createInvite();
  Future<void> removeMember(String userId);
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
