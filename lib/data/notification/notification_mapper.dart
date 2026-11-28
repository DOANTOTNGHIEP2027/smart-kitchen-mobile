import 'app_notification.dart';
import 'notification_routing.dart';

/// 1 trang hộp thư (`PagedResponse` của BE).
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<AppNotification> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  /// Còn trang sau không (trang đánh số từ 0).
  bool get hasMore => page + 1 < totalPages;
}

/// `NotificationResponse` → [AppNotification] (`fromServer: true`).
///
/// `data` của BE là `{string: string}`; giá trị lạ (số, null) đổi về chuỗi để
/// không làm hỏng cả trang. Đích điều hướng tính từ `type` top-level (ưu tiên
/// hơn `data.type`) qua allow-list [resolveNotificationTarget].
AppNotification notificationFromJson(Map<String, dynamic> json) {
  final rawData = json['data'];
  final data = rawData is Map
      ? rawData.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''))
      : <String, String>{};
  final type = json['type']?.toString() ?? data['type'] ?? '';
  final readAt = json['readAt'] as String?;
  return AppNotification(
    id: json['id'] as String,
    type: type,
    target: resolveNotificationTarget(<String, dynamic>{...data, 'type': type}),
    receivedAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    title: _nonEmpty(json['title']),
    body: _nonEmpty(json['body']),
    read: json['read'] as bool? ?? false,
    readAt: readAt == null ? null : DateTime.parse(readAt).toLocal(),
    data: data,
    fromServer: true,
  );
}

NotificationPage notificationPageFromJson(Map<String, dynamic> json) {
  final items = json['items'] as List<dynamic>? ?? <dynamic>[];
  return NotificationPage(
    items: items
        .map((raw) =>
            notificationFromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(),
    page: (json['page'] as num?)?.toInt() ?? 0,
    size: (json['size'] as num?)?.toInt() ?? items.length,
    totalElements: (json['totalElements'] as num?)?.toInt() ?? items.length,
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
  );
}

String? _nonEmpty(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}
