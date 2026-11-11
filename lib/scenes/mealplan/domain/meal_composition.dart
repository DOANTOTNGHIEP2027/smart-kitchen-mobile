class CompositionDiner {
  const CompositionDiner(this.id, this.kind, this.name);
  final String id, kind, name;
  factory CompositionDiner.fromJson(Map<String, dynamic> json) =>
      CompositionDiner(
        json['dinerId'] as String,
        json['kind'] as String,
        json['name'] as String? ?? '',
      );
}

class ComposedMeal {
  const ComposedMeal({
    required this.warnings,
    required this.missing,
    required this.dishes,
    this.totalCalories,
    this.targetCalories,
  });
  final List<String> warnings;
  final List<CompositionIngredient> missing;
  final List<ComposedMealDish> dishes;
  final double? totalCalories, targetCalories;
  factory ComposedMeal.fromJson(Map<String, dynamic> json) => ComposedMeal(
        warnings: (json['warnings'] as List<dynamic>? ?? []).cast<String>(),
        missing: (json['missingIngredients'] as List<dynamic>? ?? [])
            .map((v) =>
                CompositionIngredient.fromJson(v as Map<String, dynamic>))
            .toList(),
        dishes: (json['dishes'] as List<dynamic>? ?? [])
            .map((v) => ComposedMealDish.fromJson(v as Map<String, dynamic>))
            .toList(),
        totalCalories: (json['totalCalories'] as num?)?.toDouble(),
        targetCalories: (json['targetCalories'] as num?)?.toDouble(),
      );
}

class CompositionIngredient {
  const CompositionIngredient(this.name, this.quantity, this.unit);
  final String name, unit;
  final double quantity;
  factory CompositionIngredient.fromJson(Map<String, dynamic> json) =>
      CompositionIngredient(
        json['name'] as String,
        (json['quantity'] as num).toDouble(),
        json['unit'] as String,
      );
}

class ComposedMealDish {
  const ComposedMealDish(this.name, this.servings, this.requirements);
  final String name;
  final double servings;
  final List<CompositionIngredient> requirements;
  factory ComposedMealDish.fromJson(Map<String, dynamic> json) =>
      ComposedMealDish(
        (json['recipe'] as Map<String, dynamic>)['mealName'] as String,
        (json['plannedServings'] as num).toDouble(),
        (json['requirements'] as List<dynamic>)
            .map(
              (v) => CompositionIngredient.fromJson(v as Map<String, dynamic>),
            )
            .toList(),
      );
}

class CompositionContext {
  const CompositionContext(this.version, this.diners, this.menu);
  final int version;
  final List<CompositionDiner> diners;
  final ComposedMeal? menu;
  factory CompositionContext.fromJson(Map<String, dynamic> json) =>
      CompositionContext(
        (json['menuVersion'] as num).toInt(),
        (json['diners'] as List<dynamic>)
            .map((v) => CompositionDiner.fromJson(v as Map<String, dynamic>))
            .toList(),
        json['menu'] == null
            ? null
            : ComposedMeal.fromJson(json['menu'] as Map<String, dynamic>),
      );
}

class CompositionReceipt {
  const CompositionReceipt(this.requestId, this.status, this.menu);
  final String requestId, status;
  final ComposedMeal? menu;
  bool get terminal => status != 'RUNNING';
  factory CompositionReceipt.fromJson(Map<String, dynamic> json) =>
      CompositionReceipt(
        json['requestId'] as String,
        json['status'] as String,
        json['result'] == null
            ? null
            : ComposedMeal.fromJson(json['result'] as Map<String, dynamic>),
      );
}
