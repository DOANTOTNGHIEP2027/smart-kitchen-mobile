/// Streak hiện tại/kỷ lục của HOUSEHOLD (#84) — kết quả household-level,
/// KHÔNG đổi theo member đang xem.
class StreakSummary {
  const StreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    this.lastComputedWeekStart,
  });

  final int currentStreak;
  final int bestStreak;

  /// `null` nếu household chưa từng được batch xử lý (#84).
  final DateTime? lastComputedWeekStart;
}