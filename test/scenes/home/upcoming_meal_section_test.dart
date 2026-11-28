import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_routes.dart';
import 'package:smart_kitchen_mobile/scenes/home/stores/home_store.dart';
import 'package:smart_kitchen_mobile/scenes/home/widgets/upcoming_meal_section.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';

import 'home_fixtures.dart';

class _MockMealPlanApi extends Mock implements MealPlanApi {}

void main() {
  late _MockMealPlanApi mealPlanApi;
  late AppShellStore shell;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    Get.testMode = true;
    mealPlanApi = _MockMealPlanApi();
    shell = AppShellStore();
    Get.put<AppShellStore>(shell);
    Get.put<HomeStore>(HomeStore(
      mealPlanApi: mealPlanApi,
      // Cố định cuối ngày trước → mọi slot của hôm nay đều "sắp tới".
      clock: () => today.subtract(const Duration(minutes: 1)),
    ));
    when(() => mealPlanApi.getCurrent()).thenAnswer((_) async => plan([
          slot('dinner', today, 'DINNER', [dish('d1', recipeId: 'r1')]),
        ]));
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

  testWidgets('hiển thị bữa sắp tới và món', (tester) async {
    await pump(tester);

    expect(find.text('Bữa sắp tới'), findsOneWidget);
    expect(find.text('Tối · Hôm nay'), findsOneWidget);
    expect(find.text('Món r1'), findsOneWidget);
  });

  testWidgets('bấm món → qua guard rồi mở màn nấu', (tester) async {
    // Không có SessionStore/nhà → guard không kiểm được, vào nấu luôn.
    await pump(tester);

    await tester.tap(find.byKey(const Key('home-upcoming-dish-d1')));
    await tester.pumpAndSettle();

    expect(find.text('cooking-page'), findsOneWidget);
  });

  testWidgets('không có bữa → empty + nút lên thực đơn', (tester) async {
    when(() => mealPlanApi.getCurrent()).thenAnswer((_) async => plan([]));
    when(() => mealPlanApi.getWeek(any())).thenAnswer((_) async => plan([]));
    await pump(tester);

    await tester.tap(find.text('Lên thực đơn'));
    await tester.pump();

    expect(shell.selectedIndex, 2);
  });

  testWidgets('lỗi tải → error view', (tester) async {
    when(() => mealPlanApi.getCurrent()).thenThrow(NetworkException());
    await pump(tester);

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('Món r1'), findsNothing);
  });
}
