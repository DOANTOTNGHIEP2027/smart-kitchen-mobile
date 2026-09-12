import 'package:dio/dio.dart';

import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/household_models.dart';

abstract interface class HouseholdApi {
  Future<HouseholdCreated> create(String name);
  Future<InvitePreview> preview(String code);
  Future<HouseholdJoinResult> join(String code);
}

class HouseholdApiImpl implements HouseholdApi {
  HouseholdApiImpl(this._client);

  final DioClient _client;

  @override
  Future<HouseholdCreated> create(String name) async {
    final response = await _client.dio
        .post<Map<String, dynamic>>('/v1/households', data: {'name': name});
    return _unwrap(response, HouseholdCreated.fromJson);
  }

  @override
  Future<InvitePreview> preview(String code) async {
    final response = await _client.dio
        .get<Map<String, dynamic>>('/v1/households/invites/$code');
    return _unwrap(response, InvitePreview.fromJson);
  }

  @override
  Future<HouseholdJoinResult> join(String code) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
        '/v1/households/join',
        data: {'code': code});
    return _unwrap(response, HouseholdJoinResult.fromJson);
  }
}

T _unwrap<T>(Response<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) mapper) {
  final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
    response.data ?? const {},
    (value) => Map<String, dynamic>.from(value! as Map),
  );
  if (!envelope.success || envelope.data == null) {
    throw const FormatException('Invalid successful API response');
  }
  return mapper(envelope.data!);
}
