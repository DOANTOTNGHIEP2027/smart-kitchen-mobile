import '../domain/recipe.dart';

RecipePage mapRecipePage(Map<String, dynamic> json) => RecipePage(
      items: ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => mapRecipe(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );

Recipe mapRecipe(Map<String, dynamic> json) {
  final ingredientsJson = json['ingredients'];
  final stepsJson = json['steps'];
  final nutritionJson = json['nutrition'];
  return Recipe(
    id: json['id'] as String,
    householdId: json['householdId'] as String?,
    name: json['name'] as String,
    cuisine: json['cuisine'] as String?,
    dietTypes: ((json['dietTypes'] as List<dynamic>?) ?? const <dynamic>[])
        .map((value) => value as String)
        .toList(growable: false),
    prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt(),
    cookTimeMinutes: (json['cookTimeMinutes'] as num?)?.toInt(),
    serves: (json['serves'] as num?)?.toInt(),
    difficulty: json['difficulty'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    ingredients: ingredientsJson is List<dynamic>
        ? ingredientsJson
            .map((value) => _mapIngredient(Map<String, dynamic>.from(value as Map)))
            .toList(growable: false)
        : null,
    steps: stepsJson is List<dynamic>
        ? stepsJson
            .map((value) => _mapStep(Map<String, dynamic>.from(value as Map)))
            .toList(growable: false)
        : null,
    nutrition: nutritionJson is Map
        ? _mapNutrition(Map<String, dynamic>.from(nutritionJson))
        : null,
    source: json['source'] as String? ?? 'AI_SUGGESTED',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    favorite: RecipeFavoriteState(
      myFavorite: json['myFavorite'] as bool? ?? false,
      favoritedAt: DateTime.tryParse(json['favoritedAt'] as String? ?? ''),
      myRating: (json['myRating'] as num?)?.toInt(),
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble(),
    ),
  );
}

RecipeFavoriteState mapRecipeFavoriteState(Map<String, dynamic> json) =>
    RecipeFavoriteState(
      myFavorite: json['myFavorite'] as bool,
      favoritedAt: DateTime.tryParse(json['favoritedAt'] as String? ?? ''),
      myRating: (json['myRating'] as num?)?.toInt(),
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble(),
    );

RecipeIngredient _mapIngredient(Map<String, dynamic> json) => RecipeIngredient(
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      note: json['note'] as String?,
    );

RecipeStep _mapStep(Map<String, dynamic> json) => RecipeStep(
      stepNumber: (json['stepNumber'] as num).toInt(),
      instruction: json['instruction'] as String,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    );

RecipeNutrition _mapNutrition(Map<String, dynamic> json) => RecipeNutrition(
      calories: (json['calories'] as num?)?.toDouble(),
      proteinG: (json['proteinG'] as num?)?.toDouble(),
      fatG: (json['fatG'] as num?)?.toDouble(),
      carbsG: (json['carbsG'] as num?)?.toDouble(),
    );
