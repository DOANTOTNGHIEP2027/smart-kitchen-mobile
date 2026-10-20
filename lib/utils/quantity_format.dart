/// Số lượng hiển thị: số nguyên bỏ phần '.0' (2.0 → "2"), số lẻ giữ nguyên
/// (1.5 → "1.5"). Dùng chung cho danh sách đi chợ, kho và text chia sẻ.
/// Vô cực/NaN (dữ liệu hỏng) → in nguyên văn thay vì để `toInt()` ném lỗi
/// làm vỡ cả màn.
String formatQuantity(double qty) => qty.isFinite && qty == qty.roundToDouble()
    ? qty.toInt().toString()
    : qty.toString();

/// "2 kg"; đơn vị rỗng/null → chỉ số, không khoảng trắng thừa.
String formatQuantityWithUnit(double qty, String? unit) {
  final text = formatQuantity(qty);
  final u = unit?.trim() ?? '';
  return u.isEmpty ? text : '$text $u';
}
