import 'dart:developer' as developer;

/// Màn đích khi tap thông báo (fcm-notification-flow.md §5).
///
/// Allow-list compile-time: KHÔNG bao giờ `Get.toNamed` chuỗi lấy từ payload
/// (inventory-management.md §20.3(d), Guard 2).
enum NotificationTarget {
  inventory,
  mealPlan,

  /// Mời vote tham gia các bữa ngày mai (batch 20:00) — mở popup vote, không
  /// phải một route; cần `planId` + `targetDate` trong data.
  attendanceInvite,
  shopping,
  household,
  notifications,
}

const Set<String> _shoppingTypes = <String>{
  'SHOPPING_REMINDER',
  'SHOPPING_ASSIGNED_REMINDER',
  'SHOPPING_ASSIGNED',
};

/// Mời vote tham gia bữa ngày mai (batch 20:00). Push cũ (nhắc trước bữa 2h)
/// không có `targetDate` → chỉ mở tab tuần.
const String _attendanceInviteType = 'MEAL_ATTENDANCE_REMINDER';

/// Map `data` FCM → [NotificationTarget]. Thứ tự: `deepLink` → `type` →
/// fallback `/notifications` (log WARN).
NotificationTarget resolveNotificationTarget(Map<String, dynamic> data) {
  final fromLink = targetForDeepLink(data['deepLink']?.toString());
  if (fromLink != null) return fromLink;
  final type = data['type']?.toString() ?? '';
  if (type.startsWith('INVENTORY_')) return NotificationTarget.inventory;
  if (_shoppingTypes.contains(type)) return NotificationTarget.shopping;
  if (type == _attendanceInviteType) {
    return attendanceInviteOf(data) == null
        ? NotificationTarget.mealPlan
        : NotificationTarget.attendanceInvite;
  }
  // JOINED / LEFT / REMOVED / ROLE_CHANGED → màn thành viên gia đình.
  if (type.startsWith('HOUSEHOLD_MEMBER_')) return NotificationTarget.household;
  developer.log('Unknown notification type: "$type"', name: 'FCM');
  return NotificationTarget.notifications;
}

/// Đích của popup vote: plan + ngày của các bữa cần vote.
typedef AttendanceInvite = ({String planId, DateTime date});

/// Đọc `planId` + `targetDate` (yyyy-MM-dd) từ data; thiếu/sai → `null`.
AttendanceInvite? attendanceInviteOf(Map<String, dynamic>? data) {
  final planId = data?['planId']?.toString() ?? '';
  final date = DateTime.tryParse(data?['targetDate']?.toString() ?? '');
  if (planId.isEmpty || date == null) return null;
  return (planId: planId, date: DateTime(date.year, date.month, date.day));
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
