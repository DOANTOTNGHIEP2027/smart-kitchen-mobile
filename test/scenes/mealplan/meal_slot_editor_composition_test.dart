import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_attendance_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_composition.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/scenes/meal_slot_editor_scene.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_composition_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_plan_store.dart';

import 'fake_meal_plan_api.dart';
import 'meal_composition_store_test.dart' show FakeCompositionApi;

class _Attendance extends Mock implements MealAttendanceApi {}

const _names = <String>['Cơm trắng', 'Thịt kho', 'Rau muống xào'];
const _roles = <String>['STAPLE', 'MAIN', 'VEGETABLE'];

ComposedMeal _menu() => ComposedMeal.fromJson(<String, dynamic>{
      'warnings': <String>[],
      'missingIngredients': <dynamic>[],
      'totalCalories': 820,
      'dishes': <dynamic>[
        for (var i = 0; i < 3; i++)
          <String, dynamic>{
            'role': _roles[i],
            'recipe': <String, dynamic>{'mealName': _names[i]},
            'plannedServings': 4,
            'requirements': <dynamic>[],
          },
      ],
    });

/// #201 mục 6: menu APPLIED 3 món → editor hiện 3 thẻ món (không in dòng
/// chữ trong panel), có nhãn vai trò tiếng Việt, đổi/xoá từng món.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  testWidgets('APPLIED với 3 món → 3 thẻ món + vai trò, không render trùng',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    // ListView dựng lười — đủ cao để cả 3 thẻ cùng được build.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final planApi = FakeMealPlanApi()
      ..onGetWeek = (_) async => MealPlanDto(
            id: 'p',
            householdId: 'h',
            weekStart: DateTime(2026, 11, 16),
            status: 'DRAFT',
            slots: <MealPlanSlot>[
              MealPlanSlot(
                id: 's',
                slotDate: DateTime(2026, 11, 16),
                mealTime: 'LUNCH',
                dishes: <MealPlanDish>[
                  for (var i = 0; i < 3; i++)
                    MealPlanDish(
                      id: 'd$i',
                      slotId: 's',
                      sortOrder: i + 1,
                      status: DishUiStatus.suggested,
                      recipe: AssignedRecipeSummary(
                          recipeId: 'r$i', recipeName: _names[i], source: 'AI'),
                    ),
                ],
              ),
            ],
          );
    final plans =
        MealPlanStore(api: planApi, suggestionApi: FakeMealSuggestionApi());
    await plans.loadWeekPlan();
    Get.put<MealPlanStore>(plans);
    final attendance = _Attendance();
    when(() => attendance.get('p', 's'))
        .thenAnswer((_) async => throw NetworkException());
    Get.put<MealAttendanceApi>(attendance);
    final compositionApi = FakeCompositionApi()
      ..currentContext = CompositionContext(
        1,
        const <CompositionDiner>[
          CompositionDiner('member', 'MEMBER', 'Member'),
        ],
        _menu(),
      );
    Get.put<MealCompositionStore>(MealCompositionStore(compositionApi, plans));

    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MealSlotEditorScene(
          slotId: 's', mealLabel: 'Bữa trưa', dateLabel: '16/11'),
    ));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      expect(find.byKey(ValueKey<String>('slot-dish-d$i')), findsOneWidget);
      // Tên món chỉ xuất hiện một lần (thẻ), panel không in lại.
      expect(find.text(_names[i]), findsOneWidget);
    }
    expect(find.text('Món tinh bột · 4 khẩu phần'), findsOneWidget);
    expect(find.text('Món mặn · 4 khẩu phần'), findsOneWidget);
    expect(find.text('Món rau · 4 khẩu phần'), findsOneWidget);
    // Kế hoạch chưa chốt → mỗi món có nút xoá + chọn từ công thức.
    expect(find.byTooltip('Xoá món'), findsNWidgets(3));
    expect(find.text('Chọn từ công thức'), findsNWidgets(3));
    expect(find.text('Gợi ý lại cả bữa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
