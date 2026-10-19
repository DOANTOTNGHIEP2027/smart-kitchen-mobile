/// Số món bị bỏ theo nguyên nhân (weekly-recap §17.1). CHỈ để vẽ cột — con số
/// hiển thị luôn là `WeeklyRecapSummary.wasteItemCount` (Guard #15).
class WasteCauseBreakdown {
  const WasteCauseBreakdown({
    this.overbought = 0,
    this.forgotten = 0,
    this.spoiledEarly = 0,
    this.untagged = 0,
    this.other = 0,
  });

  final int overbought;
  final int forgotten;
  final int spoiledEarly;

  /// Người dùng bỏ qua picker nguyên nhân.
  final int untagged;

  /// Tổng các key lạ (enum tương lai của BE) — KHÔNG cộng vào [untagged].
  final int other;

  static const Set<String> _known = <String>{
    'OVERBOUGHT',
    'FORGOTTEN',
    'SPOILED_EARLY',
    'UNTAGGED',
  };

  /// Thiếu key → 0; key lạ → dồn vào [other]; `null` → toàn 0.
  factory WasteCauseBreakdown.fromJson(Map<String, dynamic>? json) {
    final m = json ?? const <String, dynamic>{};
    int at(String k) => (m[k] as num?)?.toInt() ?? 0;
    final other = m.entries
        .where((e) => !_known.contains(e.key))
        .fold<int>(0, (sum, e) => sum + ((e.value as num?)?.toInt() ?? 0));
    return WasteCauseBreakdown(
      overbought: at('OVERBOUGHT'),
      forgotten: at('FORGOTTEN'),
      spoiledEarly: at('SPOILED_EARLY'),
      untagged: at('UNTAGGED'),
      other: other,
    );
  }

  /// CHỈ làm mẫu số tỉ lệ cột.
  int get barTotal => overbought + forgotten + spoiledEarly + untagged + other;
}

/// 1 điểm xu hướng chi tiêu 8 tuần (PREMIUM). `spendTotal == null` = tuần đó
/// không món nào được nhập giá — vẽ đứt đoạn, KHÔNG coi là 0 (Guard #13).
class SpendTrendPoint {
  const SpendTrendPoint({
    required this.weekStart,
    this.spendTotal,
    this.budgetWeeklyAmount,
  });

  final DateTime weekStart;
  final double? spendTotal;
  final double? budgetWeeklyAmount;

  factory SpendTrendPoint.fromJson(Map<String, dynamic> json) =>
      SpendTrendPoint(
        weekStart: DateTime.parse(json['weekStart'] as String),
        spendTotal: (json['spendTotal'] as num?)?.toDouble(),
        budgetWeeklyAmount: (json['budgetWeeklyAmount'] as num?)?.toDouble(),
      );
}
