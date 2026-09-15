import 'package:dio/dio.dart';

import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/auth_models.dart';

abstract interface class AuthApi {
  Future<AuthSession> loginWithGoogle(String idToken);
  Future<RegisterResult> register({required String email, required String password, required String fullName});
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> verifyOtp({required String email, required String otp});
  Future<void> sendOtp(String email);
  Future<GuestJoinSession> joinAsGuest({required String inviteCode, String? displayName});
  Future<UpgradeResult> upgrade({required String email, required String password, String? fullName});
}

class AuthApiImpl implements AuthApi {
  AuthApiImpl(this._client);

  final DioClient _client;

  @override
  Future<AuthSession> loginWithGoogle(String idToken) => _post(
        '/v1/auth/google',
        {'idToken': idToken},
        AuthSession.fromJson,
      );

  @override
  Future<RegisterResult> register({required String email, required String password, required String fullName}) => _post(
        '/v1/auth/email/register',
        {'email': email, 'password': password, 'fullName': fullName},
        RegisterResult.fromJson,
      );

  @override
  Future<AuthSession> login({required String email, required String password}) => _post(
        '/v1/auth/email/login',
        {'email': email, 'password': password},
        AuthSession.fromJson,
      );

  @override
  Future<AuthSession> verifyOtp({required String email, required String otp}) => _post(
        '/v1/auth/email/verify-otp',
        {'email': email, 'otp': otp},
        AuthSession.fromJson,
      );

  @override
  Future<void> sendOtp(String email) async {
    await _post<Map<String, dynamic>>(
      '/v1/auth/email/send-otp',
      {'email': email},
      (json) => json,
    );
  }

  @override
  Future<GuestJoinSession> joinAsGuest({required String inviteCode, String? displayName}) => _post(
        '/v1/auth/qr-join',
        {
          'inviteCode': inviteCode,
          if (displayName?.trim().isNotEmpty == true) 'displayName': displayName!.trim(),
        },
        GuestJoinSession.fromJson,
      );

  @override
  Future<UpgradeResult> upgrade({required String email, required String password, String? fullName}) => _post(
        '/v1/auth/upgrade-profile',
        {
          'email': email,
          'password': password,
          if (fullName?.trim().isNotEmpty == true) 'fullName': fullName!.trim(),
        },
        UpgradeResult.fromJson,
      );

  Future<T> _post<T>(String path, Map<String, dynamic> body, T Function(Map<String, dynamic>) mapper) async {
    final response = await _client.dio.post<Map<String, dynamic>>(path, data: body);
    return _unwrap(response, mapper);
  }
}

T _unwrap<T>(Response<Map<String, dynamic>> response, T Function(Map<String, dynamic>) mapper) {
  final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
    response.data ?? const {},
    (value) => Map<String, dynamic>.from(value! as Map),
  );
  if (!envelope.success || envelope.data == null) {
    throw const FormatException('Invalid successful API response');
  }
  return mapper(envelope.data!);
}
