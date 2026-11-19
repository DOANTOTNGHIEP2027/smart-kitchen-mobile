import 'package:smart_kitchen_mobile/scenes/recipe/data/recipe_catalog_api.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/domain/recipe.dart';

/// Tham số của một lần gọi `list` — để test đối chiếu filter/search/page.
class ListCall {
  ListCall({
    required this.page,
    required this.size,
    this.search,
    this.dietType,
    this.difficulty,
    this.maxPrepTime,
  });

  final int page;
  final int size;
  final String? search;
  final String? dietType;
  final String? difficulty;
  final int? maxPrepTime;
}

/// Fake viết tay cho [RecipeCatalogApi] (pattern `fake_cooking_api.dart`).
/// Mỗi handler có thể trả Future treo (Completer) để test trạng thái
/// loading / response về muộn.
class FakeRecipeCatalogApi implements RecipeCatalogApi {
  Future<RecipePage> Function(ListCall call)? onList;
  Future<RecipePage> Function(int page, int size)? onListFavorites;
  Future<Recipe> Function(String recipeId)? onGetById;
  Future<RecipeFavoriteState> Function(String recipeId, bool isFavorite)?
      onSetFavorite;
  Future<RecipeFavoriteState> Function(String recipeId, int? rating)?
      onSetRating;

  final List<ListCall> listCalls = <ListCall>[];
  final List<int> favoritesPages = <int>[];
  final List<String> getByIdCalls = <String>[];
  final List<(String, bool)> setFavoriteCalls = <(String, bool)>[];
  final List<(String, int?)> setRatingCalls = <(String, int?)>[];

  @override
  Future<RecipePage> list({
    required int page,
    required int size,
    String? search,
    String? dietType,
    String? difficulty,
    int? maxPrepTime,
  }) {
    final call = ListCall(
      page: page,
      size: size,
      search: search,
      dietType: dietType,
      difficulty: difficulty,
      maxPrepTime: maxPrepTime,
    );
    listCalls.add(call);
    return onList?.call(call) ?? Future<RecipePage>.value(recipePage(const []));
  }

  @override
  Future<RecipePage> listFavorites({required int page, required int size}) {
    favoritesPages.add(page);
    return onListFavorites?.call(page, size) ??
        Future<RecipePage>.value(recipePage(const []));
  }

  @override
  Future<Recipe> getById(String recipeId) {
    getByIdCalls.add(recipeId);
    return onGetById!(recipeId);
  }

  @override
  Future<RecipeFavoriteState> setFavorite(String recipeId, bool isFavorite) {
    setFavoriteCalls.add((recipeId, isFavorite));
    return onSetFavorite!(recipeId, isFavorite);
  }

  @override
  Future<RecipeFavoriteState> setRating(String recipeId, int? rating) {
    setRatingCalls.add((recipeId, rating));
    return onSetRating!(recipeId, rating);
  }
}

final DateTime fixedTime = DateTime.utc(2026, 9, 27);

Recipe buildRecipe(
  String id, {
  String? name,
  List<RecipeStep>? steps,
  List<RecipeIngredient>? ingredients,
  RecipeFavoriteState favorite = RecipeFavoriteState.empty,
  String? difficulty,
}) =>
    Recipe(
      id: id,
      name: name ?? 'Món $id',
      dietTypes: const <String>[],
      source: 'MANUAL',
      createdAt: fixedTime,
      updatedAt: fixedTime,
      steps: steps,
      ingredients: ingredients,
      favorite: favorite,
      difficulty: difficulty,
    );

RecipePage recipePage(
  List<Recipe> items, {
  int page = 0,
  int totalPages = 1,
  int size = 20,
}) =>
    RecipePage(
      items: items,
      page: page,
      size: size,
      totalElements: items.length,
      totalPages: totalPages,
    );
