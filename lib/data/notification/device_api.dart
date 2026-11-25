import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

import '../../data/network/api_exception.dart';
import '../../data/network/dio_client.dart';

/// API đăng ký FCM device token với backend (#48).
///
/// Contract: `POST /api/v1/devices/register`
/// Spec: `docs/contracts/openapi/inventory-alert-scheduler.yaml`
/// Backend: `DeviceController.java`
///
/// Idempotent — gọi lại với cùng token chỉ làm mới `last_active_at`.
/// Do `NotificationStore` gọi khi: đã đăng nhập + có quyền + có token (app
/// khởi động, đăng nhập, `onTokenRefresh`, app resumed sau khi được cấp quyền).
abstract interface class DeviceApi {
  Future<void> registerDevice({required String fcmToken});
}

/// `ANDROID` | `IOS` theo contract. Không dùng `dart:io` để không ném trên web
/// (web không bao giờ đăng ký — `PushGateway.isSupported == false`).
String devicePlatformName([TargetPlatform? platform]) =>
    (platform ?? defaultTargetPlatform) == TargetPlatform.iOS
        ? 'IOS'
        : 'ANDROID';

class DeviceApiImpl implements DeviceApi {
  DeviceApiImpl(this._client);

  final DioClient _client;

  @override
  Future<void> registerDevice({required String fcmToken}) => _unwrap(() async {
        await _client.dio.post<Map<String, dynamic>>(
          '/api/v1/devices/register',
          data: <String, dynamic>{
            'deviceToken': fcmToken,
            'platform': devicePlatformName(),
          },
        );
        // Response 201 `{registered: true}` — không cần parse body.
      });

  /// Đổi `DioException` → `ApiException` để store bắt được (AGENTS.md).
  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw error.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
