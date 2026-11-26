/// Thống kê latency cho benchmark gate (on-device-ai-runtime.md §4.3).
library;

/// Percentile kiểu nearest-rank: phần tử thứ ceil(p/100 × n) của mảng đã sắp.
/// Không nội suy — p95 luôn là một lần đo có thật.
double percentile(List<double> samples, double p) {
  if (samples.isEmpty) throw ArgumentError('samples rỗng');
  if (p <= 0 || p > 100) throw ArgumentError('p ngoài (0, 100]: $p');
  final sorted = [...samples]..sort();
  final rank = (p / 100 * sorted.length).ceil();
  return sorted[rank - 1];
}

/// Kết quả warm inference của MỘT cấu hình (runtime × delegate).
class WarmStats {
  WarmStats(this.samplesMs)
      : p50Ms = percentile(samplesMs, 50),
        p95Ms = percentile(samplesMs, 95);

  final List<double> samplesMs;
  final double p50Ms;
  final double p95Ms;

  Map<String, dynamic> toJson() => {
        'n': samplesMs.length,
        'p50Ms': _r(p50Ms),
        'p95Ms': _r(p95Ms),
        'minMs': _r(samplesMs.reduce((a, b) => a < b ? a : b)),
        'maxMs': _r(samplesMs.reduce((a, b) => a > b ? a : b)),
      };
}

/// Hệ số tăng tốc của delegate so với CPU, theo p50. `null` khi delegate
/// không khởi tạo được trên máy này — ghi nhận "không hỗ trợ", không suy diễn.
double? delegateSpeedup({required WarmStats cpu, WarmStats? delegate}) =>
    delegate == null ? null : cpu.p50Ms / delegate.p50Ms;

double _r(double v) => (v * 100).roundToDouble() / 100;
