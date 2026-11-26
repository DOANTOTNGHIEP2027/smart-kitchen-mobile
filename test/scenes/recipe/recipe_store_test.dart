import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/domain/recipe.dart';
import 'package:smart_kitchen_mobile/scenes/recipe/stores/recipe_store.dart';

import 'fake_recipe_catalog_api.dart';

/// Unit test RecipeStore (#80 — danh sách công thức, §17 favorite).
void main() {
  late FakeRecipeCatalogApi api;
  late RecipeStore store;

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  setUp(() {
    api = FakeRecipeCatalogApi();
    store = RecipeStore(api);
  });
  tearDown(() => store.dispose());

  group('refresh / phân trang', () {
    test('init gọi trang 0, size 20, không filter; nhận dữ liệu → ready',
        () async {
      api.onList = (_) async =>
          recipePage(<Recipe>[buildRecipe('r1'), buildRecipe('r2')],
              totalPages: 3);

      expect(store.status, RecipeListStatus.loading);
      await store.init();

      final call = api.listCalls.single;
      expect(call.page, 0);
      expect(call.size, 20);
      expect(call.search, '');
      expect(call.dietType, isNull);
      expect(call.difficulty, isNull);
      expect(call.maxPrepTime, isNull);
      expect(store.recipes.map((r) => r.id), <String>['r1', 'r2']);
      expect(store.status, RecipeListStatus.ready);
      expect(store.hasMore, isTrue);
      expect(store.error, isNull);
    });

    test('loadMore nối trang kế tiếp; hết trang cuối → hasMore=false', () async {
      api.onList = (call) async => recipePage(
            <Recipe>[buildRecipe('p${call.page}')],
            page: call.page,
            totalPages: 2,
          );
      await store.refresh();
      expect(store.hasMore, isTrue);

      await store.loadMore();

      expect(api.listCalls.map((c) => c.page), <int>[0, 1]);
      expect(store.recipes.map((r) => r.id), <String>['p0', 'p1']);
      expect(store.hasMore, isFalse);
      expect(store.status, RecipeListStatus.ready);

      await store.loadMore();
      expect(api.listCalls, hasLength(2), reason: 'hết danh sách thì không gọi nữa');
    });

    test('chỉ 1 trang → hasMore=false ngay sau refresh', () async {
      api.onList = (_) async => recipePage(<Recipe>[buildRecipe('r1')]);
      await store.refresh();
      expect(store.hasMore, isFalse);
    });

    test('loadMore bị bỏ qua khi refresh đang chạy (status=loading)', () async {
      final gate = Completer<RecipePage>();
      api.onList = (_) => gate.future;
      final pending = store.refresh();

      await store.loadMore();
      expect(api.listCalls, hasLength(1));

      gate.complete(recipePage(const <Recipe>[]));
      await pending;
    });

    test('refresh lần sau thay toàn bộ danh sách, không nối', () async {
      var round = 0;
      api.onList = (_) async {
        round++;
        return recipePage(<Recipe>[buildRecipe('round$round')], totalPages: 2);
      };
      await store.refresh();
      await store.refresh();
      expect(store.recipes.map((r) => r.id), <String>['round2']);
    });

    test('kết quả rỗng → isEmptyResult, không phải lỗi', () async {
      await store.refresh();
      expect(store.isEmptyResult, isTrue);
      expect(store.isFirstLoadError, isFalse);
    });
  });

  group('lỗi', () {
    test('lỗi lần tải đầu → isFirstLoadError, giữ đúng exception', () async {
      final failure = NetworkException();
      api.onList = (_) async => throw failure;

      await store.refresh();

      expect(store.status, RecipeListStatus.ready);
      expect(store.error, same(failure));
      expect(store.recipes, isEmpty);
      expect(store.isFirstLoadError, isTrue);
      expect(store.isEmptyResult, isFalse);
    });

    test('lỗi loadMore giữ dữ liệu cũ, vẫn hasMore và thử lại đúng trang',
        () async {
      final failure = ServerException('ERR_INTERNAL', 'Server error');
      var failNext = false;
      api.onList = (call) async {
        if (failNext) throw failure;
        return recipePage(<Recipe>[buildRecipe('p${call.page}')],
            page: call.page, totalPages: 3);
      };
      await store.refresh();

      failNext = true;
      await store.loadMore();

      expect(store.recipes.map((r) => r.id), <String>['p0']);
      expect(store.error, same(failure));
      expect(store.status, RecipeListStatus.ready);
      expect(store.hasMore, isTrue);
      expect(store.isFirstLoadError, isFalse);

      failNext = false;
      await store.loadMore();
      expect(api.listCalls.map((c) => c.page), <int>[0, 1, 1]);
      expect(store.recipes.map((r) => r.id), <String>['p0', 'p1']);
      expect(store.error, isNull);
    });

    test('refresh xoá lỗi cũ trước khi gọi lại', () async {
      api.onList = (_) async => throw NetworkException();
      await store.refresh();
      expect(store.error, isNotNull);

      final gate = Completer<RecipePage>();
      api.onList = (_) => gate.future;
      final pending = store.refresh();
      expect(store.error, isNull);
      expect(store.status, RecipeListStatus.loading);
      gate.complete(recipePage(const <Recipe>[]));
      await pending;
    });
  });

  group('filter', () {
    test('setDietType / setDifficulty / setMaxPrepTime truyền xuống API',
        () async {
      store.setDietType('KETO');
      await flush();
      store.setDifficulty('EASY');
      await flush();
      store.setMaxPrepTime(30);
      await flush();

      expect(api.listCalls, hasLength(3));
      final last = api.listCalls.last;
      expect(last.dietType, 'KETO');
      expect(last.difficulty, 'EASY');
      expect(last.maxPrepTime, 30);
      expect(last.page, 0);
    });

    test('đặt lại cùng giá trị filter không gọi API', () async {
      store.setDietType('VEGAN');
      await flush();
      store.setDietType('VEGAN');
      store.setDifficulty(null);
      store.setMaxPrepTime(null);
      await flush();
      expect(api.listCalls, hasLength(1));
    });

    test('setFilters đổi cả 3 chỉ refresh một lần; không đổi thì không gọi',
        () async {
      store.setFilters(dietType: 'VEGAN', difficulty: 'HARD', maxPrepTime: 60);
      await flush();
      expect(api.listCalls, hasLength(1));
      expect(api.listCalls.single.dietType, 'VEGAN');
      expect(api.listCalls.single.difficulty, 'HARD');
      expect(api.listCalls.single.maxPrepTime, 60);

      store.setFilters(dietType: 'VEGAN', difficulty: 'HARD', maxPrepTime: 60);
      await flush();
      expect(api.listCalls, hasLength(1));
    });

    test('loadMore giữ nguyên filter và search hiện tại', () async {
      api.onList = (call) async =>
          recipePage(<Recipe>[buildRecipe('p${call.page}')],
              page: call.page, totalPages: 2);
      store.setFilters(dietType: 'KETO', difficulty: null, maxPrepTime: 15);
      await flush();
      await store.loadMore();

      final more = api.listCalls.last;
      expect(more.page, 1);
      expect(more.dietType, 'KETO');
      expect(more.maxPrepTime, 15);
    });
  });

  group('search debounce 300ms', () {
    test('gõ liên tục chỉ gọi 1 lần với giá trị cuối, sau 300ms', () async {
      store.setSearchQuery('ca');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      store.setSearchQuery('canh');
      expect(store.searchQuery, 'canh');

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(api.listCalls, isEmpty, reason: 'mới 200ms kể từ lần gõ cuối');

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(api.listCalls, hasLength(1));
      expect(api.listCalls.single.search, 'canh');
    });

    test('refresh thủ công huỷ debounce đang chờ (không gọi trùng)', () async {
      store.setSearchQuery('pho');
      await store.refresh();
      expect(api.listCalls.single.search, 'pho');

      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(api.listCalls, hasLength(1));
    });

    test('dispose huỷ debounce', () async {
      store.setSearchQuery('bun');
      store.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(api.listCalls, isEmpty);
    });
  });

  group('chống response cũ (stale)', () {
    test('response của request cũ về sau không ghi đè request mới', () async {
      final first = Completer<RecipePage>();
      final second = Completer<RecipePage>();
      final gates = <Completer<RecipePage>>[first, second];
      api.onList = (_) => gates.removeAt(0).future;

      final a = store.refresh();
      final b = store.refresh();
      second.complete(recipePage(<Recipe>[buildRecipe('new')]));
      await b;
      first.complete(recipePage(<Recipe>[buildRecipe('old')]));
      await a;

      expect(store.recipes.map((r) => r.id), <String>['new']);
    });

    test('lỗi của request cũ về sau không bật trạng thái lỗi', () async {
      final first = Completer<RecipePage>();
      final second = Completer<RecipePage>();
      final gates = <Completer<RecipePage>>[first, second];
      api.onList = (_) => gates.removeAt(0).future;

      final a = store.refresh();
      final b = store.refresh();
      second.complete(recipePage(<Recipe>[buildRecipe('new')]));
      await b;
      first.completeError(NetworkException());
      await a;

      expect(store.error, isNull);
      expect(store.status, RecipeListStatus.ready);
    });

    test('loadMore đang chờ bị bỏ khi refresh chen vào', () async {
      api.onList = (call) async =>
          recipePage(<Recipe>[buildRecipe('p0')], totalPages: 3);
      await store.refresh();

      final more = Completer<RecipePage>();
      api.onList = (_) => more.future;
      final loadMore = store.loadMore();
      expect(store.status, RecipeListStatus.loadingMore);

      api.onList = (_) async =>
          recipePage(<Recipe>[buildRecipe('fresh')], totalPages: 3);
      await store.refresh();
      more.complete(
          recipePage(<Recipe>[buildRecipe('p1')], page: 1, totalPages: 3));
      await loadMore;

      expect(store.recipes.map((r) => r.id), <String>['fresh']);
    });
  });

  group('tab Yêu thích', () {
    test('setTab(favorites) gọi listFavorites, không gọi list', () async {
      store.setTab(RecipeListTab.favorites);
      await flush();
      expect(store.isFavoritesTab, isTrue);
      expect(api.favoritesPages, <int>[0]);
      expect(api.listCalls, isEmpty);
    });

    test('setTab cùng tab không refresh lại', () async {
      store.setTab(RecipeListTab.all);
      await flush();
      expect(api.listCalls, isEmpty);
    });
  });

  group('toggleFavorite trên card', () {
    const before = RecipeFavoriteState(
      myFavorite: false,
      myRating: 3,
      favoriteCount: 2,
      avgRating: 3.5,
    );

    Future<void> seed() async {
      api.onList = (_) async =>
          recipePage(<Recipe>[buildRecipe('r1', favorite: before)]);
      await store.refresh();
    }

    // #134 (§17 luật 2): TypeError khi parse → rollback, pending được gỡ.
    test('setFavorite ném TypeError → rollback trục favorite', () async {
      await seed();
      api.onSetFavorite = (_, __) async => throw TypeError();

      await store.toggleFavorite('r1');

      final after = store.recipes.single.favorite;
      expect(after.myFavorite, isFalse);
      expect(after.favoriteCount, 2);
      expect(after.myRating, 3);
      expect(store.isFavoritePending('r1'), isFalse);
      expect(store.error, isA<ServerException>());
    });

    test('optimistic → áp state server khi thành công', () async {
      await seed();
      final gate = Completer<RecipeFavoriteState>();
      api.onSetFavorite = (_, __) => gate.future;

      final pending = store.toggleFavorite('r1');
      final optimistic = store.recipes.single.favorite;
      expect(optimistic.myFavorite, isTrue);
      expect(optimistic.favoriteCount, 3);
      expect(optimistic.favoritedAt, isNotNull);
      expect(store.isFavoritePending('r1'), isTrue);
      expect(api.setFavoriteCalls.single, ('r1', true));

      final serverAt = DateTime.utc(2026, 11, 1);
      gate.complete(RecipeFavoriteState(
        myFavorite: true,
        favoritedAt: serverAt,
        favoriteCount: 5,
      ));
      await pending;

      final after = store.recipes.single.favorite;
      expect(after.myFavorite, isTrue);
      expect(after.favoritedAt, serverAt);
      expect(after.favoriteCount, 5);
      expect(after.myRating, 3, reason: 'trục rating không bị đụng');
      expect(after.avgRating, 3.5);
      expect(store.isFavoritePending('r1'), isFalse);
    });

    test('lỗi → rollback đúng snapshot trước, báo lỗi', () async {
      await seed();
      final failure = NetworkException();
      api.onSetFavorite = (_, __) async => throw failure;

      await store.toggleFavorite('r1');

      final after = store.recipes.single.favorite;
      expect(after.myFavorite, before.myFavorite);
      expect(after.favoritedAt, before.favoritedAt);
      expect(after.favoriteCount, before.favoriteCount);
      expect(after.myRating, before.myRating);
      expect(after.avgRating, before.avgRating);
      expect(store.error, same(failure));
      expect(store.isFavoritePending('r1'), isFalse);
      expect(store.isFirstLoadError, isFalse);
    });

    test('đang chờ thì bấm lần nữa bị bỏ qua', () async {
      await seed();
      final gate = Completer<RecipeFavoriteState>();
      api.onSetFavorite = (_, __) => gate.future;

      final pending = store.toggleFavorite('r1');
      await store.toggleFavorite('r1');
      expect(api.setFavoriteCalls, hasLength(1));

      gate.complete(const RecipeFavoriteState(myFavorite: true));
      await pending;
    });

    test('id không có trong danh sách → không gọi API', () async {
      await seed();
      await store.toggleFavorite('missing');
      expect(api.setFavoriteCalls, isEmpty);
    });

    test('bỏ tim ở tab Yêu thích → favoritesListDirty, chặn loadMore',
        () async {
      api.onListFavorites = (_, __) async => recipePage(
            <Recipe>[
              buildRecipe('r1',
                  favorite: const RecipeFavoriteState(
                      myFavorite: true, favoriteCount: 1)),
            ],
            totalPages: 2,
          );
      store.setTab(RecipeListTab.favorites);
      await flush();
      api.onSetFavorite =
          (_, __) async => const RecipeFavoriteState(myFavorite: false);

      await store.toggleFavorite('r1');

      expect(store.favoritesListDirty, isTrue);
      expect(store.recipes.single.favorite.myFavorite, isFalse);
      await store.loadMore();
      expect(api.favoritesPages, <int>[0], reason: 'loadMore bị chặn');

      await store.refresh();
      expect(store.favoritesListDirty, isFalse);
    });

    test('lỗi sau khi đã refresh (generation đổi) không rollback đè dữ liệu mới',
        () async {
      await seed();
      final gate = Completer<RecipeFavoriteState>();
      api.onSetFavorite = (_, __) => gate.future;
      final pending = store.toggleFavorite('r1');

      const fresh = RecipeFavoriteState(myFavorite: true, favoriteCount: 9);
      api.onList = (_) async =>
          recipePage(<Recipe>[buildRecipe('r1', favorite: fresh)]);
      await store.refresh();
      gate.completeError(NetworkException());
      await pending;

      expect(store.recipes.single.favorite.favoriteCount, 9);
      expect(store.recipes.single.favorite.myFavorite, isTrue);
    });

    // #134 (recipe-list-detail-screens §17 L1/E4a): lỗi favorite của thế hệ
    // list cũ không được để lại banner lỗi trên list vừa refresh thành công.
    test('lỗi favorite về muộn sau refresh thành công → error của list vẫn null',
        () async {
      await seed();
      final gate = Completer<RecipeFavoriteState>();
      api.onSetFavorite = (_, __) => gate.future;
      final pending = store.toggleFavorite('r1');

      await store.refresh();
      expect(store.error, isNull);
      gate.completeError(NetworkException());
      await pending;

      expect(store.error, isNull);
      expect(store.status, RecipeListStatus.ready);
      expect(store.isFavoritePending('r1'), isFalse);
    });
  });

  // #134 (§17 L1/E4b): list() ném lỗi không phải ApiException (TypeError khi
  // parse) thì status phải thoát loading, error = ServerException ERR_UNKNOWN.
  group('lỗi không phải ApiException khi tải trang', () {
    test('list() ném TypeError → ready + ServerException(ERR_UNKNOWN)',
        () async {
      api.onList = (_) async => throw TypeError();

      await store.refresh();

      expect(store.status, RecipeListStatus.ready);
      expect(store.error, isA<ServerException>());
      expect(store.error?.code, 'ERR_UNKNOWN');
      expect(store.isFirstLoadError, isTrue);
    });

    test('tab Yêu thích: listFavorites() ném TypeError → không kẹt loading',
        () async {
      api.onListFavorites = (_, __) async => throw TypeError();

      store.setTab(RecipeListTab.favorites);
      await flush();

      expect(store.status, RecipeListStatus.ready);
      expect(store.error?.code, 'ERR_UNKNOWN');
    });

    test('loadMore ném FormatException → giữ dữ liệu cũ, thoát loadingMore',
        () async {
      api.onList = (call) async {
        if (call.page == 1) throw const FormatException('json hỏng');
        return recipePage(<Recipe>[buildRecipe('r1')], totalPages: 2);
      };
      await store.refresh();

      await store.loadMore();

      expect(store.status, RecipeListStatus.ready);
      expect(store.recipes.map((r) => r.id), <String>['r1']);
      expect(store.error?.code, 'ERR_UNKNOWN');
      expect(store.hasMore, isTrue);
    });

    test('lỗi lạ của request cũ về sau không bật trạng thái lỗi', () async {
      final gate = Completer<RecipePage>();
      api.onList = (_) => gate.future;
      final stale = store.refresh();

      api.onList = (_) async => recipePage(<Recipe>[buildRecipe('r2')]);
      await store.refresh();
      gate.completeError(TypeError());
      await stale;

      expect(store.error, isNull);
      expect(store.recipes.single.id, 'r2');
    });
  });

  test('applyFavoriteState cập nhật đúng item (đồng bộ từ màn chi tiết)',
      () async {
    api.onList = (_) async =>
        recipePage(<Recipe>[buildRecipe('r1'), buildRecipe('r2')]);
    await store.refresh();

    store.applyFavoriteState(
        'r2', const RecipeFavoriteState(myFavorite: true, myRating: 5));

    expect(store.recipes[0].favorite.myFavorite, isFalse);
    expect(store.recipes[1].favorite.myFavorite, isTrue);
    expect(store.recipes[1].favorite.myRating, 5);
  });
}
