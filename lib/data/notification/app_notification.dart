import 'dart:convert';

import 'notification_routing.dart';

/// 1 thông báo đã nhận trong phiên (fcm-notification-flow.md §4, §14.2).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.target,
    required this.receivedAt,
    this.title,
    this.body,
    this.read = false,
  });

  /// Chuẩn hoá cho cả 4 đường vào danh sách (foreground, opened, cold start,
  /// tap local). Payload data-only (`CAPABLE_ANDROID`) có title/body trong
  /// `data` thay vì `RemoteMessage.notification`.
  factory AppNotification.fromPush(
    Map<String, dynamic> data, {
    String? title,
    String? body,
    String? messageId,
    DateTime? at,
    bool read = false,
  }) =>
      AppNotification(
        id: notificationKey(data, messageId: messageId),
        type: data['type']?.toString() ?? '',
        target: resolveNotificationTarget(data),
        receivedAt: at ?? DateTime.now(),
        title: title ?? _nonEmpty(data['title']),
        body: body ?? _nonEmpty(data['body']),
        read: read,
      );

  final String id;
  final String type;
  final NotificationTarget target;
  final DateTime receivedAt;
  final String? title;
  final String? body;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        target: target,
        receivedAt: receivedAt,
        title: title,
        body: body,
        read: read ?? this.read,
      );
}

/// Khoá bỏ trùng: `messageId` nếu có, ngược lại hash ổn định của `data`.
String notificationKey(Map<String, dynamic> data, {String? messageId}) {
  if (messageId != null && messageId.isNotEmpty) return messageId;
  final sorted = Map<String, dynamic>.fromEntries(
      data.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  return 'data:${jsonEncode(sorted).hashCode}';
}

String? _nonEmpty(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}
