/// Tóm tắt frame thuần (chỉ `dart:core`) cho harness đo #93
/// (app-performance-audit §6.8). Ngưỡng tự đếm theo 16 667µs (60Hz) như issue —
/// khác `kBuildBudget` 16ms của SDK (Guard 12).
library;

/// Ngân sách 1 frame ở 60Hz, đơn vị µs.
const int kFrameBudgetMicros60Hz = 16667;

/// Kết quả tóm tắt một lượt thu frame.
class FrameBudgetReport {
  const FrameBudgetReport({
    required this.frameCount,
    required this.jankFrames,
    required this.totalSpanOverBudget,
    required this.worstBuildMs,
    required this.worstRasterMs,
    required this.p90BuildMs,
    required this.p90RasterMs,
    required this.budgetMicros,
  });

  final int frameCount;

  /// Frame có build > budget HOẶC raster > budget (tiêu chí AC).
  final int jankFrames;

  /// Frame có totalSpan > budget — chỉ số tham khảo issue §6 nhắc.
  final int totalSpanOverBudget;

  final double worstBuildMs;
  final double worstRasterMs;
  final double p90BuildMs;
  final double p90RasterMs;
  final int budgetMicros;

  /// Không thu được frame nào → FAIL, không PASS giả.
  bool get pass => frameCount > 0 && jankFrames == 0;

  Map<String, Object> toJson() => <String, Object>{
        'frame_count': frameCount,
        'jank_frames': jankFrames,
        'total_span_over_budget': totalSpanOverBudget,
        'worst_build_ms': worstBuildMs,
        'worst_raster_ms': worstRasterMs,
        'p90_build_ms': p90BuildMs,
        'p90_raster_ms': p90RasterMs,
        'budget_micros': budgetMicros,
        'pass': pass,
      };
}

/// Tóm tắt 3 danh sách µs cùng thứ tự frame. Lệch độ dài → [ArgumentError].
FrameBudgetReport summarizeFrames(
  List<int> buildMicros,
  List<int> rasterMicros,
  List<int> totalSpanMicros, {
  int budgetMicros = kFrameBudgetMicros60Hz,
}) {
  if (buildMicros.length != rasterMicros.length ||
      buildMicros.length != totalSpanMicros.length) {
    throw ArgumentError(
      'Độ dài lệch: build=${buildMicros.length}, '
      'raster=${rasterMicros.length}, totalSpan=${totalSpanMicros.length}',
    );
  }
  var jank = 0;
  var spanOver = 0;
  for (var i = 0; i < buildMicros.length; i++) {
    if (buildMicros[i] > budgetMicros || rasterMicros[i] > budgetMicros) {
      jank++;
    }
    if (totalSpanMicros[i] > budgetMicros) spanOver++;
  }
  return FrameBudgetReport(
    frameCount: buildMicros.length,
    jankFrames: jank,
    totalSpanOverBudget: spanOver,
    worstBuildMs: _maxMs(buildMicros),
    worstRasterMs: _maxMs(rasterMicros),
    p90BuildMs: _percentileMs(buildMicros, 90),
    p90RasterMs: _percentileMs(rasterMicros, 90),
    budgetMicros: budgetMicros,
  );
}

double _maxMs(List<int> micros) =>
    micros.isEmpty ? 0 : micros.reduce((a, b) => a > b ? a : b) / 1000;

/// Phân vị theo nearest-rank; danh sách rỗng → 0.
double _percentileMs(List<int> micros, int percentile) {
  if (micros.isEmpty) return 0;
  final sorted = List<int>.of(micros)..sort();
  var rank = (percentile / 100 * sorted.length).ceil() - 1;
  if (rank < 0) rank = 0;
  if (rank >= sorted.length) rank = sorted.length - 1;
  return sorted[rank] / 1000;
}
