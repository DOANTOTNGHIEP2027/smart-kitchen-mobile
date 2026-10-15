/// Điểm tuân thủ theo TUẦN LỊCH (Monday-aligned, #84).
class WeeklyAdherencePoint {
  const WeeklyAdherencePoint({required this.weekStart, this.adherencePercent});

  /// Luôn Monday (WeekStartNormalizer convention, #84).
  final DateTime weekStart;

  /// `null` = chưa có snapshot (404 `ERR_ADHERENCE_NOT_FOUND` cho tuần đó).
  final double? adherencePercent;
}