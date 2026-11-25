import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
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

/// Mọi phương thức convert [DioException] → [ApiException] BÊN TRONG qua
/// `_unwrap` (Guard 5) — giống `ProfileApiImpl`.
class HealthApiImpl implements HealthApi {
  HealthApiImpl(this._client);

  final DioClient _client;

  @override
  Future<HealthProfile> getMyHealthProfile() => _unwrap(() async {
        final response = await _client.dio
            .get<Map<String, dynamic>>('/api/v1/users/me/health-profile');
        return HealthProfile.fromJson(_data(response));
      });

  @override
  Future<HealthProfile> updateMyHealthProfile(Map<String, dynamic> payload) =>
      _unwrap(() async {
        final response = await _client.dio.put<Map<String, dynamic>>(
          '/api/v1/users/me/health-profile',
          data: payload,
        );
        return HealthProfile.fromJson(_data(response));
      });

  @override
  Future<List<Allergen>> getAllergenCatalog() => _unwrap(() async {
        final response =
            await _client.dio.get<Map<String, dynamic>>('/api/v1/allergens');
        return _allergenList(response);
      });

  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) =>
      _unwrap(() async {
        final response = await _client.dio.put<Map<String, dynamic>>(
          '/api/v1/users/me/allergens',
          data: <String, dynamic>{'allergenIds': allergenIds},
        );
        return _allergenList(response);
      });

  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) =>
      _unwrap(() async {
        final response = await _client.dio
            .get<Map<String, dynamic>>('/api/v1/users/$userId/health-summary');
        return MemberHealthSummaryMapper.fromJson(_data(response));
      });
}

List<Allergen> _allergenList(Response<Map<String, dynamic>> response) {
  final envelope = ApiResponse<List<dynamic>>.fromJson(
    response.data ?? const <String, dynamic>{},
    (Object? value) => List<dynamic>.from(value! as List),
  );
  if (!envelope.success || envelope.data == null) {
    throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
  }
  return envelope.data!
      .map((Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
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
