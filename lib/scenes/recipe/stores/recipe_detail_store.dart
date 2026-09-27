import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../widgets/states/view_state.dart';
import '../../cooking/scenes/cooking_routes.dart';
import '../data/recipe_catalog_api.dart';
import '../domain/recipe.dart';
import 'recipe_store.dart';

class RecipeDetailStore {
  RecipeDetailStore(this.recipeId, this._api);

  final String recipeId;
  final RecipeCatalogApi _api;
  final Observable<ViewState<Recipe>> _state =
      Observable<ViewState<Recipe>>(const LoadingState<Recipe>());
  final Observable<bool> _isMutatingFavorite = Observable<bool>(false);
  final Observable<bool> _isMutatingRating = Observable<bool>(false);
  final Observable<ApiException?> _mutationError = Observable<ApiException?>(null);

  ViewState<Recipe> get state => _state.value;
  bool get isMutatingFavorite => _isMutatingFavorite.value;
  bool get isMutatingRating => _isMutatingRating.value;
  ApiException? get mutationError => _mutationError.value;
  Recipe? get recipe => switch (_state.value) {
        SuccessState<Recipe>(:final data) => data,
        _ => null,
      };
  bool get canStartCooking => recipe?.hasSteps == true;

  Future<void> load() async {
    runInAction(() {
      _state.value = const LoadingState<Recipe>();
      _mutationError.value = null;
    });
    try {
      final fresh = await _api.getById(recipeId);
      runInAction(() => _state.value = SuccessState<Recipe>(fresh));
    } on ApiException catch (error) {
      runInAction(() => _state.value = ErrorState<Recipe>(error));
    }
  }

  void startCooking() {
    final current = recipe;
    if (current == null || !current.hasSteps) return;
    Get.toNamed(CookingRoutes.session, arguments: CookingArgs.start(current.id));
  }

  Future<void> toggleFavorite() async {
    final current = recipe;
    if (current == null || _isMutatingFavorite.value) return;
    final before = current.favorite;
    final target = !before.myFavorite;
    runInAction(() {
      _isMutatingFavorite.value = true;
      _mutationError.value = null;
      _publishFavoriteAxis(
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
      _publishFavoriteAxis(await _api.setFavorite(current.id, target));
    } on ApiException catch (error) {
      _publishFavoriteAxis(before);
      _publishError(error);
    } finally {
      runInAction(() => _isMutatingFavorite.value = false);
    }
  }

  Future<void> setRating(int? rating) async {
    final current = recipe;
    if (current == null || _isMutatingRating.value) return;
    final before = current.favorite;
    runInAction(() {
      _isMutatingRating.value = true;
      _mutationError.value = null;
      _publishRatingAxis(before.copyWith(myRating: rating, clearRating: rating == null));
    });
    try {
      _publishRatingAxis(await _api.setRating(current.id, rating));
    } on ApiException catch (error) {
      _publishRatingAxis(before);
      _publishError(error);
    } finally {
      runInAction(() => _isMutatingRating.value = false);
    }
  }

  void _publishFavoriteAxis(RecipeFavoriteState source) =>
      _publishAxis((current) => current.withFavoriteAxisOf(source));

  void _publishRatingAxis(RecipeFavoriteState source) =>
      _publishAxis((current) => current.withRatingAxisOf(source));

  void _publishAxis(RecipeFavoriteState Function(RecipeFavoriteState) merge) {
    final current = recipe;
    if (current == null) return;
    final next = merge(current.favorite);
    runInAction(() => _state.value = SuccessState<Recipe>(current.copyWithFavorite(next)));
    if (Get.isRegistered<RecipeStore>()) {
      Get.find<RecipeStore>().applyFavoriteState(current.id, next);
    }
  }

  void _publishError(ApiException error) =>
      runInAction(() => _mutationError.value = error);
}
