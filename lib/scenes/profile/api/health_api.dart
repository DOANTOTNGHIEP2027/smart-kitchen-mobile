import 'package:dio/dio.dart';

import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/allergen.dart';
import '../domain/health_profile.dart';
import '../domain/member_health_summary.dart';
import '../domain/profile_mappers.dart';

/// OAS `health-profile.yaml` để `servers: - url: /api` → endpoint
/// `/api/v1/...`. Sai prefix =Interceptor gắn sai auth-header = hỏng im lặng.
abstract interface class HealthApi {
  Future<HealthProfile> getMyHealthProfile();
  Future<HealthProfile> updateMyHealthProfile(Map<String, dynamic> payload);
  Future<List<Allergen>> getAllergenCatalog();
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds);
  Future<MemberHealthSummary> getMemberHealthSummary(String userId);
}

class HealthApiImpl implements HealthApi {
  HealthApiImpl(this._client);

  final DioClient _client;

  @override
  Future<HealthProfile> getMyHealthProfile() async {
    final response = await _client.dio
        .get<Map<String, dynamic>>('/api/v1/users/me/health-profile');
    return _unwrap(response, HealthProfile.fromJson);
  }

  @override
  Future<HealthProfile> updateMyHealthProfile(
      Map<String, dynamic> payload) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/v1/users/me/health-profile',
      data: payload,
    );
    return _unwrap(response, HealthProfile.fromJson);
  }

  @override
  Future<List<Allergen>> getAllergenCatalog() async {
    final response = await _client.dio
        .get<Map<String, dynamic>>('/api/v1/allergens');
    final envelope = ApiResponse<List<dynamic>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (Object? value) => List<dynamic>.from(value! as List),
    );
    if (!envelope.success || envelope.data == null) {
      throw const FormatException('Invalid successful API response');
    }
    return envelope.data!
        .map((Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/v1/users/me/allergens',
      data: <String, dynamic>{'allergenIds': allergenIds},
    );
    final envelope = ApiResponse<List<dynamic>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (Object? value) => List<dynamic>.from(value! as List),
    );
    if (!envelope.success || envelope.data == null) {
      throw const FormatException('Invalid successful API response');
    }
    return envelope.data!
        .map((Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) async {
    final response = await _client.dio
        .get<Map<String, dynamic>>('/api/v1/users/$userId/health-summary');
    return _unwrap(response, MemberHealthSummaryMapper.fromJson);
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
