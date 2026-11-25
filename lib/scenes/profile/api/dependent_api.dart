import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/allergen.dart';
import '../domain/dependent_health_profile.dart';
import '../domain/dependent_summary.dart';

/// `/api/v1/dependents/**` (OAS `dependent-profile-tiering.yaml`,
/// `servers: /api`). 8 method theo §16.2 của dependent-profile-screens.md.
abstract interface class DependentApi {
  Future<List<DependentSummary>> listDependents();
  Future<DependentSummary> getDependent(String id);

  /// `dateOfBirth == null` → OMIT key (POST tạo mới, không có "reset").
  Future<DependentSummary> createDependent({
    required String displayName,
    DateTime? dateOfBirth,
  });
  Future<void> deleteDependent(String id);
  Future<DependentSummary> changeGuardian(String id, String guardianUserId);
  Future<DependentHealthProfile> getHealthProfile(String id);

  /// Full-replace: caller PHẢI gửi đủ 4 key (Guard 6) — `{}` = reset hết.
  Future<DependentHealthProfile> updateHealthProfile(
      String id, Map<String, dynamic> payload);

  /// Full-replace `allergenIds` (Guard 7).
  Future<List<Allergen>> updateAllergens(String id, List<int> allergenIds);
}

/// Mọi method convert [DioException] → [ApiException] BÊN TRONG qua `_unwrap`
/// (Guard 9) — chép đúng pattern `HealthApiImpl`.
class DependentApiImpl implements DependentApi {
  DependentApiImpl(this._client);

  final DioClient _client;

  static const String _base = '/api/v1/dependents';

  @override
  Future<List<DependentSummary>> listDependents() => _unwrap(() async {
        final response = await _client.dio.get<Map<String, dynamic>>(_base);
        return _list(response)
            .map((Object? e) =>
                DependentSummary.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      });

  @override
  Future<DependentSummary> getDependent(String id) => _unwrap(() async {
        final response =
            await _client.dio.get<Map<String, dynamic>>('$_base/$id');
        return DependentSummary.fromJson(_data(response));
      });

  @override
  Future<DependentSummary> createDependent({
    required String displayName,
    DateTime? dateOfBirth,
  }) =>
      _unwrap(() async {
        final response = await _client.dio.post<Map<String, dynamic>>(
          _base,
          data: <String, dynamic>{
            'displayName': displayName,
            if (dateOfBirth != null) 'dateOfBirth': formatDateOnly(dateOfBirth),
          },
        );
        return DependentSummary.fromCreateResponse(_data(response));
      });

  /// `200 data: null` (`ApiResponseEmpty`) — không parse body.
  @override
  Future<void> deleteDependent(String id) => _unwrap(() async {
        await _client.dio.delete<Map<String, dynamic>>('$_base/$id');
      });

  @override
  Future<DependentSummary> changeGuardian(String id, String guardianUserId) =>
      _unwrap(() async {
        final response = await _client.dio.patch<Map<String, dynamic>>(
          '$_base/$id/guardian',
          data: <String, dynamic>{'guardianUserId': guardianUserId},
        );
        return DependentSummary.fromJson(_data(response));
      });

  @override
  Future<DependentHealthProfile> getHealthProfile(String id) =>
      _unwrap(() async {
        final response = await _client.dio
            .get<Map<String, dynamic>>('$_base/$id/health-profile');
        return DependentHealthProfile.fromJson(_data(response));
      });

  @override
  Future<DependentHealthProfile> updateHealthProfile(
          String id, Map<String, dynamic> payload) =>
      _unwrap(() async {
        final response = await _client.dio.put<Map<String, dynamic>>(
          '$_base/$id/health-profile',
          data: payload,
        );
        return DependentHealthProfile.fromJson(_data(response));
      });

  @override
  Future<List<Allergen>> updateAllergens(String id, List<int> allergenIds) =>
      _unwrap(() async {
        final response = await _client.dio.put<Map<String, dynamic>>(
          '$_base/$id/allergens',
          data: <String, dynamic>{'allergenIds': allergenIds},
        );
        return _list(response)
            .map((Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      });
}

List<dynamic> _list(Response<Map<String, dynamic>> response) {
  final envelope = ApiResponse<List<dynamic>>.fromJson(
    response.data ?? const <String, dynamic>{},
    (Object? value) => List<dynamic>.from(value! as List),
  );
  if (!envelope.success || envelope.data == null) {
    throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
  }
  return envelope.data!;
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
