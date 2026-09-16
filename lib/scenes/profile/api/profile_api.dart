import 'package:dio/dio.dart';

import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../../../domain/auth/user_summary.dart';

/// ⚠️ BLOCKED — `PUT /api/v1/users/me` CHƯA tồn tại ở BE REVIEWED+FIXED nào
/// (FE-3 Implementation Guard 1). Code đầy đủ để test với mock, nhưng UI phải
/// giữ form blocked tới khi issue BE mới ship endpoint này.
abstract interface class ProfileApi {
  Future<UserSummary> updateMe({required String fullName, String? avatarUrl});
}

class ProfileApiImpl implements ProfileApi {
  ProfileApiImpl(this._client);

  final DioClient _client;

  @override
  Future<UserSummary> updateMe({
    required String fullName,
    String? avatarUrl,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/v1/users/me',
      data: <String, dynamic>{
        'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    return _unwrap(response, UserSummary.fromJson);
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
