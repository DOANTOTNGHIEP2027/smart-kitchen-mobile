import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mobx/mobx.dart' show runInAction;
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_routes.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_attendance_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_suggestion.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/recipe_check.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/scenes/meal_slot_editor_scene.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/scenes/weekly_meal_plan_scene.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/widgets/meal_card.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/data/recipe_catalog_api.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/domain/recipe.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/scenes/recipe_list_scene.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../recipe/fake_recipe_catalog_api.dart';
import 'fake_meal_plan_api.dart';

class _Attendance extends Mock implements MealAttendanceApi {}

final DateTime _monday = DateTime(2026, 11, 2);
final AppLocalizationsVi _l10n = AppLocalizationsVi();

MealPlanDto _plan(List<MealPlanSlot> slots) => MealPlanDto(
      id: 'p',
      householdId: 'h',
      weekStart: _monday,
      status: 'DRAFT',
      slots: slots,
    );

const AssignedRecipeSummary _oldRecipe = AssignedRecipeSummary(
    recipeId: 'r-old', recipeName: 'Canh cũ', source: 'MANUAL');

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(GetMaterialApp(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    getPages: <GetPage<dynamic>>[
      GetPage<void>(
        name: CookingRoutes.session,
        page: () => const Scaffold(body: Text('cooking-page')),
      ),
    ],
    home: home,
  ));
}

/// Pump có hạn: ảnh bìa (CachedNetworkImage) quay spinner mãi trong test.
Future<void> _settle(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    MealPlanStore.clock = () => DateTime(2026, 11, 1);
  });
  tearDown(() {
    MealPlanStore.clock = DateTime.now;
    Get.reset();
  });

  group('lịch tuần (R3 mục 16)', () {
    Future<MealPlanStore> pumpWeek(
        WidgetTester tester, List<MealPlanSlot> slots) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final session = SessionStore(TokenStorage(), AuthRefreshUseCase(Dio()));
      runInAction(() => session.householdId = 'h');
      Get.put<SessionStore>(session);
      final api = FakeMealPlanApi()..onGetWeek = (_) async => _plan(slots);
      final store =
          MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
      Get.put<MealPlanStore>(store);
      await _pumpApp(tester, const WeeklyMealPlanScene());
      await _settle(tester, frames: 3);
      return store;
    }

    testWidgets(
        'render đúng slot server: 2 bữa phụ tuỳ biến đều hiện, đúng thứ tự',
        (tester) async {
      await pumpWeek(tester, <MealPlanSlot>[
        MealPlanSlot(
            id: 'sn2',
            slotDate: _monday,
            mealTime: 'SNACK',
            slotKey: 'CUSTOM_3',
            label: 'Ăn khuya',
            scheduledTime: '21:30:00',
            sortOrder: 5,
            dishes: const <MealPlanDish>[]),
        MealPlanSlot(
            id: 'b',
            slotDate: _monday,
            mealTime: 'BREAKFAST',
            scheduledTime: '07:00',
            sortOrder: 1,
            dishes: const <MealPlanDish>[]),
        MealPlanSlot(
            id: 'sn1',
            slotDate: _monday,
            mealTime: 'SNACK',
            slotKey: 'CUSTOM_2',
            label: 'Ăn xế',
            scheduledTime: '15:00',
            sortOrder: 3,
            dishes: const <MealPlanDish>[]),
      ]);

      // Không còn cố định Sáng/Trưa/Tối: không có slot LUNCH/DINNER ⇒ không
      // vẽ thẻ trống cho chúng.
      expect(find.text('${_l10n.mealPlanBreakfast} · 07:00'), findsOneWidget);
      expect(find.text('Ăn xế · 15:00'), findsOneWidget);
      expect(find.text('Ăn khuya · 21:30'), findsOneWidget);
      expect(find.text(_l10n.mealPlanLunch), findsNothing);
      final y = <String, double>{
        for (final id in <String>['b', 'sn1', 'sn2'])
          id: tester
              .getTopLeft(find.byKey(ValueKey<String>('meal-slot-card-$id')))
              .dy,
      };
      expect(y['b']! < y['sn1']! && y['sn1']! < y['sn2']!, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bữa bị server khoá: chỉ xem, không mở màn sửa, không trợ lý',
        (tester) async {
      await pumpWeek(tester, <MealPlanSlot>[
        MealPlanSlot(
            id: 'locked',
            slotDate: _monday,
            mealTime: 'LUNCH',
            locked: true,
            dishes: const <MealPlanDish>[]),
        MealPlanSlot(
            id: 'open',
            slotDate: _monday,
            mealTime: 'DINNER',
            locked: false,
            dishes: const <MealPlanDish>[]),
      ]);

      expect(find.text(_l10n.mealPlanSlotLocked), findsOneWidget);
      expect(find.text(_l10n.mealPlanTapToAdd), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('assistant-slot-locked')),
          findsNothing);
      expect(find.byKey(const ValueKey<String>('assistant-slot-open')),
          findsOneWidget);

      await tester.tap(find.text(_l10n.mealPlanSlotLocked));
      await _settle(tester, frames: 2);
      expect(find.byType(MealSlotEditorScene), findsNothing);
    });
  });

  group('chọn món tay (R3 mục 11/12)', () {
    late FakeMealPlanApi api;
    late FakeRecipeCatalogApi recipes;

    Future<MealPlanStore> pumpEditor(
      WidgetTester tester, {
      List<MealPlanDish> dishes = const <MealPlanDish>[],
      bool? locked = false,
    }) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      api = FakeMealPlanApi();
      api.onGetWeek = (_) async => _plan(<MealPlanSlot>[
            MealPlanSlot(
                id: 's',
                slotDate: _monday,
                mealTime: 'LUNCH',
                locked: locked,
                dishes: dishes),
          ]);
      api.onAddDish = (_, slotId) async => MealPlanDish(
          id: 'd-new',
          slotId: slotId,
          sortOrder: 9,
          status: DishUiStatus.empty);
      api.onRemoveDish = (_, __, ___) async {};
      api.onAssignDishRecipe = (_, slotId, dishId,
              {required recipeId, required recipeName}) async =>
          MealPlanDish(
            id: dishId,
            slotId: slotId,
            sortOrder: 0,
            status: DishUiStatus.confirmed,
            recipe: AssignedRecipeSummary(
                recipeId: recipeId, recipeName: recipeName, source: 'MANUAL'),
          );
      final store =
          MealPlanStore(api: api, suggestionApi: FakeMealSuggestionApi());
      await store.loadWeekPlan();
      api.calls.clear();
      Get.put<MealPlanStore>(store);
      final attendance = _Attendance();
      when(() => attendance.get('p', 's'))
          .thenAnswer((_) async => throw NetworkException());
      Get.put<MealAttendanceApi>(attendance);
      recipes = FakeRecipeCatalogApi();
      recipes.onList = (_) async =>
          recipePage(<Recipe>[buildRecipe('r9', name: 'Canh tôm')]);
      Get.put<RecipeCatalogApi>(recipes);
      await _pumpApp(
        tester,
        const MealSlotEditorScene(
            slotId: 's', mealLabel: 'Bữa trưa', dateLabel: '02/11'),
      );
      await _settle(tester, frames: 2);
      return store;
    }

    RecipeCheckResult check({
      bool allergy = true,
      bool missing = true,
      bool verified = false,
    }) =>
        RecipeCheckResult(
          recipeId: 'r9',
          allergenVerified: verified,
          allergenConflicts: allergy
              ? const <RecipeAllergenConflict>[
                  RecipeAllergenConflict(
                    personType: 'DEPENDENT',
                    personId: 'dep',
                    name: 'Bé Na',
                    allergens: <RecipeCheckAllergen>[
                      RecipeCheckAllergen(id: 'a', name: 'Tôm'),
                    ],
                  ),
                ]
              : const <RecipeAllergenConflict>[],
          missingIngredients: missing
              ? const <IngredientItem>[
                  IngredientItem(name: 'Tôm', quantity: 200, unit: 'g'),
                ]
              : const <IngredientItem>[],
        );

    Future<void> pickRecipeForNewDish(WidgetTester tester) async {
      await tester.tap(find.text(_l10n.mealPlanAddDish));
      await _settle(tester, frames: 2);
      await tester
          .tap(find.byKey(const ValueKey<String>('dish-source-recipe')));
      await _settle(tester, frames: 3);
      await tester
          .tap(find.byKey(const ValueKey<String>('${kRecipeCardKeyPrefix}r9')));
      await _settle(tester, frames: 3);
    }

    testWidgets('thứ tự: dị ứng → thiếu nguyên liệu → xác nhận mới tạo + gán',
        (tester) async {
      final store = await pumpEditor(tester);
      api.onRecipeCheck = (_, __, ___) async => check();

      await pickRecipeForNewDish(tester);
      // Bước 1: chỉ mới kiểm tra (chỉ đọc), CHƯA tạo món.
      expect(find.byKey(const ValueKey<String>('allergen-conflict-dialog')),
          findsOneWidget);
      expect(find.text('Bé Na: Tôm'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('allergen-conflict-unverified')),
          findsOneWidget);
      expect(api.calls, <String>['recipeCheck:s:r9']);

      await tester.tap(
          find.byKey(const ValueKey<String>('allergen-conflict-continue')));
      await _settle(tester, frames: 2);
      // Bước 2: hỏi nguyên liệu thiếu, vẫn chưa tạo món.
      expect(find.byKey(const ValueKey<String>('missing-choice-dialog')),
          findsOneWidget);
      expect(find.text(_l10n.mealPlanMissingAddWithShopping), findsOneWidget);
      expect(api.calls, <String>['recipeCheck:s:r9']);

      await tester
          .tap(find.byKey(const ValueKey<String>('missing-choice-add-only')));
      await _settle(tester, frames: 3);
      expect(api.calls, <String>[
        'recipeCheck:s:r9',
        'addDish:s',
        'assign:d-new:r9',
      ]);
      expect(store.slots['s']!.dishes.single.recipe?.recipeId, 'r9');
    });

    for (final step in <String>['allergy', 'missing']) {
      testWidgets('huỷ ở bước $step ⇒ không tạo/gán/xoá món nào',
          (tester) async {
        final store = await pumpEditor(tester);
        api.onRecipeCheck = (_, __, ___) async => check();

        await pickRecipeForNewDish(tester);
        if (step == 'missing') {
          await tester.tap(
              find.byKey(const ValueKey<String>('allergen-conflict-continue')));
          await _settle(tester, frames: 2);
          await tester
              .tap(find.byKey(const ValueKey<String>('missing-choice-cancel')));
        } else {
          await tester.tap(
              find.byKey(const ValueKey<String>('allergen-conflict-cancel')));
        }
        await _settle(tester, frames: 2);

        expect(api.calls, <String>['recipeCheck:s:r9']);
        expect(store.slots['s']!.dishes, isEmpty);
      });
    }

    testWidgets('đóng sheet chọn cách thêm ⇒ không tạo món rỗng',
        (tester) async {
      await pumpEditor(tester);
      await tester.tap(find.text(_l10n.mealPlanAddDish));
      await _settle(tester, frames: 2);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester, frames: 2);
      expect(api.calls, isEmpty);
    });

    testWidgets('đổi công thức món đang có, huỷ ⇒ giữ công thức cũ',
        (tester) async {
      final store = await pumpEditor(tester, dishes: const <MealPlanDish>[
        MealPlanDish(
            id: 'd1',
            slotId: 's',
            sortOrder: 0,
            status: DishUiStatus.confirmed,
            recipe: _oldRecipe),
      ]);
      api.onRecipeCheck = (_, __, ___) async => check(allergy: false);

      await tester.tap(find.text(_l10n.mealPlanChooseRecipe));
      await _settle(tester, frames: 3);
      await tester
          .tap(find.byKey(const ValueKey<String>('${kRecipeCardKeyPrefix}r9')));
      await _settle(tester, frames: 3);
      // Không có dị ứng ⇒ vào thẳng bước nguyên liệu thiếu.
      expect(find.byKey(const ValueKey<String>('allergen-conflict-dialog')),
          findsNothing);
      await tester
          .tap(find.byKey(const ValueKey<String>('missing-choice-cancel')));
      await _settle(tester, frames: 2);

      expect(api.calls, <String>['recipeCheck:s:r9']);
      expect(store.slots['s']!.dishes.single.recipe?.recipeId, 'r-old');
    });

    testWidgets('server cũ chưa có recipe-check ⇒ bỏ qua, gán như cũ',
        (tester) async {
      final store = await pumpEditor(tester);
      // onRecipeCheck null ⇒ fake ném ERR_NOT_FOUND (endpoint không có).
      await pickRecipeForNewDish(tester);

      expect(api.calls, <String>[
        'recipeCheck:s:r9',
        'addDish:s',
        'assign:d-new:r9',
      ]);
      expect(store.slots['s']!.dishes.single.recipe?.recipeId, 'r9');
    });

    testWidgets('gán lỗi sau khi tạo ⇒ xoá món vừa tạo', (tester) async {
      final store = await pumpEditor(tester);
      api.onRecipeCheck =
          (_, __, ___) async => check(allergy: false, missing: false);
      api.onAssignDishRecipe = (_, __, ___,
              {required recipeId, required recipeName}) async =>
          throw BusinessException('ERR_PLAN_DISH_NOT_FOUND', 'x');

      await pickRecipeForNewDish(tester);

      expect(api.calls, <String>[
        'recipeCheck:s:r9',
        'addDish:s',
        'assign:d-new:r9',
        'removeDish:d-new',
      ]);
      expect(store.slots['s']!.dishes, isEmpty);
    });

    testWidgets('bữa đã khoá: không nút thêm/chọn/xoá món', (tester) async {
      await pumpEditor(tester, locked: true, dishes: const <MealPlanDish>[
        MealPlanDish(
            id: 'd1',
            slotId: 's',
            sortOrder: 0,
            status: DishUiStatus.confirmed,
            recipe: _oldRecipe),
      ]);
      final add = tester.widget<FilledButton>(find.ancestor(
          of: find.text(_l10n.mealPlanAddDish),
          matching: find.byWidgetPredicate((w) => w is FilledButton)));
      expect(add.onPressed, isNull);
      expect(find.text(_l10n.mealPlanChooseRecipe), findsNothing);
      final delete = tester.widget<IconButton>(find.ancestor(
          of: find.byIcon(Icons.delete_outline_rounded),
          matching: find.byType(IconButton)));
      expect(delete.onPressed, isNull);
    });
  });

  group('món đã nấu (R3 mục 10)', () {
    MealPlanDish dishOf({DateTime? cookedAt}) => MealPlanDish(
          id: 'd1',
          slotId: 's',
          sortOrder: 0,
          status: DishUiStatus.confirmed,
          recipe: const AssignedRecipeSummary(
              recipeId: 'r1', recipeName: 'Canh chua', source: 'MANUAL'),
          cookedAt: cookedAt,
        );

    Future<void> openSheet(WidgetTester tester, MealPlanDish dish) async {
      await _pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Get.bottomSheet<void>(
                ConfirmedDishSheet(dish: dish, onRemove: () async {}),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('món đã nấu: badge + bấm nấu ⇒ dialog, không mở màn nấu',
        (tester) async {
      await openSheet(tester, dishOf(cookedAt: DateTime(2026, 11, 2, 12, 5)));
      expect(find.byKey(const ValueKey<String>('dish-cooked-badge')),
          findsOneWidget);

      await tester.tap(find.text(_l10n.mealplanStartCooking));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('dish-cooked-dialog')),
          findsOneWidget);
      expect(find.text(_l10n.dishCookedMessageAt('12:05', '02/11')),
          findsOneWidget);
      expect(find.text('cooking-page'), findsNothing);
    });

    testWidgets('món chưa nấu: bấm nấu ⇒ mở màn nấu', (tester) async {
      await openSheet(tester, dishOf());
      expect(find.byKey(const ValueKey<String>('dish-cooked-badge')),
          findsNothing);

      await tester.tap(find.text(_l10n.mealplanStartCooking));
      await tester.pumpAndSettle();

      expect(find.text('cooking-page'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('dish-cooked-dialog')),
          findsNothing);
    });
  });
}
