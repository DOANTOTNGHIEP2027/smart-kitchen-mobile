/// Định dạng tiền VND dùng chung TOÀN APP (đặc tả: weekly-recap-screen.md
/// §17.2) — làm tròn về đồng, dấu chấm phân cách nghìn, hậu tố `₫`.
/// Không viết bản thứ hai ở module khác.
String formatVnd(double value) {
  final s = value
      .round()
      .abs()
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  return '${value < 0 ? '-' : ''}$s ₫';
}
