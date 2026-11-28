import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_log_entry.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/meal_type.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/meal_log_scene.dart';

MealLogEntry _entry(String id, String description, DateTime loggedAt) => MealLogEntry(
      id: id,
      householdId: 'h1',
      memberId: 'u1',
      loggedBy: 'u1',
      description: description,
      caloriesKcal: 100,
      requiresConfirmation: false,
      confirmedByUser: false,
      loggedAt: loggedAt,
      status: MealEntryStatus.saved,
    );

void main() {
  group('mealTypeByHour', () {
    test('ranh giới giờ khớp bữa mặc định của sheet ghi món', () {
      expect(mealTypeByHour(6), MealType.breakfast);
      expect(mealTypeByHour(9), MealType.breakfast);
      expect(mealTypeByHour(10), MealType.lunch);
      expect(mealTypeByHour(13), MealType.lunch);
      expect(mealTypeByHour(15), MealType.snack);
      expect(mealTypeByHour(17), MealType.dinner);
      expect(mealTypeByHour(20), MealType.dinner);
      expect(mealTypeByHour(22), MealType.snack);
      expect(mealTypeByHour(3), MealType.snack);
    });
  });

  group('mealGroup', () {
    test('ưu tiên bữa đã chọn lúc ghi (tiền tố), kể cả ghi trễ giờ', () {
      // Ghi bữa trưa lúc 15h vẫn vào nhóm trưa.
      final late = _entry('a', '[Bữa trưa] Cơm gà', DateTime(2026, 11, 28, 15));
      expect(late.mealGroup, MealType.lunch);
    });

    test('không có tiền tố → suy theo giờ ghi', () {
      expect(_entry('b', 'Bánh mì', DateTime(2026, 11, 28, 7)).mealGroup, MealType.breakfast);
      expect(_entry('c', 'Bún chả', DateTime(2026, 11, 28, 18)).mealGroup, MealType.dinner);
    });
  });

  group('groupMealLogs', () {
    test('sáng → trưa → tối → ăn vặt, bỏ bữa trống, giữ thứ tự trong nhóm', () {
      final groups = groupMealLogs(<MealLogEntry>[
        _entry('t2', '[Bữa tối] Canh chua', DateTime(2026, 11, 28, 19, 30)),
        _entry('t1', '[Bữa tối] Cá kho', DateTime(2026, 11, 28, 19)),
        _entry('s1', '[Bữa sáng] Phở bò', DateTime(2026, 11, 28, 7)),
        _entry('v1', '[Ăn vặt] Sữa chua', DateTime(2026, 11, 28, 15)),
      ]);

      expect(groups.map((g) => g.type),
          <MealType>[MealType.breakfast, MealType.dinner, MealType.snack]);
      expect(groups[1].entries.map((e) => e.id), <String>['t2', 't1']);
    });

    test('danh sách rỗng → không nhóm nào', () {
      expect(groupMealLogs(const <MealLogEntry>[]), isEmpty);
    });
  });
}
