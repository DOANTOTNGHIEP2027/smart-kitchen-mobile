import 'package:fl_chart/fl_chart.dart';

/// Kỹ thuật gap dùng chung cho cả 2 chart (nutrition-trend-history.md §8.1).
///
/// `fl_chart` không có API "gap" gốc — nếu bỏ qua các điểm `null` khi build
/// `FlSpot`, đường vẫn nối liền 2 điểm 2 bên khoảng trống. Giải pháp: tách dữ
/// liệu thành các đoạn LIÊN TỤC không có `null` ở giữa, mỗi đoạn là 1 series
/// riêng.
///
/// ⚠️ `FlSpot.x` GIỮ NGUYÊN index gốc `i` trong mảng đầy đủ `length` phần tử
/// (KHÔNG renumber theo từng đoạn) — nếu renumber, các đoạn vẽ chồng lên nhau
/// bắt đầu lại từ x=0 (Guard §12.2).
List<List<FlSpot>> buildGapSegments(
  int length,
  double? Function(int index) valueAt,
) {
  final segments = <List<FlSpot>>[];
  var current = <FlSpot>[];
  for (var i = 0; i < length; i++) {
    final v = valueAt(i);
    if (v == null) {
      if (current.isNotEmpty) {
        segments.add(current);
        current = [];
      }
      continue;
    }
    current.add(FlSpot(i.toDouble(), v));
  }
  if (current.isNotEmpty) segments.add(current);
  return segments;
}