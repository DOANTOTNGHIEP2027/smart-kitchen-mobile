import 'dart:async';
import 'dart:math' as math;

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../data/recipe_catalog_api.dart';
import '../domain/recipe.dart';

enum RecipeListStatus { loading, loadingMore, ready }
enum RecipeListTab { all, favorites }

/// State cho danh sách công thức. Không dùng codegen để tránh tạo thêm một
/// bước build cho state đơn giản này; các Observable vẫn được Observer theo dõi.
class RecipeStore {
  RecipeStore(this._api);

  final RecipeCatalogApi _api;
  final ObservableList<Recipe> _recipes = ObservableList<Recipe>();
  final Observable<RecipeListStatus> _status =
      Observable<RecipeListStatus>(RecipeListStatus.loading);
  final Observable<ApiException?> _error = Observable<ApiException?>(null);
  final Observable<bool> _hasMore = Observable<bool>(true);
  final Observable<RecipeListTab> _tab =
      Observable<RecipeListTab>(RecipeListTab.all);
  final Observable<String> _searchQuery = Observable<String>('');
  final Observable<String?> _dietType = Observable<String?>(null);
  final Observable<String?> _difficulty = Observable<String?>(null);
  final Observable<int?> _maxPrepTime = Observable<int?>(null);
  final ObservableSet<String> _pendingFavoriteIds = ObservableSet<String>();
  final Observable<bool> _favoritesListDirty = Observable<bool>(false);

  Timer? _searchDebounce;
  int _currentPage = 0;
  int _generation = 0;
  int _requestId = 0;

  List<Recipe> get recipes => _recipes;
  RecipeListStatus get status => _status.value;
  ApiException? get error => _error.value;
  bool get hasMore => _hasMore.value;
  RecipeListTab get tab => _tab.value;
  String get searchQuery => _searchQuery.value;
  String? get dietType => _dietType.value;
  String? get difficulty => _difficulty.value;
  int? get maxPrepTime => _maxPrepTime.value;
  bool get isFavoritesTab => _tab.value == RecipeListTab.favorites;
  bool get favoritesListDirty => _favoritesListDirty.value;

  bool get isFirstLoadError =>
      _error.value != null && _recipes.isEmpty && _status.value == RecipeListStatus.ready;
  bool get isEmptyResult =>
      _error.value == null && _recipes.isEmpty && _status.value == RecipeListStatus.ready;

  bool isFavoritePending(String recipeId) => _pendingFavoriteIds.contains(recipeId);

  Future<void> init() => refresh();

  void setTab(RecipeListTab value) {
    if (_tab.value == value) return;
    runInAction(() => _tab.value = value);
    unawaited(refresh());
  }

  void setSearchQuery(String value) {
    runInAction(() => _searchQuery.value = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), refresh);
  }

  void setDietType(String? value) {
    if (_dietType.value == value) return;
    runInAction(() => _dietType.value = value);
    unawaited(refresh());
  }

  void setDifficulty(String? value) {
    if (_difficulty.value == value) return;
    runInAction(() => _difficulty.value = value);
    unawaited(refresh());
  }

  void setMaxPrepTime(int? value) {
    if (_maxPrepTime.value == value) return;
    runInAction(() => _maxPrepTime.value = value);
    unawaited(refresh());
  }

  void setFilters({
    required String? dietType,
    required String? difficulty,
    required int? maxPrepTime,
  }) {
    final didChange = _dietType.value != dietType ||
        _difficulty.value != difficulty ||
        _maxPrepTime.value != maxPrepTime;
    if (!didChange) return;
    runInAction(() {
      _dietType.value = dietType;
      _difficulty.value = difficulty;
      _maxPrepTime.value = maxPrepTime;
    });
    unawaited(refresh());
  }

  Future<void> refresh() async {
    _searchDebounce?.cancel();
    final request = ++_requestId;
    runInAction(() {
      _generation++;
      _status.value = RecipeListStatus.loading;
      _error.value = null;
      _hasMore.value = true;
      _currentPage = 0;
      _pendingFavoriteIds.clear();
      _favoritesListDirty.value = false;
    });
    await _fetchPage(0, append: false, request: request);
  }

  Future<void> loadMore() async {
    if (!_hasMore.value || _status.value != RecipeListStatus.ready) return;
    if (isFavoritesTab && _favoritesListDirty.value) return;
    final request = ++_requestId;
    runInAction(() => _status.value = RecipeListStatus.loadingMore);
    await _fetchPage(_currentPage + 1, append: true, request: request);
  }

  Future<void> _fetchPage(
    int page, {
    required bool append,
    required int request,
  }) async {
    try {
      final pageData = isFavoritesTab
          ? await _api.listFavorites(page: page, size: 20)
          : await _api.list(
              page: page,
              size: 20,
              search: _searchQuery.value,
              dietType: _dietType.value,
              difficulty: _difficulty.value,
              maxPrepTime: _maxPrepTime.value,
            );
      if (request != _requestId) return;
      runInAction(() {
        if (append) {
          _recipes.addAll(pageData.items);
        } else {
          _recipes
            ..clear()
            ..addAll(pageData.items);
        }
        _currentPage = pageData.page;
        _hasMore.value = pageData.page < pageData.totalPages - 1;
        _error.value = null;
        _status.value = RecipeListStatus.ready;
      });
    } on ApiException catch (error) {
      if (request != _requestId) return;
      runInAction(() {
        _error.value = error;
        _status.value = RecipeListStatus.ready;
      });
    }
  }

  void applyFavoriteState(String recipeId, RecipeFavoriteState value) {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index < 0) return;
    runInAction(() => _recipes[index] = _recipes[index].copyWithFavorite(value));
  }

  Future<void> toggleFavorite(String recipeId) async {
    if (_pendingFavoriteIds.contains(recipeId)) return;
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index < 0) return;

    final before = _recipes[index].favorite;
    final target = !before.myFavorite;
    final generation = _generation;
    runInAction(() {
      _pendingFavoriteIds.add(recipeId);
      _applyFavoriteAxis(
        recipeId,
        before.copyWith(
          myFavorite: target,
          favoritedAt: target ? DateTime.now() : null,
          clearFavoritedAt: !target,
          favoriteCount:
              target ? before.favoriteCount + 1 : math.max(0, before.favoriteCount - 1),
        ),
      );
    });
    try {
      final fresh = await _api.setFavorite(recipeId, target);
      if (generation == _generation) {
        runInAction(() {
          _applyFavoriteAxis(recipeId, fresh);
          if (isFavoritesTab && !target) _favoritesListDirty.value = true;
        });
      }
    } on ApiException catch (error) {
      if (generation == _generation) {
        runInAction(() => _applyFavoriteAxis(recipeId, before));
      }
      runInAction(() => _error.value = error);
    } finally {
      runInAction(() => _pendingFavoriteIds.remove(recipeId));
    }
  }

  void _applyFavoriteAxis(String recipeId, RecipeFavoriteState source) {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index < 0) return;
    final current = _recipes[index].favorite;
    _recipes[index] = _recipes[index]
        .copyWithFavorite(current.withFavoriteAxisOf(source));
  }

  void dispose() => _searchDebounce?.cancel();
}
