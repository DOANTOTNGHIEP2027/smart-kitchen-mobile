import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/shopping_list_sink.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/scenes/meal_suggestion_detail_scene.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/data/shopping_api.dart';
import 'package:smart_kitchen_mobile/scenes/shopping/stores/shopping_store.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';

import 'fake_meal_plan_api.dart';

class _ShoppingApi extends Mock implements ShoppingApi {}

class _ShoppingStore extends Mock implements ShoppingStore {}

class _Sink implements ShoppingListSink {
  @override
  Future<int> addItems(List<IngredientItem> items) async => 0;
}

const _a = MealSuggestion(id: 'a', recipeId: 'a', mealName: 'Saved soup');
const _b = MealSuggestion(id: 'b', recipeId: 'b', mealName: 'New soup');

Future<MealPlanStore> _open(
    WidgetTester tester, FakeMealSuggestionApi api) async {
  final plan = MealPlanStore(api: FakeMealPlanApi(), suggestionApi: api);
  plan.currentPlanIdForTesting = 'p';
  Get.put<MealPlanStore>(plan);
  Get.put<ShoppingApi>(_ShoppingApi());
  Get.put<ShoppingStore>(_ShoppingStore());
  Get.put<ShoppingListSink>(_Sink());
  await tester.pumpWidget(GetMaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    initialRoute: '/suggestions/s/d',
    getPages: [
      GetPage(
          name: '/suggestions/:slotId/:dishId',
          page: () => const MealSuggestionDetailScene())
    ],
  ));
  return plan;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(MealSuggestionDetailScene)));
AppButton _button(WidgetTester tester, String label) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, label));
Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.widgetWithText(AppButton, label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async {
    Get.reset();
  });

  testWidgets(
      'V7 UI keeps unknown across snapshots and requires explicit acknowledgment',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeMealSuggestionApi();
    api.onList = () async => [_a];
    var writes = 0;
    api.onGenerate = () async {
      writes++;
      throw NetworkException();
    };
    final plan = await _open(tester, api);
    await tester.pumpAndSettle();
    final l10n = _l10n(tester);
    await _tap(tester, l10n.mealPlanGenerateSuggestions);
    expect(find.text(l10n.mealplanOutcomeUnknown), findsOneWidget);
    expect(find.text(l10n.mealplanActionRolledBack), findsNothing);
    expect(find.text('Saved soup'), findsWidgets);
    expect(_button(tester, l10n.mealplanChooseDish).onPressed, null);
    expect(_button(tester, l10n.mealplanContinueSnapshot).onPressed, null);
    await _tap(tester, l10n.mealplanReadAgain); // Read A before server commit.
    expect(find.text(l10n.mealplanOutcomeUnknown), findsOneWidget);
    expect(_button(tester, l10n.mealplanContinueSnapshot).onPressed, isNotNull);
    api.onList = () async => [_b];
    await _tap(tester, l10n.mealplanReadAgain); // Read B after server commit.
    expect(plan.suggestions['d']?.single.id, 'b');
    expect(find.text(l10n.mealplanOutcomeUnknown), findsOneWidget);
    await _tap(tester, l10n.mealplanContinueSnapshot);
    expect(find.text(l10n.mealplanOutcomeUnknown), findsNothing);
    expect(_button(tester, l10n.mealplanChooseDish).onPressed, isNotNull);
    expect(writes, 1);
  });

  testWidgets(
      'V7 UI shows loading, empty and read error without auto generation',
      (tester) async {
    final gate = Completer<List<MealSuggestion>>();
    final api = FakeMealSuggestionApi();
    api.onList = () => gate.future;
    var writes = 0;
    api.onGenerate = () async {
      writes++;
      return [];
    };
    await _open(tester, api);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    gate.complete([]);
    await tester.pumpAndSettle();
    final l10n = _l10n(tester);
    expect(find.text(l10n.mealplanSuggestionsExhausted), findsOneWidget);
    api.onList = () async => throw NetworkException();
    await _tap(tester, l10n.mealplanReadAgain);
    expect(find.text(l10n.mealplanSuggestionsUnavailable), findsOneWidget);
    expect(writes, 0);
    api.onList = () async => [_a];
    await _tap(tester, l10n.mealplanReadAgain);
    expect(find.text('Saved soup'), findsWidgets);
    expect(writes, 0);
  });

  testWidgets(
      'V7 UI preserves unknown on failed recheck, no Continue or mutation',
      (tester) async {
    final api = FakeMealSuggestionApi();
    api.onList = () async => [_a];
    api.onGenerate = () async => throw NetworkException();
    await _open(tester, api);
    await tester.pumpAndSettle();
    final l10n = _l10n(tester);
    await _tap(tester, l10n.mealPlanGenerateSuggestions);
    api.onList = () async => throw NetworkException();
    await _tap(tester, l10n.mealplanReadAgain);
    expect(find.text(l10n.mealplanOutcomeUnknown), findsOneWidget);
    expect(_button(tester, l10n.mealplanContinueSnapshot).onPressed, null);
    expect(_button(tester, l10n.mealPlanGenerateSuggestions).onPressed, null);
    expect(find.text('Saved soup'), findsWidgets);
  });
}
