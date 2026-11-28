import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';

import 'fake_meal_plan_api.dart';

final DateTime _monday = DateTime(2026, 11, 2);

MealPlanSlot _slot(
  String id, {
  String mealTime = 'SNACK',
  String? slotKey,
  String? label,
  String? time,
  int? sortOrder,
  bool? locked,
  DateTime? date,
  List<MealPlanDish> dishes = const <MealPlanDish>[],
}) =>
    MealPlanSlot(
      id: id,
      slotDate: date ?? _monday,
      mealTime: mealTime,
      dishes: dishes,
      slotKey: slotKey,
      label: label,
      scheduledTime: time,
      sortOrder: sortOrder,
      locked: locked,
    );

MealPlanDto _plan(List<MealPlanSlot> slots) => MealPlanDto(
      id: 'p',
      householdId: 'h',
      weekStart: _monday,
      status: 'DRAFT',
      slots: slots,
    );

/// R3 mục 10/16: slot theo danh sách server (slotKey/label/giờ/thứ tự), khoá
/// theo cờ `locked`, món đã nấu (`cookedAt`).
void main() {
  setUp(() => MealPlanStore.clock = () => DateTime(2026, 11, 1));
  tearDown(() => MealPlanStore.clock = DateTime.now);

  group('mapper', () {
    test('slot đọc field mới; server cũ thiếu field ⇒ null', () {
      final slot = MealPlanMapper.slotFromJson(<String, dynamic>{
        'id': 's',
        'slotDate': '2026-11-02',
        'mealTime': 'SNACK',
        'slotKey': 'CUSTOM_2',
        'label': 'Ăn khuya',
        'scheduledTime': '21:30:00',
        'sortOrder': 4,
        'locked': true,
        'allCooked': false,
        'dishes': <dynamic>[
          <String, dynamic>{
            'id': 'd',
            'slotId': 's',
            'status': 'CONFIRMED',
            'cookedAt': '2026-11-02T14:30:00Z',
            'cookedSessionId': 'cs-1',
          },
        ],
      });
      expect(slot.slotKey, 'CUSTOM_2');
      expect(slot.label, 'Ăn khuya');
      expect(slot.scheduledMinutes, 21 * 60 + 30);
      expect(slot.sortOrder, 4);
      expect(slot.locked, isTrue);
      expect(slot.allCooked, isFalse);
      expect(slot.dishes.single.isCooked, isTrue);
      expect(slot.dishes.single.cookedAt!.toUtc(),
          DateTime.utc(2026, 11, 2, 14, 30));
      expect(slot.dishes.single.cookedSessionId, 'cs-1');

      final old = MealPlanMapper.slotFromJson(<String, dynamic>{
        'id': 's',
        'slotDate': '2026-11-02',
        'mealTime': 'LUNCH',
      });
      expect(old.slotKey, isNull);
      expect(old.label, isNull);
      expect(old.scheduledMinutes, isNull);
      expect(old.locked, isNull);
      expect(old.allCooked, isNull);
    });

    test('recipe-check: dị ứng theo người + thiếu nguyên liệu', () {
      final check = MealPlanMapper.recipeCheckFromJson(<String, dynamic>{
        'recipeId': 'r',
        'allergenVerified': false,
        'allergenConflicts': <dynamic>[
          <String, dynamic>{
            'personType': 'DEPENDENT',
            'personId': 'dep-1',
            'name': 'Bé Na',
            'allergens': <dynamic>[
              <String, dynamic>{'id': 'a1', 'name': 'Tôm'},
              <String, dynamic>{'id': null, 'name': 'Cua'},
            ],
          },
        ],
        'missingIngredients': <dynamic>[
          <String, dynamic>{
            'ingredientName': 'Tôm',
            'shortfallQuantity': 200,
            'unit': 'GRAM',
          },
        ],
      });
      expect(check.allergenVerified, isFalse);
      final person = check.allergenConflicts.single;
      expect(person.personType, 'DEPENDENT');
      expect(person.name, 'Bé Na');
      expect(person.allergens.map((a) => a.name), <String>['Tôm', 'Cua']);
      expect(person.allergens.last.id, isNull);
      expect(check.missingIngredients.single.unit, 'g');
    });
  });

  group('store', () {
    test('2 bữa SNACK tuỳ biến cùng ngày đều giữ, sắp theo sortOrder',
        () async {
      final api = FakeMealPlanApi()
        ..onGetWeek = (_) async => _plan(<MealPlanSlot>[
              _slot('sn2', label: 'Ăn khuya', time: '21:30', sortOrder: 5),
              _slot('b',
                  mealTime: 'BREAKFAST', label: 'Bữa sáng', sortOrder: 1),
              _slot('sn1', label: 'Ăn xế', time: '15:00', sortOrder: 3),
            ]);
      final store =
          MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
      await store.loadWeekPlan();

      expect(store.slots.length, 3);
      expect(store.slotsOfDate(_monday).map((s) => s.id),
          <String>['b', 'sn1', 'sn2']);
      expect(store.slotKeyOf('sn1'), 'sn1');
    });

    test('thiếu sortOrder ⇒ sắp theo giờ rồi theo mealTime', () async {
      final api = FakeMealPlanApi()
        ..onGetWeek = (_) async => _plan(<MealPlanSlot>[
              _slot('d', mealTime: 'DINNER'),
              _slot('l', mealTime: 'LUNCH'),
              _slot('b', mealTime: 'BREAKFAST'),
            ]);
      final store =
          MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
      await store.loadWeekPlan();
      expect(
          store.slotsOfDate(_monday).map((s) => s.id), <String>['b', 'l', 'd']);
    });

    test('cờ locked server thắng luật ngày; thiếu cờ ⇒ fallback ngày',
        () async {
      MealPlanStore.clock = () => DateTime(2026, 11, 3);
      final api = FakeMealPlanApi()
        ..onGetWeek = (_) async => _plan(<MealPlanSlot>[
              // Ngày đã qua nhưng server nói chưa khoá.
              _slot('pastOpen', locked: false),
              // Ngày tương lai nhưng server đã khoá (đã nấu món).
              _slot('futureLocked',
                  locked: true,
                  date: DateTime(2026, 11, 5),
                  dishes: const <MealPlanDish>[
                    MealPlanDish(
                        id: 'dl',
                        slotId: 'futureLocked',
                        sortOrder: 0,
                        status: DishUiStatus.confirmed),
                  ]),
              _slot('pastOld'),
            ]);
      final store =
          MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
      await store.loadWeekPlan();

      expect(store.isSlotLocked('pastOpen'), isFalse);
      expect(store.isSlotLocked('futureLocked'), isTrue);
      expect(store.isSlotLocked('pastOld'), isTrue);
      expect(store.canEditDish('dl'), isFalse);
      expect(await store.addDish('futureLocked'), isNull);
      expect(api.calls, isEmpty);
    });

    test('409 ERR_PLAN_SLOT_LOCKED ⇒ đánh dấu khoá, báo tick, tải lại plan',
        () async {
      var reads = 0;
      final api = FakeMealPlanApi()
        ..onGetWeek = ((_) async => _plan(<MealPlanSlot>[_slot('s')]))
        ..onGetById = (_) async {
          reads++;
          return _plan(<MealPlanSlot>[_slot('s', locked: true)]);
        }
        ..onAddDish = (_, __) async =>
            throw BusinessException('ERR_PLAN_SLOT_LOCKED', 'locked');
      final store =
          MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
      await store.loadWeekPlan();
      expect(store.isSlotLocked('s'), isFalse);

      expect(await store.addDish('s'), isNull);
      expect(store.isSlotLocked('s'), isTrue);
      expect(store.slotLockedTick, 1);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(reads, 1);
      expect(store.slots['s']!.locked, isTrue);
    });

    test('recipe-check server cũ (404) ⇒ null; lỗi mạng ném lại', () async {
      final api = FakeMealPlanApi()
        ..onGetWeek = (_) async => _plan(<MealPlanSlot>[_slot('s')]);
      final store =
          MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
      await store.loadWeekPlan();

      expect(await store.recipeCheck('s', 'r'), isNull);
      api.onRecipeCheck = (_, __, ___) async => throw NetworkException();
      expect(
          () => store.recipeCheck('s', 'r'), throwsA(isA<NetworkException>()));
    });

    test('isAllCooked: cờ server, thiếu cờ thì suy từ cookedAt', () {
      MealPlanDish cooked(String id, {DateTime? at}) => MealPlanDish(
            id: id,
            slotId: 's',
            sortOrder: 0,
            status: DishUiStatus.confirmed,
            recipe: const AssignedRecipeSummary(
                recipeId: 'r', recipeName: 'Canh', source: 'MANUAL'),
            cookedAt: at,
          );
      final at = DateTime(2026, 11, 2, 12);
      expect(
          _slot('s', dishes: <MealPlanDish>[cooked('a', at: at)]).isAllCooked,
          isTrue);
      expect(
          _slot('s', dishes: <MealPlanDish>[cooked('a', at: at), cooked('b')])
              .isAllCooked,
          isFalse);
      expect(_slot('s').isAllCooked, isFalse);
      expect(
          MealPlanSlot(
                  id: 's',
                  slotDate: _monday,
                  mealTime: 'LUNCH',
                  dishes: const <MealPlanDish>[],
                  allCooked: true)
              .isAllCooked,
          isTrue);
    });
  });
}
