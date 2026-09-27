class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    this.quantity,
    this.unit,
    this.note,
  });

  final String name;
  final double? quantity;
  final String? unit;
  final String? note;
}

class RecipeStep {
  const RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.durationMinutes,
  });

  final int stepNumber;
  final String instruction;
  final int? durationMinutes;
}

class RecipeNutrition {
  const RecipeNutrition({
    this.calories,
    this.proteinG,
    this.fatG,
    this.carbsG,
  });

  final double? calories;
  final double? proteinG;
  final double? fatG;
  final double? carbsG;
}

/// Trạng thái yêu thích/đánh giá của chính người dùng và của household.
///
/// Hai trục favourite và rating được cập nhật riêng để một request hoàn thành
/// muộn không ghi đè thao tác còn lại.
class RecipeFavoriteState {
  const RecipeFavoriteState({
    this.myFavorite = false,
    this.favoritedAt,
    this.myRating,
    this.favoriteCount = 0,
    this.avgRating,
  });

  static const RecipeFavoriteState empty = RecipeFavoriteState();

  final bool myFavorite;
  final DateTime? favoritedAt;
  final int? myRating;
  final int favoriteCount;
  final double? avgRating;

  RecipeFavoriteState copyWith({
    bool? myFavorite,
    DateTime? favoritedAt,
    bool clearFavoritedAt = false,
    int? myRating,
    bool clearRating = false,
    int? favoriteCount,
    double? avgRating,
    bool clearAvgRating = false,
  }) =>
      RecipeFavoriteState(
        myFavorite: myFavorite ?? this.myFavorite,
        favoritedAt: clearFavoritedAt ? null : (favoritedAt ?? this.favoritedAt),
        myRating: clearRating ? null : (myRating ?? this.myRating),
        favoriteCount: favoriteCount ?? this.favoriteCount,
        avgRating: clearAvgRating ? null : (avgRating ?? this.avgRating),
      );

  RecipeFavoriteState withFavoriteAxisOf(RecipeFavoriteState source) =>
      copyWith(
        myFavorite: source.myFavorite,
        favoritedAt: source.favoritedAt,
        clearFavoritedAt: source.favoritedAt == null,
        favoriteCount: source.favoriteCount,
      );

  RecipeFavoriteState withRatingAxisOf(RecipeFavoriteState source) => copyWith(
        myRating: source.myRating,
        clearRating: source.myRating == null,
        avgRating: source.avgRating,
        clearAvgRating: source.avgRating == null,
      );
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.dietTypes,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.householdId,
    this.cuisine,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.serves,
    this.difficulty,
    this.thumbnailUrl,
    this.ingredients,
    this.steps,
    this.nutrition,
    this.favorite = RecipeFavoriteState.empty,
  });

  final String id;
  final String? householdId;
  final String name;
  final String? cuisine;
  final List<String> dietTypes;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int? serves;
  final String? difficulty;
  final String? thumbnailUrl;
  final List<RecipeIngredient>? ingredients;
  final List<RecipeStep>? steps;
  final RecipeNutrition? nutrition;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RecipeFavoriteState favorite;

  bool get hasSteps => steps != null && steps!.isNotEmpty;

  Recipe copyWithFavorite(RecipeFavoriteState value) => Recipe(
        id: id,
        householdId: householdId,
        name: name,
        cuisine: cuisine,
        dietTypes: dietTypes,
        prepTimeMinutes: prepTimeMinutes,
        cookTimeMinutes: cookTimeMinutes,
        serves: serves,
        difficulty: difficulty,
        thumbnailUrl: thumbnailUrl,
        ingredients: ingredients,
        steps: steps,
        nutrition: nutrition,
        source: source,
        createdAt: createdAt,
        updatedAt: updatedAt,
        favorite: value,
      );
}

class RecipePage {
  const RecipePage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<Recipe> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
}
