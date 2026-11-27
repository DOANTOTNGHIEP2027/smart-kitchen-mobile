import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/domain/recipe.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/scenes/recipe_detail_scene.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/scenes/recipe_list_scene.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/stores/recipe_detail_store.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/stores/recipe_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_empty_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';

import '../../helpers/pump_app.dart';
import 'fake_recipe_catalog_api.dart';

/// Widget test 4 trạng thái loading / empty / error / success (#80).
void main() {
  final l10n = AppLocalizationsVi();
  late FakeRecipeCatalogApi api;

  setUp(() => api = FakeRecipeCatalogApi());
  tearDown(Get.reset);

  group('RecipeListScene', () {
    Future<void> pumpList(WidgetTester tester) async {
      Get.put<RecipeStore>(RecipeStore(api));
      await tester.pumpAppWidget(const RecipeListScene(), wrapInScaffold: false);
    }

    testWidgets('loading: lần tải đầu hiện AppLoadingView', (tester) async {
      final gate = Completer<RecipePage>();
      api.onList = (_) => gate.future;
      await pumpList(tester);
      await tester.pump();

      expect(find.byType(AppLoadingView), findsOneWidget);
      expect(api.listCalls.single.page, 0);

      gate.complete(recipePage(const <Recipe>[]));
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingView), findsNothing);
    });

    testWidgets('empty: tab Tất cả → recipesNoResults', (tester) async {
      await pumpList(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyView), findsOneWidget);
      expect(find.text(l10n.recipesNoResults), findsOneWidget);
    });

    testWidgets('empty: tab Yêu thích → recipesNoFavorites', (tester) async {
      await pumpList(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.recipesFavorites));
      await tester.pumpAndSettle();

      expect(api.favoritesPages, <int>[0]);
      expect(find.text(l10n.recipesNoFavorites), findsOneWidget);
      expect(find.byType(TextField), findsNothing,
          reason: 'tab Yêu thích không có ô tìm kiếm');
    });

    testWidgets('error: lỗi lần đầu → AppErrorView, bấm thử lại tải lại',
        (tester) async {
      var fail = true;
      api.onList = (_) async {
        if (fail) throw NetworkException();
        return recipePage(<Recipe>[buildRecipe('r1', name: 'Canh chua')]);
      };
      await pumpList(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text(l10n.networkError), findsOneWidget);

      fail = false;
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();

      expect(api.listCalls, hasLength(2));
      expect(find.byType(AppErrorView), findsNothing);
      expect(find.text('Canh chua'), findsOneWidget);
    });

    testWidgets('success: hiện card + nút Tải thêm khi còn trang',
        (tester) async {
      api.onList = (call) async => recipePage(
            <Recipe>[buildRecipe('p${call.page}', name: 'Món ${call.page}')],
            page: call.page,
            totalPages: 2,
          );
      await pumpList(tester);
      await tester.pumpAndSettle();

      expect(find.text('Món 0'), findsOneWidget);
      expect(find.text(l10n.recipesLoadMore), findsOneWidget);

      // #201: nút nằm dưới lưới (không còn là một ô) → cuộn tới trước.
      await tester.ensureVisible(find.text(l10n.recipesLoadMore));
      await tester.pump();
      await tester.tap(find.text(l10n.recipesLoadMore));
      await tester.pumpAndSettle();

      expect(api.listCalls.map((c) => c.page), <int>[0, 1]);
      expect(find.text('Món 1'), findsOneWidget);
      expect(find.text(l10n.recipesLoadMore), findsNothing,
          reason: 'đã tới trang cuối');
    });

    testWidgets('gõ tìm kiếm → gọi API với search sau debounce 300ms',
        (tester) async {
      await pumpList(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'canh');
      await tester.pump(const Duration(milliseconds: 299));
      expect(api.listCalls, hasLength(1));

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(api.listCalls, hasLength(2));
      expect(api.listCalls.last.search, 'canh');
    });

    testWidgets('bấm tim lỗi → icon về trạng thái cũ + banner lỗi inline',
        (tester) async {
      api.onList = (_) async =>
          recipePage(<Recipe>[buildRecipe('r1', name: 'Canh chua')]);
      api.onSetFavorite = (_, __) async => throw NetworkException();
      await pumpList(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();

      expect(api.setFavoriteCalls.single, ('r1', true));
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text(l10n.networkError), findsOneWidget);
      expect(find.text('Canh chua'), findsOneWidget);
    });

    testWidgets('#201: card đủ badge không tràn ở 360dp, text scale 1.3',
        (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      api.onList = (_) async => recipePage(<Recipe>[
            for (final id in <String>['a', 'b', 'c'])
              Recipe(
                id: id,
                name: 'Canh chua cá lóc nấu kiểu miền Tây rất dài $id',
                dietTypes: const <String>['GLUTEN_FREE'],
                source: 'MANUAL',
                createdAt: fixedTime,
                updatedAt: fixedTime,
                prepTimeMinutes: 15,
                cookTimeMinutes: 30,
                serves: 4,
                difficulty: 'MEDIUM',
                nutrition: const RecipeNutrition(calories: 523.4),
                favorite: const RecipeFavoriteState(avgRating: 4.5),
              ),
          ]);
      await pumpList(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(l10n.homeRecipeMinutes(45)), findsNWidgets(3));
      expect(find.text(l10n.homeRecipeCalories(523)), findsNWidgets(3));
      expect(find.text(l10n.recipeCardServes(4)), findsNWidgets(3));
    });

    testWidgets('#201: sheet lọc dùng chip, Áp dụng gửi filter đã chọn',
        (tester) async {
      await pumpList(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String?>), findsNothing);

      await tester
          .tap(find.byKey(const ValueKey<String>('recipe-filter-diet-VEGAN')));
      await tester.pump();
      final time = find.byKey(const ValueKey<String>('recipe-filter-time-30'));
      await tester.ensureVisible(time);
      await tester.pump();
      await tester.tap(time);
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey<String>('recipe-filter-apply')));
      await tester.pumpAndSettle();

      expect(api.listCalls.last.dietType, 'VEGAN');
      expect(api.listCalls.last.maxPrepTime, 30);
      expect(api.listCalls.last.difficulty, isNull);
    });
  });

  group('RecipeDetailScene', () {
    late RecipeDetailStore store;

    Future<void> pumpDetail(WidgetTester tester) async {
      store = RecipeDetailStore('r1', api);
      Get.put<RecipeDetailStore>(store, tag: 'r1');
      await tester.pumpAppWidget(const RecipeDetailScene(recipeId: 'r1'),
          wrapInScaffold: false);
    }

    final fullRecipe = buildRecipe(
      'r1',
      name: 'Canh chua cá',
      difficulty: 'EASY',
      ingredients: const <RecipeIngredient>[
        RecipeIngredient(name: 'Cá lóc', quantity: 400, unit: 'g'),
      ],
      steps: const <RecipeStep>[
        RecipeStep(stepNumber: 1, instruction: 'Sơ chế cá'),
      ],
      favorite: const RecipeFavoriteState(myRating: 3, favoriteCount: 2),
    );

    testWidgets('loading: hiện AppLoadingView khi đang tải', (tester) async {
      final gate = Completer<Recipe>();
      api.onGetById = (_) => gate.future;
      await pumpDetail(tester);
      await tester.pump();

      expect(find.byType(AppLoadingView), findsOneWidget);

      gate.complete(fullRecipe);
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingView), findsNothing);
    });

    testWidgets('error: AppErrorView với message BE, thử lại gọi load',
        (tester) async {
      var fail = true;
      api.onGetById = (_) async {
        if (fail) throw BusinessException('ERR_RECIPE_NOT_FOUND', 'Không có');
        return fullRecipe;
      };
      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Không có'), findsOneWidget);

      fail = false;
      await tester.tap(find.text(l10n.commonRetry));
      await tester.pumpAndSettle();
      expect(api.getByIdCalls, <String>['r1', 'r1']);
      expect(find.text('Canh chua cá'), findsOneWidget);
    });

    testWidgets('success: tên, nguyên liệu, bước, nút Bắt đầu nấu',
        (tester) async {
      api.onGetById = (_) async => fullRecipe;
      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('Canh chua cá'), findsOneWidget);
      expect(find.text(l10n.recipeDifficultyEasy), findsOneWidget);
      expect(find.text(l10n.recipeHouseholdFavorites(2)), findsOneWidget);
      await tester.scrollUntilVisible(find.text('400 g'), 200);
      expect(find.text('Cá lóc'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Sơ chế cá'), 200);
      await tester.scrollUntilVisible(find.text(l10n.recipeStartCooking), 200);
      expect(find.text(l10n.recipeNoSteps), findsNothing);
    });

    testWidgets('success không có bước → thông báo recipeNoSteps, không có nút nấu',
        (tester) async {
      api.onGetById = (_) async => buildRecipe('r1', name: 'Nháp');
      await pumpDetail(tester);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text(l10n.recipeNoSteps), 200);
      expect(find.text(l10n.recipeStartCooking), findsNothing);
    });

    testWidgets('chấm sao gọi setRating với đúng giá trị', (tester) async {
      api.onGetById = (_) async => fullRecipe;
      api.onSetRating = (_, rating) async =>
          RecipeFavoriteState(myRating: rating, avgRating: 4.5);
      await pumpDetail(tester);
      await tester.pumpAndSettle();

      final fifthStar = find.byTooltip('5');
      await tester.scrollUntilVisible(fifthStar, 200);
      await tester.tap(fifthStar);
      await tester.pumpAndSettle();

      expect(api.setRatingCalls.single, ('r1', 5));
      expect(store.recipe!.favorite.myRating, 5);
      expect(find.text('★ 4.5'), findsOneWidget);
    });

    testWidgets('bấm tim lỗi → icon trở lại cũ + banner lỗi, màn vẫn success',
        (tester) async {
      api.onGetById = (_) async => fullRecipe;
      api.onSetFavorite = (_, __) async => throw NetworkException();
      await pumpDetail(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(l10n.recipesFavorites));
      await tester.pumpAndSettle();

      expect(api.setFavoriteCalls.single, ('r1', true));
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text(l10n.networkError), findsOneWidget);
      expect(find.text('Canh chua cá'), findsOneWidget);
    });
  });
}
