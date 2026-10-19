import '../../../domain/shared/budget_period.dart';

/// `GET/PATCH /households/me/budget` → `BudgetResponse` (camelCase thật của BE,
/// không phải snake_case như bản thiết kế §19.2).
///
/// `GET` LUÔN 200 kể cả khi chưa đặt — mọi field `null`. Đây là dữ liệu HỢP LỆ
/// ("chưa đặt"), không phải lỗi (Guard #12).
class HouseholdBudget {
  const HouseholdBudget({
    required this.period,
    this.amount,
    this.currency,
    this.updatedBy,
    this.updatedAt,
  });

  final BudgetPeriod period;

  /// `null` ⟺ chưa đặt ngân sách.
  final double? amount;
  final String? currency;
  final String? updatedBy;
  final DateTime? updatedAt;

  bool get isSet => amount != null;

  factory HouseholdBudget.fromJson(Map<String, dynamic> json) => HouseholdBudget(
        period: BudgetPeriod.fromApi(json['period'] as String?),
        // JSON thật có thể là int (1500000) — luôn coercion (Guard #16).
        amount: (json['amount'] as num?)?.toDouble(),
        currency: json['currency'] as String?,
        updatedBy: json['updatedBy'] as String?,
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.parse(json['updatedAt'] as String),
      );
}
