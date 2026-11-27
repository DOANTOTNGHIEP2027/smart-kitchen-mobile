import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/widgets/food_category_visual.dart';
import 'package:smart_kitchen_mobile/utils/recipe_images.dart';

void main() {
  test('ảnh backend ưu tiên; seed có ảnh, món lạ không gán ảnh ngẫu nhiên', () {
    expect(
        recipeImageUrl(
            recipeId: 'de300000-0000-4000-8000-000000001001',
            recipeName: 'Phở bò',
            thumbnailUrl: 'https://example.com/real.jpg'),
        'https://example.com/real.jpg');
    expect(
        recipeImageUrl(
            recipeId: 'de300000-0000-4000-8000-000000001001',
            recipeName: 'Phở bò'),
        contains('img-global.cpcdn.com'));
    expect(recipeImageUrl(recipeId: 'unknown', recipeName: 'Món chưa biết'),
        isNull);
  });
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('nhóm seed có icon có màu, không về icon tủ lạnh',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Builder(builder: (context) {
            final visuals = [
              'Thịt',
              'Hải sản',
              'Trứng & sữa',
              'Trái cây',
              'Đồ khô'
            ]
                .map((category) => foodCategoryVisual(context, category, ''))
                .toList();
            for (final visual in visuals) {
              expect(visual.icon, isNot(Icons.kitchen_outlined));
              expect(visual.color, isNot(visual.background));
            }
            return const SizedBox.shrink();
          })));
    });
  }
}
