/// Chu kỳ ngân sách household — bản DUY NHẤT dùng chung cho module profile và
/// insights (tier-gate-screens.md §19.1, FIX HIGH-A1). Nhãn hiển thị lấy từ l10n.
enum BudgetPeriod {
  weekly,
  monthly,

  /// Giá trị lạ/null — fail-safe, không throw khi parse.
  unknown;

  /// Không phân biệt hoa/thường — đồng bộ với `HouseholdTier.fromApi`.
  static BudgetPeriod fromApi(String? raw) => switch (raw?.toUpperCase()) {
        'WEEKLY' => BudgetPeriod.weekly,
        'MONTHLY' => BudgetPeriod.monthly,
        _ => BudgetPeriod.unknown,
      };

  String toWire() => switch (this) {
        BudgetPeriod.weekly => 'WEEKLY',
        BudgetPeriod.monthly => 'MONTHLY',
        BudgetPeriod.unknown =>
          throw StateError('Không thể gửi period "unknown" lên BE'),
      };
}
