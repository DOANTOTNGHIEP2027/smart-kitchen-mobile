/// Định dạng tiền VND dùng chung TOÀN APP (đặc tả: weekly-recap-screen.md
/// §17.2) — làm tròn về đồng, dấu chấm phân cách nghìn, hậu tố `₫`.
/// Không viết bản thứ hai ở module khác.
String formatVnd(double value) {
  final s = groupThousands(value.round().abs().toString());
  return '${value < 0 ? '-' : ''}$s ₫';
}

/// Chèn dấu chấm phân cách nghìn vào chuỗi CHỈ gồm chữ số (`55000` → `55.000`)
/// — dùng chung cho [formatVnd] và ô nhập tiền.
String groupThousands(String digits) =>
    digits.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
