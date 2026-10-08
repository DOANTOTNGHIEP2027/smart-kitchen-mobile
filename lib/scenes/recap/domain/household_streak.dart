/// Streak hiện tại/kỷ lục của HOUSEHOLD (không phải per-member) — snapshot
/// tính sẵn từ batch job #84 (adherence-streak.yaml).
class HouseholdStreak {
  const HouseholdStreak({
    required this.householdId,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastComputedWeekStart,
  });

  final String householdId;
  final int currentStreak;
  final int bestStreak;

  /// `null` nếu household chưa từng được batch #84 xử lý lần nào.
  final DateTime? lastComputedWeekStart;
}