/// Ngày gửi lên BE dạng `yyyy-MM-dd` theo NGÀY LOCAL (#239 F4).
///
/// Không dùng `toUtc()`: `showDatePicker` và `DateTime.parse('yyyy-MM-dd')`
/// trả nửa đêm giờ local, ở UTC+7 `toUtc()` lùi về ngày hôm trước.
String toApiDate(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
}

/// Parse `yyyy-MM-dd` của BE thành nửa đêm local; null/rỗng/sai → null.
DateTime? parseApiDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
}
