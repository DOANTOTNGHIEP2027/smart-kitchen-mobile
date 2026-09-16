import 'package:dio/dio.dart';

import '../../../data/network/api_exception.dart';
import '../../../data/network/api_response.dart';
import '../../../data/network/dio_client.dart';
import '../domain/cooking_session_step.dart';
import 'cooking_session_mapper.dart';

/// Tối giản — chỉ cần `getSteps(recipeId)` cho màn hình nấu ăn (FE-6 §3,
/// nguồn `recipes.steps` #75).
///
/// Không tái tạo toàn bộ `GET /recipes/{id}` (title/yields/tags/...) vì màn
/// nấu ăn không tiêu thụ các field đó — bám §2 "ngoài phạm vi" của
/// recipe-list-detail-screens.md. `recipeName` đến cooking screen qua
/// `CookingSession.recipeName` (snapshot tại start) hoặc argument route.
abstract interface class RecipeApi {
  Future<List<CookingSessionStep>> getSteps(String recipeId);
}

class RecipeApiImpl implements RecipeApi {
  RecipeApiImpl(this._client);

  final DioClient _client;

  @override
  Future<List<CookingSessionStep>> getSteps(String recipeId) {
    return _unwrap(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/v1/recipes/$recipeId',
      );
      final envelope = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const <String, dynamic>{},
        (Object? v) => Map<String, dynamic>.from(v! as Map),
      );
      if (!envelope.success || envelope.data == null) {
        throw ServerException('ERR_UNKNOWN', 'Invalid success envelope');
      }
      final steps = envelope.data!['steps'] as List<dynamic>? ??
          const <dynamic>[];
      return steps
          .map((Object? e) =>
              mapCookingSessionStep(e as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<T> _unwrap<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw e.error as ApiException? ??
          ServerException('ERR_UNKNOWN', 'Unexpected response');
    }
  }
}
