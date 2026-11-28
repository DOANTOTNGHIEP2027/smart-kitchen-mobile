
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/scenes/home/stores/home_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/data/recipe_catalog_api.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';

import '../../helpers/pump_app.dart';
import '../recipe/fake_recipe_catalog_api.dart';

class _MockMealPlanApi extends Mock implements MealPlanApi {}

void main() {
  final l10n = AppLocalizationsVi();
  late FakeRecipeCatalogApi api;

  setUp(() {
    api = FakeRecipeCatalogApi();
    Get.put<RecipeCatalogApi>(api);
    // HomeTab có khung "Bữa sắp tới" — cần HomeStore; lỗi tải không ảnh hưởng
    // các phần khác của Home đang được test ở đây.
    final mealPlanApi = _MockMealPlanApi();
    when(mealPlanApi.getCurrent).thenThrow(NetworkException());
    Get.put<HomeStore>(HomeStore(mealPlanApi: mealPlanApi));
  });
  tearDown(Get.reset);

  for (final width in [320.0, 375.0, 800.0]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('Home: đủ nhãn hành động ở rộng $width, cỡ chữ $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, width == 800 ? 375 : 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpAppWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const HomeTab(),
          ),
          wrapInScaffold: false,
        );
        await tester.pumpAndSettle();
        for (final label in [
          l10n.homeStartCooking,
          l10n.homeStartCookingSubtitle,
          l10n.homeInventoryTitle,
          l10n.homeInventorySubtitle,
          l10n.homeMealPlanTitle,
          l10n.homeMealPlanSubtitle,
          l10n.navShopping,
          l10n.homeShoppingSubtitle,
          l10n.mealLogTitle,
          l10n.homeMealLogSubtitle,
        ]) {
          final text = find.text(label);
          // Khung "Bữa sắp tới" đẩy phần này xuống ngoài vùng ListView dựng
          // sẵn — phải cuộn tới, ensureVisible không thấy widget chưa dựng.
          await tester.scrollUntilVisible(text, 100,
              scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          expect(tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
              isFalse,
              reason: label);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('trang chủ không còn danh sách công thức, không gọi catalog',
      (tester) async {
    await tester.pumpAppWidget(const HomeTab(), wrapInScaffold: false);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(l10n.homeMealLogSubtitle), 100,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text(l10n.recipesTitle), findsNothing);
    expect(find.text(l10n.homeRecommendedMeals), findsNothing);
    expect(api.listCalls, isEmpty);
  });
}
