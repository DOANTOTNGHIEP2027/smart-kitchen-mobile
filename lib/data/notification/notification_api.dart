import 'package:dio/dio.dart';

import '../network/api_exception.dart';
import '../network/api_response.dart';
import '../network/dio_client.dart';
import 'app_notification.dart';
import 'notification_mapper.dart';

/// API hộp thư thông báo cá nhân (#201).
///
/// Contract: `GET /api/v1/notifications?page&size` (mới nhất trước),
/// `GET /api/v1/notifications/unread-count`, `POST /{id}/read`,
/// `POST /read-all`. Mọi response bọc envelope `ApiResponse`.
abstract interface class NotificationApi {
  Future<NotificationPage> list({int page = 0, int size = 20});
  Future<int> unreadCount();
  Future<AppNotification> markRead(String id);

  /// Trả số bản ghi đã chuyển sang đã đọc.
  Future<int> markAllRead();
}

class NotificationApiImpl implements NotificationApi {
  NotificationApiImpl(this._client);

  final DioClient _client;

  static const String _base = '/api/v1/notifications';

  @override
  Future<NotificationPage> list({int page = 0, int size = 20}) =>
      _unwrap(() async {
        final response = await _client.dio.get<Map<String, dynamic>>(
          _base,
          queryParameters: <String, dynamic>{'page': page, 'size': size},
        );
        return notificationPageFromJson(_data(response.data));
      });

  @override
  Future<int> unreadCount() => _unwrap(() async {
        final response =
            await _client.dio.get<Map<String, dynamic>>('$_base/unread-count');
        return (_data(response.data)['count'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<AppNotification> markRead(String id) => _unwrap(() async {
        final response =
            await _client.dio.post<Map<String, dynamic>>('$_base/$id/read');
        return notificationFromJson(_data(response.data));
      });

  @override
  Future<int> markAllRead() => _unwrap(() async {
        final response =
            await _client.dio.post<Map<String, dynamic>>('$_base/read-all');
        return (_data(response.data)['updated'] as num?)?.toInt() ?? 0;
      });

  Map<String, dynamic> _data(Map<String, dynamic>? raw) {
    final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        raw ?? const <String, dynamic>{},
        (v) => Map<String, dynamic>.from(v! as Map));
    if (!envelope.success || envelope.data == null) {
      throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
    }
    return envelope.data!;
  }

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
