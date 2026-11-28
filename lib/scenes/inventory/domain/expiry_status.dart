/// Trạng thái hạn dùng của 1 món trong kho — tính tại máy theo NGÀY, không
/// dựa cờ `isExpiringSoon` của server (cờ đó không có "đã hết hạn" và không tự
/// đổi khi qua ngày).
enum ExpiryStatus { expired, today, soon, none }

/// Số ngày tối đa (tính cả) còn coi là "sắp hết hạn" — cùng ngưỡng 3 ngày cũ.
const int kExpirySoonDays = 3;

/// So sánh chỉ phần ngày: [expiryDate] lấy y/m/d như server gửi (mapper parse
/// `yyyy-MM-ddT00:00:00Z`, đổi múi giờ sẽ lệch ngày), [now] lấy ngày local.
ExpiryStatus expiryStatusOf(DateTime? expiryDate, DateTime now) {
  if (expiryDate == null) return ExpiryStatus.none;
  final expiry = DateTime.utc(expiryDate.year, expiryDate.month, expiryDate.day);
  final today = DateTime.utc(now.year, now.month, now.day);
  final days = expiry.difference(today).inDays;
  if (days < 0) return ExpiryStatus.expired;
  if (days == 0) return ExpiryStatus.today;
  if (days <= kExpirySoonDays) return ExpiryStatus.soon;
  return ExpiryStatus.none;
}
