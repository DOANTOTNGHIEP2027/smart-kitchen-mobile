import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_shopping_sync.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/widgets/missing_ingredients_prompt.dart';

import '../../helpers/pump_app.dart';

class _FakeSync implements MealShoppingSync {
  _FakeSync(this.lines);
  final List<SlotShoppingLine>? lines;
  final List<(String, List<IngredientItem>)> added = <(String, List<IngredientItem>)>[];
  final List<String> removed = <String>[];
  (DateTime, String)? asked;

  @override
  Future<List<SlotShoppingLine>?> linesOfSlot(DateTime slotDate, String mealTime) async {
    asked = (slotDate, mealTime);
    return lines;
  }

  @override
  Future<int> addForDish(String dishId, List<IngredientItem> items) async {
    added.add((dishId, items));
    return items.length;
  }

  @override
  Future<int> remove(List<String> ids) async {
    removed.addAll(ids);
    return ids.length;
  }
}

MealPlanDish _dish(String id, String recipeId, String recipeName) => MealPlanDish(
      id: id,
      slotId: 's1',
      sortOrder: 0,
      status: DishUiStatus.confirmed,
      recipe: AssignedRecipeSummary(recipeId: recipeId, recipeName: recipeName, source: 'MANUAL'),
    );

SlotShoppingLine _line(String id, String dishId,
        {String? recipeName, bool bought = false, String name = 'Hành'}) =>
    SlotShoppingLine(
      id: id,
      dishId: dishId,
      recipeName: recipeName,
      name: name,
      quantity: 1,
      unit: 'cu',
      bought: bought,
    );

void main() {
  final l10n = AppLocalizationsVi();
  final date = DateTime.utc(2026, 11, 28);
  const pho = <IngredientItem>[IngredientItem(name: 'Bánh phở', quantity: 500, unit: 'g')];

  bool? result;
  setUp(() => result = null);

  Future<void> pumpFinish(
    WidgetTester tester,
    _FakeSync sync,
    List<MealPlanDish> dishes, {
    List<IngredientItem> missing = pho,
  }) async {
    await tester.pumpAppWidget(Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await finishSlotShopping(
          context,
          slotDate: date,
          mealTime: 'LUNCH',
          dishes: dishes,
          sync: sync,
          missingOf: (_) async => missing,
        ),
        child: const Text('xong'),
      ),
    ));
    await tester.tap(find.text('xong'));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('món chưa có dòng đi chợ → hỏi rồi đẩy đồ thiếu, gắn đúng món', (tester) async {
    final sync = _FakeSync(const <SlotShoppingLine>[]);
    await pumpFinish(tester, sync, <MealPlanDish>[_dish('d1', 'r1', 'Phở')]);
    expect(sync.asked, (date, 'LUNCH'));
    expect(find.text(l10n.mealPlanFinishTitle), findsOneWidget);
    expect(find.textContaining('Bánh phở — 500 g'), findsOneWidget);
    await confirm(tester);
    expect(sync.added.single.$1, 'd1');
    expect(sync.added.single.$2.single.name, 'Bánh phở');
    expect(sync.removed, isEmpty);
    expect(find.text(l10n.mealPlanFinishDone(1, 0)), findsOneWidget);
  });

  testWidgets('món đã xoá: xoá dòng CHƯA MUA, giữ dòng đã mua', (tester) async {
    final sync = _FakeSync(<SlotShoppingLine>[
      _line('i1', 'gone', name: 'Thịt bò'),
      _line('i2', 'gone', bought: true, name: 'Gừng'),
    ]);
    await pumpFinish(tester, sync, const <MealPlanDish>[]);
    expect(find.textContaining('Thịt bò'), findsOneWidget);
    expect(find.textContaining('Gừng'), findsNothing);
    await confirm(tester);
    expect(sync.removed, <String>['i1']);
    expect(sync.added, isEmpty);
  });

  testWidgets('món đã có dòng (kể cả đã mua) → không đẩy lại', (tester) async {
    final sync = _FakeSync(<SlotShoppingLine>[
      _line('i1', 'd1', recipeName: 'Phở', bought: true),
    ]);
    await pumpFinish(tester, sync, <MealPlanDish>[_dish('d1', 'r1', 'Phở')]);
    expect(find.text(l10n.mealPlanFinishTitle), findsNothing);
    expect(find.text(l10n.mealPlanFinishInSync), findsOneWidget);
    expect(sync.added, isEmpty);
    expect(result, isTrue);
  });

  testWidgets('món đổi công thức → xoá dòng cũ chưa mua, đẩy đồ của công thức mới', (tester) async {
    final sync = _FakeSync(<SlotShoppingLine>[_line('i1', 'd1', recipeName: 'Bún')]);
    await pumpFinish(tester, sync, <MealPlanDish>[_dish('d1', 'r1', 'Phở')]);
    await confirm(tester);
    expect(sync.removed, <String>['i1']);
    expect(sync.added.single.$1, 'd1');
  });

  testWidgets('huỷ thì không đổi gì, ở lại màn', (tester) async {
    final sync = _FakeSync(<SlotShoppingLine>[_line('i1', 'gone')]);
    await pumpFinish(tester, sync, <MealPlanDish>[_dish('d1', 'r1', 'Phở')]);
    await tester.tap(find.byKey(const ValueKey<String>('confirm-dialog-cancel')));
    await tester.pumpAndSettle();
    expect(sync.added, isEmpty);
    expect(sync.removed, isEmpty);
    expect(result, isFalse);
  });

  testWidgets('không tải được đi chợ → báo lỗi, không đoán, ở lại màn', (tester) async {
    final sync = _FakeSync(null);
    await pumpFinish(tester, sync, <MealPlanDish>[_dish('d1', 'r1', 'Phở')]);
    expect(find.text(l10n.mealPlanFinishLoadFailed), findsOneWidget);
    expect(sync.added, isEmpty);
    expect(result, isFalse);
  });
}
