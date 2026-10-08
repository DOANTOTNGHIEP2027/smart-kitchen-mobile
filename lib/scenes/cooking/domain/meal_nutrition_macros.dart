/// Bộ nutrient ước tính từ AI (#77 `NutritionMacrosResponse`, camelCase).
class MealNutritionMacros {
  const MealNutritionMacros({
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
  });

  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  /// Nullable đúng optionality thật của #79 §2.3 (model không tách được).
  final double? fiberG;

  factory MealNutritionMacros.fromJson(Map<String, dynamic> json) {
    return MealNutritionMacros(
      // Guard #11: coerce qua num — jsonDecode có thể parse int cho giá trị
      // không phần thập phân; `as double?` sẽ throw runtime.
      proteinG: (json['proteinG'] as num?)?.toDouble(),
      carbsG: (json['carbsG'] as num?)?.toDouble(),
      fatG: (json['fatG'] as num?)?.toDouble(),
      fiberG: (json['fiberG'] as num?)?.toDouble(),
    );
  }
}