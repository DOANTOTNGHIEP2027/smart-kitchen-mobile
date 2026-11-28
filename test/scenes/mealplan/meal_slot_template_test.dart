import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'fake_meal_plan_api.dart';

MealPlanSlot _slot(String key, String mealTime, int order, String time) =>
    MealPlanSlot(
      id: 'slot-$key',
      slotDate: DateTime(2026, 11, 3),
      mealTime: mealTime,
      dishes: const [],
      slotKey: key,
      label: 'Nhãn $key',
      scheduledTime: time,
      sortOrder: order,
    );

void main() {
  test('mapper đọc slotKey/label/giờ/thứ tự; thiếu slotKey thì = mealTime',
      () {
    final custom = MealPlanMapper.slotFromJson(<String, dynamic>{
      'id': 's1',
      'slotDate': '2026-11-03',
      'mealTime': 'SNACK',
      'dishes': <dynamic>[],
      'slotKey': 'CUSTOM_1',
      'label': 'Ăn xế',
      'scheduledTime': '15:00:00',
      'sortOrder': 3,
    });
    expect(custom.slotKey, 'CUSTOM_1');
    expect(custom.label, 'Ăn xế');
    expect(custom.scheduledTime, '15:00:00');
    expect(custom.sortOrder, 3);

    final legacy = MealPlanMapper.slotFromJson(<String, dynamic>{
      'id': 's2',
      'slotDate': '2026-11-03',
      'mealTime': 'LUNCH',
    });
    expect(legacy.slotKey, 'LUNCH');
    expect(legacy.copyWith(dishes: const []).slotKey, 'LUNCH');
  });

  test('2 bữa tự đặt cùng ngày không đè nhau, slotsOfDay theo thứ tự',
      () async {
    final api = FakeMealPlanApi()
      ..onGetWeek = (_) async => MealPlanDto(
            id: 'p',
            householdId: 'h',
            weekStart: DateTime(2026, 11, 2),
            slots: <MealPlanSlot>[
              _slot('CUSTOM_2', 'SNACK', 4, '21:00:00'),
              _slot('BREAKFAST', 'BREAKFAST', 1, '07:00:00'),
              _slot('CUSTOM_1', 'SNACK', 2, '10:00:00'),
              _slot('DINNER', 'DINNER', 3, '18:00:00'),
            ],
          );
    final store =
        MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
    await store.loadWeekPlan();

    expect(store.slots.length, 4);
    expect(
      store.slotsOfDay(DateTime(2026, 11, 3)).map((s) => s.slotKey),
      <String>['BREAKFAST', 'CUSTOM_1', 'DINNER', 'CUSTOM_2'],
    );
    expect(store.slotsOfDay(DateTime(2026, 11, 4)), isEmpty);
  });
}
