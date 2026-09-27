import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/recipe.dart';
import 'recipe_mapper.dart';

abstract interface class RecipeCatalogApi {
  Future<RecipePage> list({
    required int page,
    required int size,
    String? search,
    String? dietType,
    String? difficulty,
    int? maxPrepTime,
  });

  Future<RecipePage> listFavorites({required int page, required int size});
  Future<Recipe> getById(String recipeId);
  Future<RecipeFavoriteState> setFavorite(String recipeId, bool isFavorite);
  Future<RecipeFavoriteState> setRating(String recipeId, int? rating);
}

class RecipeCatalogApiImpl implements RecipeCatalogApi {
  RecipeCatalogApiImpl(this._client);

  final DioClient _client;

  @override
  Future<RecipePage> list({
    required int page,
    required int size,
    String? search,
    String? dietType,
    String? difficulty,
    int? maxPrepTime,
  }) =>
      _unwrap(() async {
        final response = await _client.dio.get<Map<String, dynamic>>(
          '/api/v1/recipes',
          queryParameters: <String, dynamic>{
            'page': page,
            'size': size,
            if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
            if (dietType != null) 'dietType': dietType,
            if (difficulty != null) 'difficulty': difficulty,
            if (maxPrepTime != null) 'maxPrepTime': maxPrepTime,
          },
        );
        return mapRecipePage(_dataOf(response));
      });

  @override
  Future<RecipePage> listFavorites({required int page, required int size}) =>
      _unwrap(() async {
        final response = await _client.dio.get<Map<String, dynamic>>(
          '/api/v1/recipes/favorites',
          queryParameters: <String, dynamic>{'page': page, 'size': size},
        );
        return mapRecipePage(_dataOf(response));
      });

  @override
  Future<Recipe> getById(String recipeId) => _unwrap(() async {
        final response = await _client.dio.get<Map<String, dynamic>>(
          '/api/v1/recipes/$recipeId',
        );
        return mapRecipe(_dataOf(response));
      });

  @override
  Future<RecipeFavoriteState> setFavorite(String recipeId, bool isFavorite) =>
      _unwrap(() async {
        final response = await _client.dio.put<Map<String, dynamic>>(
          '/api/v1/recipes/$recipeId/favorite',
          data: <String, dynamic>{'isFavorite': isFavorite},
        );
        return mapRecipeFavoriteState(_dataOf(response));
      });

  @override
  Future<RecipeFavoriteState> setRating(String recipeId, int? rating) =>
      _unwrap(() async {
        final response = await _client.dio.put<Map<String, dynamic>>(
          '/api/v1/recipes/$recipeId/rating',
          data: <String, dynamic>{'rating': rating},
        );
        return mapRecipeFavoriteState(_dataOf(response));
      });

  Map<String, dynamic> _dataOf(Response<Map<String, dynamic>> response) {
    final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (value) => Map<String, dynamic>.from(value! as Map),
    );
    if (!envelope.success || envelope.data == null) {
      throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
    }
    return envelope.data!;
  }

  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw error.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
