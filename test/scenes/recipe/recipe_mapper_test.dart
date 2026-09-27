import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/data/recipe_mapper.dart';

void main() {
  group('mapRecipe', () {
    test('đọc payload RecipeResponse camelCase từ backend', () {
      final recipe = mapRecipe(<String, dynamic>{
        'id': 'recipe-1',
        'householdId': null,
        'name': 'Canh chua cá',
        'cuisine': 'Việt Nam',
        'dietTypes': <String>['PESCATARIAN'],
        'prepTimeMinutes': 15,
        'cookTimeMinutes': 20,
        'serves': 4,
        'difficulty': 'EASY',
        'thumbnailUrl': null,
        'ingredients': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Cá', 'quantity': 400, 'unit': 'g'},
        ],
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{
            'stepNumber': 1,
            'instruction': 'Nấu canh',
            'durationMinutes': 20,
          },
        ],
        'nutrition': <String, dynamic>{'calories': 250},
        'source': 'AI_SUGGESTED',
        'createdAt': '2026-09-27T00:00:00.000Z',
        'updatedAt': '2026-09-27T00:00:00.000Z',
        'myFavorite': true,
        'myRating': 4,
        'favoriteCount': 2,
        'avgRating': 4.5,
      });

      expect(recipe.name, 'Canh chua cá');
      expect(recipe.hasSteps, isTrue);
      expect(recipe.steps!.single.stepNumber, 1);
      expect(recipe.steps!.single.durationMinutes, 20);
      expect(recipe.ingredients!.single.quantity, 400);
      expect(recipe.nutrition!.calories, 250);
      expect(recipe.favorite.myFavorite, isTrue);
      expect(recipe.favorite.myRating, 4);
      expect(recipe.favorite.favoriteCount, 2);
      expect(recipe.favorite.avgRating, 4.5);
    });

    test('chấp nhận item danh sách yêu thích không có detail fields', () {
      final recipe = mapRecipe(<String, dynamic>{
        'id': 'recipe-1',
        'name': 'Công thức nháp',
        'dietTypes': <String>[],
        'source': 'MANUAL',
        'createdAt': '2026-09-27T00:00:00.000Z',
        'updatedAt': '2026-09-27T00:00:00.000Z',
        'myFavorite': true,
        'myRating': null,
        'favoritedAt': '2026-09-27T00:00:00.000Z',
        'favoriteCount': 1,
        'avgRating': null,
      });

      expect(recipe.ingredients, isNull);
      expect(recipe.steps, isNull);
      expect(recipe.nutrition, isNull);
      expect(recipe.hasSteps, isFalse);
      expect(recipe.favorite.myFavorite, isTrue);
    });
  });
}
