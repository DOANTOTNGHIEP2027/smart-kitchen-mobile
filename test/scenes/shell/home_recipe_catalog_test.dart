import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/data/recipe_catalog_api.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/domain/recipe.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/scenes/recipe_detail_scene.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/scenes/recipe_routes.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/stores/recipe_store.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_scene.dart';
import 'package:smart_kitchen_mobile/scenes/shell/app_shell_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_empty_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/shell_bindings_stub.dart';
import '../recipe/fake_recipe_catalog_api.dart';

void main() {
  final l10n = AppLocalizationsVi();
  late FakeRecipeCatalogApi api;

  setUp(() {
    api = FakeRecipeCatalogApi();
    Get.put<RecipeCatalogApi>(api);
  });
  tearDown(Get.reset);

  Future<void> pumpCatalog(WidgetTester tester) => tester.pumpAppWidget(
        const SingleChildScrollView(child: HomeRecipeCatalog()),
      );

  testWidgets('đang tải rồi catalog rỗng: không thay bằng món demo',
      (tester) async {
    final gate = Completer<RecipePage>();
    api.onList = (_) => gate.future;
    await pumpCatalog(tester);
    expect(find.byType(AppLoadingView), findsOneWidget);

    gate.complete(recipePage(const <Recipe>[]));
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyView), findsOneWidget);
    expect(find.text(l10n.recipesNoResults), findsOneWidget);
    expect(find.text(l10n.homeRecommendedMeals), findsNothing);
  });

  testWidgets('lỗi mạng có thử lại và tải món trả về từ API', (tester) async {
    api.onList = (_) async => throw NetworkException();
    await pumpCatalog(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorView), findsOneWidget);

    api.onList = (_) async => recipePage(<Recipe>[
          buildRecipe('seed-pho', name: 'Phở bò từ backend'),
        ]);
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorView), findsNothing);
    expect(find.text('Phở bò từ backend'), findsOneWidget);
    expect(api.listCalls, hasLength(2));
  });

  testWidgets('Home tải catalog dù màn Công thức đang lọc tab yêu thích',
      (tester) async {
    final filteredStore = RecipeStore(api);
    Get.put<RecipeStore>(filteredStore);
    filteredStore.setTab(RecipeListTab.favorites);
    api.onList = (_) async => recipePage(List<Recipe>.generate(
          8,
          (i) => buildRecipe('seed-$i', name: 'Công thức seed $i'),
        ));
    await pumpCatalog(tester);
    await tester.pumpAndSettle();

    expect(api.listCalls.single.search, isEmpty);
    expect(find.text('Công thức seed 0'), findsOneWidget);
    expect(find.text('Công thức seed 5'), findsOneWidget);
    expect(find.text('Công thức seed 6'), findsNothing);
    expect(filteredStore.tab, RecipeListTab.favorites);
    await tester.tap(find.byTooltip(l10n.refresh));
    await tester.pumpAndSettle();
    expect(api.listCalls, hasLength(2));
    filteredStore.dispose();
  });

  testWidgets('shell backend thật có catalog ngay trên trang chủ',
      (tester) async {
    api.onList = (_) async => recipePage(<Recipe>[
          buildRecipe('seed-pho', name: 'Phở bò từ backend'),
        ]);
    Get.put<AppShellStore>(AppShellStore());
    registerShellStubBindings();
    await tester.pumpAppWidget(const AppShellScene(), wrapInScaffold: false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(HomeRecipeCatalog));
    await tester.pumpAndSettle();
    expect(find.text('Phở bò từ backend'), findsOneWidget);
    expect(api.listCalls, hasLength(1));
  });

  testWidgets('bấm món mở chi tiết bằng id backend, chỉ đọc công thức',
      (tester) async {
    api.onList = (_) async => recipePage(<Recipe>[
          buildRecipe('seed-pho', name: 'Phở bò từ backend'),
        ]);
    api.onGetById = (id) async => buildRecipe(
          id,
          name: 'Phở bò chi tiết',
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
                name: 'Bánh phở từ seed', quantity: 800, unit: 'g'),
          ],
        );
    await tester.pumpWidget(GetMaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(child: HomeRecipeCatalog()),
      ),
      getPages: <GetPage<dynamic>>[
        GetPage<void>(
          name: AppRoutes.recipeDetail,
          page: () => RecipeDetailScene(recipeId: Get.parameters['id']!),
          binding: RecipeDetailBinding(),
        ),
      ],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phở bò từ backend'));
    await tester.pumpAndSettle();
    expect(api.getByIdCalls, <String>['seed-pho']);
    expect(find.text('Phở bò chi tiết'), findsOneWidget);
    expect(find.textContaining('Bánh phở từ seed'), findsOneWidget);
    expect(find.byType(RecipeDetailScene), findsOneWidget);
  });
}
