import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_list_screen.dart';

void main() {
  test('ageOn: chưa tới sinh nhật trong năm → trừ 1; đúng ngày sinh nhật → đủ tuổi', () {
    expect(ageOn(DateTime(2020, 12, 1), DateTime(2026, 10, 19)), 5);
    expect(ageOn(DateTime(2020, 10, 19), DateTime(2026, 10, 19)), 6);
    expect(ageOn(DateTime(2020, 1, 1), DateTime(2026, 10, 19)), 6);
    // Trước sinh nhật 1 ngày (cùng tháng) → chưa đủ tuổi.
    expect(ageOn(DateTime(2020, 10, 20), DateTime(2026, 10, 19)), 5);
    // Sinh 29/2: năm không nhuận đủ tuổi từ 1/3, chưa đủ vào 28/2.
    expect(ageOn(DateTime(2020, 2, 29), DateTime(2026, 2, 28)), 5);
    expect(ageOn(DateTime(2020, 2, 29), DateTime(2026, 3, 1)), 6);
    expect(ageOn(DateTime(2020, 2, 29), DateTime(2024, 2, 29)), 4);
  });

  test('stripMealTypePrefix: bỏ tiền tố [nhãn], không khớp thì giữ nguyên', () {
    final d = MealType.breakfast.composeDescription('phở bò');
    expect(stripMealTypePrefix(d), 'phở bò');
    expect(stripMealTypePrefix(MealType.dinner.composeDescription(null)), '');
    expect(stripMealTypePrefix('cơm tấm'), 'cơm tấm');
  });
}
