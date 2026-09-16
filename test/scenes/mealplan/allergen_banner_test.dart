import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/allergen_derivation.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/widgets/allergen_banner.dart';

/// Tests cho `AllergenBanner` 3 nhánh — DoD FE-7 bắt buộc (Implementation Guard
/// #7, engine §7.3). Test nhánh "UNVERIFIED + [] = chưa kiểm, không phải an
/// toàn" là **test chống hồi quy an toàn dị ứng** — không được xoá.
void main() {
  group('AllergenBanner — 3 nhánh §9.3', () {
    testWidgets(
        'nhánh 1: isAllergenCleared (INGREDIENT_RULE + tags rỗng) → ẩn hoàn toàn',
        (WidgetTester tester) async {
      const suggestion = MealSuggestion(
        recipeId: 'r1',
        mealName: 'Canh rau',
        allergenTags: <String>[],
        allergenDerivation: AllergenDerivation.ingredientRule,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AllergenBanner(suggestion: suggestion)),
      ));

      expect(find.byType(AllergenBanner), findsOneWidget);
      expect(find.textContaining('dị ứng'), findsNothing,
          reason: 'đã clear → ẩn, KHÔNG hiển thị thông tin dị ứng');
    });

    testWidgets(
        'nhánh 2: INGREDIENT_RULE + có tag → banner ĐỎ nêu đích danh',
        (WidgetTester tester) async {
      const suggestion = MealSuggestion(
        recipeId: 'r1',
        mealName: 'Canh tôm',
        allergenTags: <String>['Shellfish', 'Eggs'],
        allergenDerivation: AllergenDerivation.ingredientRule,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AllergenBanner(suggestion: suggestion)),
      ));

      expect(find.textContaining('Shellfish'), findsOneWidget);
      expect(find.textContaining('Eggs'), findsOneWidget);
    });

    testWidgets(
        '⭐ nhánh 3: UNVERIFIED + tags rỗng → BẮT BUỘC banner vàng, KHÔNG SizedBox.shrink()',
        (WidgetTester tester) async {
      // Đây là test chống hồi quy — 4 nhánh của derivation,
      // UNVERIFIED/SOURCE/MANUAL/unknown → cần cảnh báo.
      const suggestion = MealSuggestion(
        recipeId: 'r1',
        mealName: 'Món AI sinh (generated)',
        allergenTags: <String>[], // rỗng NHƯNG chưa kiểm
        allergenDerivation: AllergenDerivation.unverified,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AllergenBanner(suggestion: suggestion)),
      ));

      expect(find.textContaining('Chưa kiểm chứng'), findsOneWidget,
          reason:
              'UNVERIFIED có nghĩa là CHƯA KIỂM, không phải an toàn. '
              'AllergenBanner không bao giờ được im lặng ở nhánh này — '
              'vi phạm = bug an toàn dị ứng (engine §7.3).');
    });

    testWidgets('nhánh "unknown" derivation lạ → vẫn cảnh báo vàng',
        (WidgetTester tester) async {
      const suggestion = MealSuggestion(
        recipeId: 'r1',
        mealName: 'Món lạ',
        allergenTags: <String>[],
        allergenDerivation: AllergenDerivation.unknown,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AllergenBanner(suggestion: suggestion)),
      ));

      expect(find.textContaining('Chưa kiểm chứng'), findsOneWidget);
    });

    testWidgets('nhánh SOURCE + tags rỗng → cảnh báo vàng', (tester) async {
      const suggestion = MealSuggestion(
        recipeId: 'r1',
        mealName: 'Món mới',
        allergenTags: <String>[],
        allergenDerivation: AllergenDerivation.source,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AllergenBanner(suggestion: suggestion)),
      ));

      expect(find.textContaining('Chưa kiểm chứng'), findsOneWidget);
    });
  });

  group('MealSuggestion — B1 getters', () {
    test('isAllergenCleared đúng định nghĩa 4-trạng-thái', () {
      expect(
        const MealSuggestion(
          recipeId: 'r1',
          mealName: 'm',
          allergenDerivation: AllergenDerivation.ingredientRule,
        ).isAllergenCleared,
        isTrue,
        reason: 'INGREDIENT_RULE + không tag → clear',
      );
      expect(
        const MealSuggestion(
          recipeId: 'r1',
          mealName: 'm',
          allergenTags: <String>['Fish'],
          allergenDerivation: AllergenDerivation.ingredientRule,
        ).isAllergenCleared,
        isFalse,
        reason: 'Đã kiểm nhưng CÓ tag → không clear',
      );
      expect(
        const MealSuggestion(
          recipeId: 'r1',
          mealName: 'm',
          allergenDerivation: AllergenDerivation.unverified,
        ).isAllergenCleared,
        isFalse,
        reason: 'Chưa kiểm thì không clear dù tags rỗng',
      );
    });

    test('needsAllergenWarning đúng definition', () {
      expect(
        const MealSuggestion(
          recipeId: 'r',
          mealName: 'm',
          allergenDerivation: AllergenDerivation.ingredientRule,
        ).needsAllergenWarning,
        isFalse,
      );
      for (final d in <AllergenDerivation>[
        AllergenDerivation.source,
        AllergenDerivation.manual,
        AllergenDerivation.unverified,
        AllergenDerivation.unknown,
      ]) {
        expect(
          MealSuggestion(
            recipeId: 'r',
            mealName: 'm',
            allergenDerivation: d,
          ).needsAllergenWarning,
          isTrue,
          reason: '$d → warning',
        );
      }
    });
  });

  group('MealSuggestion.fromVoteOpen — camelCase parsing', () {
    test('parse đúng 7 field B1 + confidence', () {
      final s = MealSuggestion.fromVoteOpen(<String, dynamic>{
        'recipeId': 'r1',
        'recipeName': 'Canh chua',
        'confidence': 0.85,
        'kbRecipeId': 'kb-1',
        'source': 'KB',
        'rankReason': 'Ưu tiên vì cá lóc còn 1 ngày hết hạn',
        'tradeoffNote': 'Tuy hơi mặn nhưng tốt cho sức khoẻ',
        'missingIngredients': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Cà chua',
            'quantity': 200,
            'unit': 'GRAM',
            'role': 'MAIN',
          },
        ],
        'allergenTags': <String>['Fish'],
        'allergenDerivation': 'INGREDIENT_RULE',
      });

      expect(s.recipeId, 'r1');
      expect(s.mealName, 'Canh chua');
      expect(s.confidenceScore, 0.85);
      expect(s.kbRecipeId, 'kb-1');
      expect(s.source, 'KB');
      expect(s.rankReason, 'Ưu tiên vì cá lóc còn 1 ngày hết hạn');
      expect(s.tradeoffNote, 'Tuy hơi mặn nhưng tốt cho sức khoẻ');
      expect(s.missingIngredients.length, 1);
      expect(s.missingIngredients.first.name, 'Cà chua');
      expect(s.missingIngredients.first.quantity, 200);
      expect(s.missingIngredients.first.role, 'MAIN');
      expect(s.allergenTags, <String>['Fish']);
      expect(s.allergenDerivation, AllergenDerivation.ingredientRule);
      expect(s.isAllergenCleared, isFalse); // có tag Fish
    });

    test('UNVERIFIED + empty tags → needsAllergenWarning=true', () {
      final s = MealSuggestion.fromVoteOpen(<String, dynamic>{
        'recipeId': 'r1',
        'recipeName': 'Món AI sinh',
        'confidence': 0.5,
        'source': 'GENERATED',
        'rankReason': 'Không có món nào trong KB khớp',
        'missingIngredients': <dynamic>[],
        'allergenTags': <String>[],
        'allergenDerivation': 'UNVERIFIED',
      });

      expect(s.source, 'GENERATED');
      expect(s.allergenTags, isEmpty);
      expect(s.allergenDerivation, AllergenDerivation.unverified);
      expect(s.needsAllergenWarning, isTrue);
    });

    test('field lạ/missing → derivation unknown → warning', () {
      final s = MealSuggestion.fromVoteOpen(<String, dynamic>{
        'recipeId': 'r1',
        'recipeName': 'Món không rõ nguồn',
        'confidence': 0.5,
        // source/rankReason missing → null
        'missingIngredients': null,
        'allergenTags': null,
        // allergenDerivation missing → unknown
      });

      expect(s.source, isNull);
      expect(s.rankReason, isNull);
      expect(s.allergenTags, isEmpty);
      expect(s.allergenDerivation, AllergenDerivation.unknown);
      expect(s.needsAllergenWarning, isTrue);
    });
  });
}
