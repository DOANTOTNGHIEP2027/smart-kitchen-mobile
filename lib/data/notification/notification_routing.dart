import 'dart:developer' as developer;

/// Màn đích khi tap thông báo (fcm-notification-flow.md §5).
///
/// Allow-list compile-time: KHÔNG bao giờ `Get.toNamed` chuỗi lấy từ payload
/// (inventory-management.md §20.3(d), Guard 2).
enum NotificationTarget { inventory, mealPlan, shopping, notifications }

const Set<String> _shoppingTypes = <String>{
  'SHOPPING_REMINDER',
  'SHOPPING_ASSIGNED_REMINDER',
};

/// Map `data` FCM → [NotificationTarget]. Thứ tự: `deepLink` → `type` →
/// fallback `/notifications` (log WARN).
NotificationTarget resolveNotificationTarget(Map<String, dynamic> data) {
  final fromLink = targetForDeepLink(data['deepLink']?.toString());
  if (fromLink != null) return fromLink;
  final type = data['type']?.toString() ?? '';
  if (type.startsWith('INVENTORY_')) return NotificationTarget.inventory;
  if (_shoppingTypes.contains(type)) return NotificationTarget.shopping;
  developer.log('Unknown notification type: "$type"', name: 'FCM');
  return NotificationTarget.notifications;
}

/// `smartkitchen://meal-plan` / `smartkitchen://inventory` → target; còn lại
/// `null` (caller tự quyết fallback).
NotificationTarget? targetForDeepLink(String? value) {
  final uri = value == null ? null : Uri.tryParse(value);
  if (uri == null || uri.scheme != 'smartkitchen') return null;
  return switch (uri.host) {
    'meal-plan' => NotificationTarget.mealPlan,
    'inventory' => NotificationTarget.inventory,
    _ => null,
  };
}
