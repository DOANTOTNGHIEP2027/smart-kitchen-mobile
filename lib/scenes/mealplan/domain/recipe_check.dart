import 'meal_suggestion.dart';

/// 1 dị ứng của người ăn trùng với công thức (`allergens[]` của recipe-check).
class RecipeCheckAllergen {
  const RecipeCheckAllergen({this.id, required this.name});

  final String? id;
  final String name;
}

/// 1 người ăn bữa này bị dị ứng với công thức định chọn.
class RecipeAllergenConflict {
  const RecipeAllergenConflict({
    required this.personType,
    this.personId,
    required this.name,
    required this.allergens,
  });

  /// `MEMBER` | `DEPENDENT` | `GUEST`.
  final String personType;
  final String? personId;
  final String name;
  final List<RecipeCheckAllergen> allergens;
}

/// Kết quả `GET .../slots/{slotId}/recipe-check?recipeId=` — kiểm tra TRƯỚC
/// khi gán món tay (chỉ đọc, không tạo dish).
class RecipeCheckResult {
  const RecipeCheckResult({
    required this.recipeId,
    required this.allergenConflicts,
    required this.allergenVerified,
    required this.missingIngredients,
  });

  final String recipeId;
  final List<RecipeAllergenConflict> allergenConflicts;

  /// `false` ⇒ dữ liệu dị ứng của công thức chưa được kiểm chứng.
  final bool allergenVerified;

  /// Nguyên liệu kho đang thiếu (cùng shape `missingIngredients` của dish).
  final List<IngredientItem> missingIngredients;
}
