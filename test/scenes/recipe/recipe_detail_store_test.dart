import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_routes.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/domain/recipe.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/stores/recipe_detail_store.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/stores/recipe_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import 'fake_recipe_catalog_api.dart';

/// Unit test RecipeDetailStore (#80 + §17 favorite/rating).
void main() {
  late FakeRecipeCatalogApi api;
  late RecipeDetailStore store;

  final favoritedAt = DateTime.utc(2026, 10, 1, 8);
  final before = RecipeFavoriteState(
    myFavorite: true,
    favoritedAt: favoritedAt,
    myRating: 3,
    favoriteCount: 2,
    avgRating: 3.5,
  );
  const steps = <RecipeStep>[
    RecipeStep(stepNumber: 1, instruction: 'Sơ chế'),
  ];

  void expectSameFavorite(RecipeFavoriteState actual, RecipeFavoriteState exp) {
    expect(actual.myFavorite, exp.myFavorite);
    expect(actual.favoritedAt, exp.favoritedAt);
    expect(actual.myRating, exp.myRating);
    expect(actual.favoriteCount, exp.favoriteCount);
    expect(actual.avgRating, exp.avgRating);
  }

  Future<void> loadWith(Recipe recipe) async {
    api.onGetById = (_) async => recipe;
    await store.load();
  }

  setUp(() {
    api = FakeRecipeCatalogApi();
    store = RecipeDetailStore('r1', api);
  });
  tearDown(Get.reset);

  group('load', () {
    test('mặc định LoadingState; thành công → SuccessState', () async {
      expect(store.state, isA<LoadingState<Recipe>>());
      await loadWith(buildRecipe('r1', name: 'Canh chua'));

      expect(api.getByIdCalls, <String>['r1']);
      expect(store.state, isA<SuccessState<Recipe>>());
      expect(store.recipe!.name, 'Canh chua');
    });

    test('lỗi → ErrorState giữ đúng exception, recipe=null', () async {
      final failure = BusinessException('ERR_RECIPE_NOT_FOUND', 'Not found');
      api.onGetById = (_) async => throw failure;

      await store.load();

      final state = store.state;
      expect(state, isA<ErrorState<Recipe>>());
      expect((state as ErrorState<Recipe>).error, same(failure));
      expect(store.recipe, isNull);
      expect(store.canStartCooking, isFalse);
    });

    test('load lại về LoadingState và xoá mutationError cũ', () async {
      await loadWith(buildRecipe('r1', favorite: before));
      api.onSetFavorite = (_, __) async => throw NetworkException();
      await store.toggleFavorite();
      expect(store.mutationError, isNotNull);

      final gate = Completer<Recipe>();
      api.onGetById = (_) => gate.future;
      final pending = store.load();
      expect(store.state, isA<LoadingState<Recipe>>());
      expect(store.mutationError, isNull);
      gate.complete(buildRecipe('r1'));
      await pending;
    });
  });

  group('toggleFavorite', () {
    test('recipe chưa tải → không gọi API', () async {
      await store.toggleFavorite();
      expect(api.setFavoriteCalls, isEmpty);
    });

    test('optimistic bỏ tim → áp state server, giữ trục rating', () async {
      await loadWith(buildRecipe('r1', favorite: before));
      final gate = Completer<RecipeFavoriteState>();
      api.onSetFavorite = (_, __) => gate.future;

      final pending = store.toggleFavorite();
      expect(api.setFavoriteCalls.single, ('r1', false));
      expect(store.isMutatingFavorite, isTrue);
      final optimistic = store.recipe!.favorite;
      expect(optimistic.myFavorite, isFalse);
      expect(optimistic.favoritedAt, isNull);
      expect(optimistic.favoriteCount, 1);
      expect(optimistic.myRating, 3);

      gate.complete(const RecipeFavoriteState(
        myFavorite: false,
        favoriteCount: 4,
        // Trục rating trong response bị bỏ qua bởi withFavoriteAxisOf.
        myRating: 1,
        avgRating: 1.0,
      ));
      await pending;

      final after = store.recipe!.favorite;
      expect(after.myFavorite, isFalse);
      expect(after.favoriteCount, 4);
      expect(after.myRating, 3);
      expect(after.avgRating, 3.5);
      expect(store.isMutatingFavorite, isFalse);
      expect(store.mutationError, isNull);
    });

    test('lỗi → rollback về ĐÚNG snapshot trước (kể cả favoritedAt)', () async {
      await loadWith(buildRecipe('r1', favorite: before));
      final failure = NetworkException();
      api.onSetFavorite = (_, __) async => throw failure;

      await store.toggleFavorite();

      expectSameFavorite(store.recipe!.favorite, before);
      expect(store.mutationError, same(failure));
      expect(store.isMutatingFavorite, isFalse);
      expect(store.state, isA<SuccessState<Recipe>>(),
          reason: 'lỗi mutation không biến màn thành ErrorState');
    });

    test('từ chưa thích → thích: count +1; lỗi → về count & favoritedAt cũ',
        () async {
      const notFav = RecipeFavoriteState(favoriteCount: 0);
      await loadWith(buildRecipe('r1', favorite: notFav));
      final gate = Completer<RecipeFavoriteState>();
      api.onSetFavorite = (_, __) => gate.future;

      final pending = store.toggleFavorite();
      expect(store.recipe!.favorite.myFavorite, isTrue);
      expect(store.recipe!.favorite.favoriteCount, 1);
      expect(store.recipe!.favorite.favoritedAt, isNotNull);

      gate.completeError(ServerException('ERR_INTERNAL', 'Server error'));
      await pending;
      expectSameFavorite(store.recipe!.favorite, notFav);
    });

    test('đang mutate thì bấm lần nữa bị bỏ qua', () async {
      await loadWith(buildRecipe('r1', favorite: before));
      final gate = Completer<RecipeFavoriteState>();
      api.onSetFavorite = (_, __) => gate.future;

      final pending = store.toggleFavorite();
      await store.toggleFavorite();
      expect(api.setFavoriteCalls, hasLength(1));

      gate.complete(const RecipeFavoriteState());
      await pending;
    });
  });

  group('setRating', () {
    test('optimistic myRating → áp myRating/avgRating server', () async {
      await loadWith(buildRecipe('r1', favorite: before));
      final gate = Completer<RecipeFavoriteState>();
      api.onSetRating = (_, __) => gate.future;

      final pending = store.setRating(5);
      expect(api.setRatingCalls.single, ('r1', 5));
      expect(store.isMutatingRating, isTrue);
      expect(store.recipe!.favorite.myRating, 5);

      gate.complete(const RecipeFavoriteState(myRating: 5, avgRating: 4.0));
      await pending;

      final after = store.recipe!.favorite;
      expect(after.myRating, 5);
      expect(after.avgRating, 4.0);
      expect(after.myFavorite, isTrue, reason: 'trục favorite không bị đụng');
      expect(after.favoriteCount, 2);
      expect(after.favoritedAt, favoritedAt);
      expect(store.isMutatingRating, isFalse);
    });

    test('lỗi → rollback về ĐÚNG snapshot trước', () async {
      await loadWith(buildRecipe('r1', favorite: before));
      final failure = BusinessException('ERR_VALIDATION', 'bad');
      api.onSetRating = (_, __) async => throw failure;

      await store.setRating(1);

      expectSameFavorite(store.recipe!.favorite, before);
      expect(store.mutationError, same(failure));
      expect(store.isMutatingRating, isFalse);
    });

    test('xoá đánh giá (null): optimistic về null; lỗi → trả lại 3', () async {
      await loadWith(buildRecipe('r1', favorite: before));
      final gate = Completer<RecipeFavoriteState>();
      api.onSetRating = (_, __) => gate.future;

      final pending = store.setRating(null);
      expect(api.setRatingCalls.single, ('r1', null));
      expect(store.recipe!.favorite.myRating, isNull);

      gate.completeError(NetworkException());
      await pending;
      expectSameFavorite(store.recipe!.favorite, before);
    });

    test('rating lỗi không rollback trục favorite vừa thành công song song',
        () async {
      await loadWith(buildRecipe('r1', favorite: before));
      final favGate = Completer<RecipeFavoriteState>();
      final rateGate = Completer<RecipeFavoriteState>();
      api.onSetFavorite = (_, __) => favGate.future;
      api.onSetRating = (_, __) => rateGate.future;

      final fav = store.toggleFavorite();
      final rate = store.setRating(5);
      favGate.complete(const RecipeFavoriteState(myFavorite: false, favoriteCount: 1));
      await fav;
      rateGate.completeError(NetworkException());
      await rate;

      final after = store.recipe!.favorite;
      expect(after.myFavorite, isFalse);
      expect(after.favoriteCount, 1);
      expect(after.favoritedAt, isNull);
      expect(after.myRating, 3);
      expect(after.avgRating, 3.5);
    });
  });

  group('đồng bộ sang RecipeStore', () {
    test('RecipeStore đã đăng ký → item trong danh sách cập nhật & rollback',
        () async {
      final listApi = FakeRecipeCatalogApi()
        ..onList = (_) async =>
            recipePage(<Recipe>[buildRecipe('r1', favorite: before)]);
      final list = RecipeStore(listApi);
      await list.refresh();
      Get.put<RecipeStore>(list);

      await loadWith(buildRecipe('r1', favorite: before));
      final gate = Completer<RecipeFavoriteState>();
      api.onSetFavorite = (_, __) => gate.future;

      final pending = store.toggleFavorite();
      expect(list.recipes.single.favorite.myFavorite, isFalse);

      gate.completeError(NetworkException());
      await pending;
      expectSameFavorite(list.recipes.single.favorite, before);
      list.dispose();
    });
  });

  group('bắt đầu nấu', () {
    test('canStartCooking theo hasSteps', () async {
      await loadWith(buildRecipe('r1', steps: steps));
      expect(store.canStartCooking, isTrue);

      await loadWith(buildRecipe('r1', steps: const <RecipeStep>[]));
      expect(store.canStartCooking, isFalse);
    });

    Future<List<Object?>> pumpRouter(WidgetTester tester) async {
      final pushed = <Object?>[];
      Get.testMode = true;
      await tester.pumpWidget(GetMaterialApp(
        initialRoute: '/',
        getPages: <GetPage<dynamic>>[
          GetPage<void>(name: '/', page: () => const SizedBox()),
          GetPage<void>(
            name: CookingRoutes.session,
            page: () {
              pushed.add(Get.arguments);
              return const SizedBox();
            },
          ),
        ],
      ));
      return pushed;
    }

    testWidgets('có bước → điều hướng tới cooking session với CookingArgs.start',
        (tester) async {
      final pushed = await pumpRouter(tester);
      await tester.runAsync(() => loadWith(buildRecipe('r1', steps: steps)));

      store.startCooking();
      await tester.pumpAndSettle();

      expect(Get.currentRoute, CookingRoutes.session);
      expect(pushed, hasLength(1));
      expect(pushed.single, isA<CookingArgs>());
      // _CookingStartArgs là private; đọc recipeId qua dynamic.
      expect((pushed.single as dynamic).recipeId, 'r1');
    });

    testWidgets('không có bước → không điều hướng', (tester) async {
      final pushed = await pumpRouter(tester);
      await tester.runAsync(
          () => loadWith(buildRecipe('r1', steps: const <RecipeStep>[])));

      store.startCooking();
      await tester.pumpAndSettle();

      expect(pushed, isEmpty);
      expect(Get.currentRoute, '/');
    });
  });
}
