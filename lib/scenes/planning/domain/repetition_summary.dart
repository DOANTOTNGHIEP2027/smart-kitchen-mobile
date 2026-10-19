/// 1 lần món xuất hiện trong window (`RepetitionSummaryResponse.RepetitionOccurrence`).
class RepetitionOccurrence {
  const RepetitionOccurrence({
    required this.mealPlanId,
    required this.mealDate,
    required this.slotLabel,
  });

  final String mealPlanId;
  final DateTime mealDate;
  final String slotLabel;

  factory RepetitionOccurrence.fromJson(Map<String, dynamic> json) =>
      RepetitionOccurrence(
        mealPlanId: json['mealPlanId'] as String,
        mealDate: DateTime.parse(json['mealDate'] as String),
        slotLabel: json['slotLabel'] as String? ?? '',
      );
}

class RepeatedDish {
  const RepeatedDish({
    required this.recipeId,
    required this.recipeName,
    required this.occurrenceCount,
    required this.occurrences,
  });

  final String recipeId;
  final String recipeName;
  final int occurrenceCount;
  final List<RepetitionOccurrence> occurrences;

  factory RepeatedDish.fromJson(Map<String, dynamic> json) => RepeatedDish(
        recipeId: json['recipeId'] as String,
        recipeName: json['recipeName'] as String,
        occurrenceCount: (json['occurrenceCount'] as num).toInt(),
        occurrences: ((json['occurrences'] as List?) ?? const <dynamic>[])
            .map((Object? e) => RepetitionOccurrence.fromJson(
                Map<String, dynamic>.from(e! as Map)))
            .toList(growable: false),
      );
}

/// `GET /households/me/meal-plans/repetition-summary` (thiết kế §5.4).
/// `repeatedDishes = []` là kết quả hợp lệ — không có món nào lặp ≥ 2 lần.
class RepetitionSummary {
  const RepetitionSummary({
    required this.windowDays,
    required this.windowStart,
    required this.windowEnd,
    required this.repeatedDishes,
  });

  final int windowDays;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<RepeatedDish> repeatedDishes;

  factory RepetitionSummary.fromJson(Map<String, dynamic> json) =>
      RepetitionSummary(
        windowDays: (json['windowDays'] as num).toInt(),
        windowStart: DateTime.parse(json['windowStart'] as String),
        windowEnd: DateTime.parse(json['windowEnd'] as String),
        repeatedDishes: ((json['repeatedDishes'] as List?) ?? const <dynamic>[])
            .map((Object? e) =>
                RepeatedDish.fromJson(Map<String, dynamic>.from(e! as Map)))
            .toList(growable: false)
          ..sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount)),
      );
}
