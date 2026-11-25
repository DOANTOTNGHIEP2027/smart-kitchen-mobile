import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../../../domain/auth/user_summary.dart';

/// Kết quả `POST /api/v1/files` (`object-storage.yaml` `FileUploadResponse`).
class FileUploadResult {
  const FileUploadResult({required this.key, required this.url});

  final String key;

  /// URL tuyệt đối BE dựng từ host lúc upload. FE lưu NGUYÊN chuỗi này vào
  /// `avatarUrl`, không tự ghép host/key (Q9).
  final String url;

  factory FileUploadResult.fromJson(Map<String, dynamic> json) =>
      FileUploadResult(key: json['key'] as String, url: json['url'] as String);
}

/// Sửa tên/avatar của chính caller (profile-family-screens.md §7, D11).
///
/// Mọi phương thức convert [DioException] → [ApiException] BÊN TRONG qua
/// `_unwrap` (Guard 5) — thiếu bước này mọi `on ApiException catch` ở
/// `ProfileStore` thành code chết.
abstract interface class ProfileApi {
  /// Bước 1 — `POST /api/v1/files`, multipart part `file`. BE trả **201**.
  Future<FileUploadResult> uploadAvatar(Uint8List jpegBytes);

  /// Bước 2 — `PUT /api/v1/users/me`, JSON camelCase. Chỉ gửi key có giá trị
  /// (BE coi `null`/vắng = giữ nguyên — Guard 15).
  Future<UserSummary> updateMe({String? fullName, String? avatarUrl});
}

class ProfileApiImpl implements ProfileApi {
  ProfileApiImpl(this._client);

  final DioClient _client;

  @override
  Future<FileUploadResult> uploadAvatar(Uint8List jpegBytes) =>
      _unwrap(() async {
        final response = await _client.dio.post<Map<String, dynamic>>(
          '/api/v1/files',
          data: FormData.fromMap(<String, dynamic>{
            'file': MultipartFile.fromBytes(jpegBytes, filename: 'avatar.jpg'),
          }),
        );
        return FileUploadResult.fromJson(_data(response));
      });

  @override
  Future<UserSummary> updateMe({String? fullName, String? avatarUrl}) =>
      _unwrap(() async {
        final response = await _client.dio.put<Map<String, dynamic>>(
          '/api/v1/users/me',
          data: <String, dynamic>{
            if (fullName != null) 'fullName': fullName,
            if (avatarUrl != null) 'avatarUrl': avatarUrl,
          },
        );
        return UserSummary.fromJson(_data(response));
      });

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
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
