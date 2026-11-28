import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/shopping_list_sink.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/widgets/missing_ingredients_prompt.dart';

import '../../helpers/pump_app.dart';

class _RecordingSink implements ShoppingListSink {
  final List<List<IngredientItem>> calls = <List<IngredientItem>>[];

  @override
  Future<int> addItems(List<IngredientItem> items) async {
    calls.add(items);
    return items.length;
  }
}

void main() {
  final l10n = AppLocalizationsVi();
  const missing = <IngredientItem>[
    IngredientItem(name: 'Bánh phở', quantity: 500, unit: 'g'),
  ];

  Future<void> pumpTrigger(
    WidgetTester tester,
    List<IngredientItem> items,
    ShoppingListSink sink,
  ) async {
    await tester.pumpAppWidget(Builder(
      builder: (context) => TextButton(
        onPressed: () =>
            confirmAddMissingToShopping(context, missing: items, sink: sink),
        child: const Text('chon'),
      ),
    ));
    await tester.tap(find.text('chon'));
    await tester.pumpAndSettle();
  }

  testWidgets('đồng ý thì đẩy nguyên liệu thiếu sang đi chợ', (tester) async {
    final sink = _RecordingSink();
    await pumpTrigger(tester, missing, sink);
    expect(find.text(l10n.mealPlanMissingTitle), findsOneWidget);
    expect(find.textContaining('Bánh phở — 500 g'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey<String>('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(sink.calls.single.single.name, 'Bánh phở');
    expect(find.text(l10n.mealPlanMissingAdded(1)), findsOneWidget);
  });

  testWidgets('huỷ thì không đẩy gì', (tester) async {
    final sink = _RecordingSink();
    await pumpTrigger(tester, missing, sink);
    await tester
        .tap(find.byKey(const ValueKey<String>('confirm-dialog-cancel')));
    await tester.pumpAndSettle();
    expect(sink.calls, isEmpty);
  });

  testWidgets('không thiếu gì thì không hiện popup', (tester) async {
    final sink = _RecordingSink();
    await pumpTrigger(tester, const <IngredientItem>[], sink);
    expect(find.text(l10n.mealPlanMissingTitle), findsNothing);
  });
}
