import 'package:dio/dio.dart';

/// Thu hồi refresh token phía server — phần "nối BE" của luồng đăng xuất.
///
/// Hai endpoint (auth-jwt.yaml):
/// - `POST /api/v1/auth/revoke` — thu hồi đúng refresh token hiện tại (một thiết bị).
/// - `POST /api/v1/auth/revoke-all` — thu hồi mọi refresh token đang active của user
///   (mọi thiết bị), idempotent.
///
/// Cả hai đều cần `Authorization: Bearer <access token>` — KHÔNG nằm trong
/// `DioClient.publicPaths`, nên [AuthHeaderInterceptor] tự gắn token như mọi
/// request protected khác. Ném [DioException] (đã mang ApiException ở `.error`)
/// khi thất bại; caller chịu trách nhiệm best-effort.
class AuthRevokeUseCase {
  const AuthRevokeUseCase(this._dio);

  static const String revokePath = '/api/v1/auth/revoke';
  static const String revokeAllPath = '/api/v1/auth/revoke-all';

  final Dio _dio;

  /// Thu hồi một refresh token cụ thể. BE trả `ApiResponse<Void>` (data null).
  Future<void> revoke(String refreshToken) async {
    await _dio.post<dynamic>(
      revokePath,
      data: <String, dynamic>{'refreshToken': refreshToken},
    );
  }

  /// Thu hồi toàn bộ refresh token của user. Không body.
  Future<void> revokeAll() async {
    await _dio.post<dynamic>(revokeAllPath);
  }
}
