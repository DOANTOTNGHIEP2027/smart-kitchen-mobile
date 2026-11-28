import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_routes.dart';
import 'package:smart_kitchen_mobile/scenes/home/domain/upcoming_meal.dart';
import 'package:smart_kitchen_mobile/scenes/home/stores/home_store.dart';
import 'package:smart_kitchen_mobile/scenes/home/widgets/upcoming_meal_section.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';

import 'home_fixtures.dart';

class _MockMealPlanApi extends Mock implements MealPlanApi {}

MealPlanSlot _timed(
  String id,
  DateTime date,
  String mealTime,
  List<MealPlanDish> dishes, {
  String? time,
  bool? allCooked,
}) =>
    MealPlanSlot(
      id: id,
      slotDate: date,
      mealTime: mealTime,
      dishes: dishes,
      scheduledTime: time,
      allCooked: allCooked,
    );

/// R3 mục 17: bữa sắp tới theo giờ server + bữa đã nấu xong.
void main() {
  final day = DateTime(2026, 11, 28);
  final l10n = AppLocalizationsVi();

  group('selectUpcomingMeal', () {
    test('dùng scheduledTime server thay giờ mặc định theo mealTime', () {
      final p = plan([
        _timed('late', day, 'DINNER', [dish('d1', recipeId: 'r1')],
            time: '20:30:00'),
      ]);
      // Giờ mặc định DINNER 18h + 2h đã qua lúc 21h, nhưng giờ thật 20:30
      // + 2h vẫn còn.
      expect(
          selectUpcomingMeal(p, DateTime(2026, 11, 28, 21))?.slot.id, 'late');
      expect(selectUpcomingMeal(p, DateTime(2026, 11, 28, 22, 31)), isNull);
    });

    test('2 bữa phụ khác giờ: chọn đúng bữa gần nhất theo giờ server', () {
      final p = plan([
        _timed('night', day, 'SNACK', [dish('d2', recipeId: 'r2')],
            time: '21:30'),
        _timed('tea', day, 'SNACK', [dish('d1', recipeId: 'r1')],
            time: '15:00'),
      ]);
      expect(selectUpcomingMeal(p, DateTime(2026, 11, 28, 14))?.slot.id, 'tea');
      expect(selectUpcomingMeal(p, DateTime(2026, 11, 28, 17, 30))?.slot.id,
          'night');
    });

    test('bữa đã nấu xong: còn hiện trước giờ, qua giờ nhường bữa kế', () {
      final p = plan([
        _timed('lunch', day, 'LUNCH', [dish('d1', recipeId: 'r1')],
            time: '12:00', allCooked: true),
        _timed('dinner', day, 'DINNER', [dish('d2', recipeId: 'r2')],
            time: '18:00'),
      ]);
      final before = selectUpcomingMeal(p, DateTime(2026, 11, 28, 11));
      expect(before?.slot.id, 'lunch');
      expect(before?.allCooked, isTrue);
      expect(selectUpcomingMeal(p, DateTime(2026, 11, 28, 12, 30))?.slot.id,
          'dinner');
    });
  });

  group('UpcomingMealSection', () {
    late _MockMealPlanApi api;
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);

    setUp(() {
      Get.testMode = true;
      api = _MockMealPlanApi();
      Get.put<HomeStore>(HomeStore(
        mealPlanApi: api,
        clock: () => date.subtract(const Duration(minutes: 1)),
      ));
    });
    tearDown(Get.reset);

    Future<void> pump(WidgetTester tester) async {
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
        home: const Scaffold(
          body: SingleChildScrollView(child: UpcomingMealSection()),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('bữa allCooked: nhãn "Đã nấu xong", bấm món không mở nấu',
        (tester) async {
      when(() => api.getCurrent()).thenAnswer((_) async => plan([
            _timed('dinner', date, 'DINNER', [dish('d1', recipeId: 'r1')],
                time: '18:00', allCooked: true),
          ]));
      await pump(tester);

      expect(find.byKey(const ValueKey<String>('home-upcoming-all-cooked')),
          findsOneWidget);
      expect(find.text(l10n.homeUpcomingAllCooked), findsOneWidget);

      await tester.tap(find.byKey(const Key('home-upcoming-dish-d1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('dish-cooked-dialog')),
          findsOneWidget);
      expect(find.text('cooking-page'), findsNothing);
    });

    testWidgets('món chưa nấu: không có nhãn, bấm mở màn nấu', (tester) async {
      when(() => api.getCurrent()).thenAnswer((_) async => plan([
            _timed('dinner', date, 'DINNER', [dish('d1', recipeId: 'r1')],
                time: '18:00', allCooked: false),
          ]));
      await pump(tester);

      expect(find.byKey(const ValueKey<String>('home-upcoming-all-cooked')),
          findsNothing);
      await tester.tap(find.byKey(const Key('home-upcoming-dish-d1')));
      await tester.pumpAndSettle();
      expect(find.text('cooking-page'), findsOneWidget);
    });
  });
}
