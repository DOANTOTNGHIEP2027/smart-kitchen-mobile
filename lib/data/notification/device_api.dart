import 'dart:io';

import '../../data/network/dio_client.dart';

/// API đăng ký FCM device token với backend (FE-3 #48).
///
/// Contract: `POST /api/v1/devices/register`
/// Spec: `docs/contracts/openapi/inventory-alert-scheduler.yaml`
/// Backend: `DeviceController.java`
///
/// Idempotent — gọi lại với cùng token chỉ làm mới `last_active_at`.
/// Gọi mỗi khi:
/// - App khởi động và user đã authenticated.
/// - Firebase gọi `onTokenRefresh` — token FCM mới phát hành.
abstract interface class DeviceApi {
  Future<void> registerDevice({required String fcmToken});
}

class DeviceApiImpl implements DeviceApi {
  DeviceApiImpl(this._client);

  final DioClient _client;

  @override
  Future<void> registerDevice({required String fcmToken}) async {
    await _client.dio.post<Map<String, dynamic>>(
      '/api/v1/devices/register',
      data: <String, dynamic>{
        'deviceToken': fcmToken,
        'platform': Platform.isAndroid ? 'ANDROID' : 'IOS',
      },
    );
    // Response 201 với `{registered: true}` — chỉ cần gọi thành công, không
    // cần parse body. Nếu call fail, Dio sẽ throw ApiException qua interceptor.
  }
}
