import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../routing/app_routes.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_cached_image.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../domain/recipe.dart';
import '../stores/recipe_store.dart';

class RecipeListScene extends StatefulWidget {
  const RecipeListScene({super.key});

  @override
  State<RecipeListScene> createState() => _RecipeListSceneState();
}

class _RecipeListSceneState extends State<RecipeListScene> {
  late final RecipeStore _store;

  @override
  void initState() {
    super.initState();
    _store = Get.find<RecipeStore>();
    _store.init();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: context.l10n.recipesTitle,
        actions: <Widget>[
          Observer(
            builder: (_) => IconButton(
              tooltip: context.l10n.refresh,
              onPressed: _store.status == RecipeListStatus.loading
                  ? null
                  : _store.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          Observer(
            builder: (_) => _store.isFavoritesTab
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: context.l10n.recipesFilters,
                    onPressed: () => _showFilters(context),
                    icon: const Icon(Icons.tune_rounded),
                  ),
          ),
        ],
        body: Observer(
          builder: (_) => Column(
            children: <Widget>[
              _RecipeTabs(store: _store),
              if (!_store.isFavoritesTab) _SearchBox(store: _store),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      );

  Widget _buildContent(BuildContext context) {
    if (_store.status == RecipeListStatus.loading && _store.recipes.isEmpty) {
      return const AppLoadingView();
    }
    if (_store.isFirstLoadError) {
      return AppErrorView(message: _store.error?.message, onRetry: _store.refresh);
    }
    if (_store.isEmptyResult) {
      return AppEmptyView(
        icon: _store.isFavoritesTab
            ? Icons.favorite_border_rounded
            : Icons.search_off_rounded,
        message: _store.isFavoritesTab
            ? context.l10n.recipesNoFavorites
            : context.l10n.recipesNoResults,
      );
    }
    return Column(
      children: <Widget>[
        if (_store.status == RecipeListStatus.loading)
          const LinearProgressIndicator(minHeight: 2),
        if (_store.error != null && _store.recipes.isNotEmpty)
          _InlineError(message: _store.error!.message, onRetry: _store.refresh),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _store.refresh,
            child: GridView.builder(
              padding: const EdgeInsets.all(AppDimens.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppDimens.sm,
                mainAxisSpacing: AppDimens.sm,
                childAspectRatio: 0.64,
              ),
              itemCount: _store.recipes.length +
                  (_store.hasMore || _store.favoritesListDirty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _store.recipes.length) {
                  final recipe = _store.recipes[index];
                  return _RecipeCard(
                    recipe: recipe,
                    isFavoritePending: _store.isFavoritePending(recipe.id),
                    onOpen: () => Get.toNamed(
                      AppRoutes.recipeDetail.replaceFirst(':id', recipe.id),
                    ),
                    onToggleFavorite: () => _store.toggleFavorite(recipe.id),
                  );
                }
                if (_store.favoritesListDirty) {
                  return _ReloadCard(
                    message: context.l10n.recipesListChanged,
                    label: context.l10n.recipesReload,
                    onPressed: _store.refresh,
                  );
                }
                return _LoadMoreCard(
                  isLoading: _store.status == RecipeListStatus.loadingMore,
                  label: context.l10n.recipesLoadMore,
                  onPressed: _store.loadMore,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    String? dietType = _store.dietType;
    String? difficulty = _store.difficulty;
    int? maxPrepTime = _store.maxPrepTime;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.md,
            AppDimens.lg,
            AppDimens.md,
            AppDimens.md + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String?>(
                initialValue: dietType,
                decoration: InputDecoration(labelText: context.l10n.recipesFilterDiet),
                items: <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(context.l10n.all),
                  ),
                  ..._dietTypes(context).entries.map(
                        (entry) => DropdownMenuItem<String?>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      ),
                ],
                onChanged: (value) => setSheetState(() => dietType = value),
              ),
              const SizedBox(height: AppDimens.sm),
              DropdownButtonFormField<String?>(
                initialValue: difficulty,
                decoration: InputDecoration(
                  labelText: context.l10n.recipesFilterDifficulty,
                ),
                items: <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(context.l10n.all),
                  ),
                  ..._difficultyLabels(context).entries.map(
                        (entry) => DropdownMenuItem<String?>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      ),
                ],
                onChanged: (value) => setSheetState(() => difficulty = value),
              ),
              const SizedBox(height: AppDimens.sm),
              DropdownButtonFormField<int?>(
                initialValue: maxPrepTime,
                decoration: InputDecoration(
                  labelText: context.l10n.recipesFilterPrepTime,
                ),
                items: <DropdownMenuItem<int?>>[
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(context.l10n.all),
                  ),
                  const DropdownMenuItem<int?>(value: 15, child: Text('≤15')),
                  const DropdownMenuItem<int?>(value: 30, child: Text('≤30')),
                  const DropdownMenuItem<int?>(value: 60, child: Text('≤60')),
                ],
                onChanged: (value) => setSheetState(() => maxPrepTime = value),
              ),
              const SizedBox(height: AppDimens.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _store.setFilters(
                      dietType: dietType,
                      difficulty: difficulty,
                      maxPrepTime: maxPrepTime,
                    );
                    Navigator.pop(sheetContext);
                  },
                  child: Text(context.l10n.saveChanges),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeTabs extends StatelessWidget {
  const _RecipeTabs({required this.store});

  final RecipeStore store;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.md,
          AppDimens.sm,
          AppDimens.md,
          0,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _TabButton(
                label: context.l10n.recipesAll,
                selected: store.tab == RecipeListTab.all,
                onTap: () => store.setTab(RecipeListTab.all),
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Expanded(
              child: _TabButton(
                label: context.l10n.recipesFavorites,
                selected: store.tab == RecipeListTab.favorites,
                onTap: () => store.setTab(RecipeListTab.favorites),
              ),
            ),
          ],
        ),
      );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.sage : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(
              color: selected ? AppColors.sage : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.store});

  final RecipeStore store;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.md,
          AppDimens.sm,
          AppDimens.md,
          0,
        ),
        child: TextField(
          onChanged: store.setSearchQuery,
          decoration: InputDecoration(
            hintText: context.l10n.recipesSearch,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppDimens.sm,
              horizontal: AppDimens.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.isFavoritePending,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final Recipe recipe;
  final bool isFavoritePending;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(child: _RecipeArtwork(recipe: recipe)),
                      Positioned(
                        top: AppDimens.xs,
                        right: AppDimens.xs,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: isFavoritePending ? null : onToggleFavorite,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: isFavoritePending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.sage,
                                      ),
                                    )
                                  : Icon(
                                      recipe.favorite.myFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 18,
                                      color: recipe.favorite.myFavorite
                                          ? AppColors.error
                                          : AppColors.textSecondary,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        recipe.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _meta(context, recipe),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: <Widget>[
                          if (recipe.difficulty != null)
                            _Badge(
                              label: _difficultyLabel(
                                  context, recipe.difficulty!),
                            ),
                          for (final diet in recipe.dietTypes.take(1))
                            _Badge(
                              label: _dietLabel(context, diet),
                              color: AppColors.sageLight,
                              textColor: AppColors.sageDark,
                            ),
                          if (recipe.favorite.avgRating != null)
                            _Badge(
                              label:
                                  '★ ${recipe.favorite.avgRating!.toStringAsFixed(1)}',
                              color: const Color(0xFFFFF7E0),
                              textColor: const Color(0xFFD97706),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RecipeArtwork extends StatelessWidget {
  const _RecipeArtwork({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final imageUrl = recipe.thumbnailUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return const _RecipeArtworkFallback();
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusMd),
      ),
      child: AppCachedImage(
        url: imageUrl,
        width: double.infinity,
        height: double.infinity,
        shape: AppCachedImageShape.rectangle,
        borderRadius: BorderRadius.zero,
        placeholderIcon: Icons.restaurant_menu_rounded,
        errorIcon: Icons.restaurant_menu_rounded,
      ),
    );
  }
}

class _RecipeArtworkFallback extends StatelessWidget {
  const _RecipeArtworkFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sageLight,
        ),
        child: Center(
          child: Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.sage,
            size: 32,
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.color,
    this.textColor,
  });

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color ?? AppColors.secondaryFill,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor ?? AppColors.textSecondary,
          ),
        ),
      );
}

class _LoadMoreCard extends StatelessWidget {
  const _LoadMoreCard({required this.isLoading, required this.label, required this.onPressed});

  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
      );
}

class _ReloadCard extends StatelessWidget {
  const _ReloadCard({required this.message, required this.label, required this.onPressed});

  final String message;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message, textAlign: TextAlign.center),
              TextButton(onPressed: onPressed, child: Text(label)),
            ],
          ),
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MaterialBanner(
        content: Text(message),
        actions: <Widget>[TextButton(onPressed: onRetry, child: Text(context.l10n.retry))],
      );
}

Map<String, String> _dietTypes(BuildContext context) => <String, String>{
      'NONE': context.l10n.dietTypeNone,
      'KETO': context.l10n.dietTypeKeto,
      'VEGETARIAN': context.l10n.dietTypeVegetarian,
      'VEGAN': context.l10n.dietTypeVegan,
      'PESCATARIAN': context.l10n.dietTypePescatarian,
      'GLUTEN_FREE': context.l10n.dietTypeGlutenFree,
      'DIABETIC': context.l10n.dietTypeDiabetic,
    };

Map<String, String> _difficultyLabels(BuildContext context) => <String, String>{
      'EASY': context.l10n.recipeDifficultyEasy,
      'MEDIUM': context.l10n.recipeDifficultyMedium,
      'HARD': context.l10n.recipeDifficultyHard,
    };

String _dietLabel(BuildContext context, String value) => _dietTypes(context)[value] ?? value;
String _difficultyLabel(BuildContext context, String value) =>
    _difficultyLabels(context)[value] ?? value;

String _meta(BuildContext context, Recipe recipe) {
  final parts = <String>[];
  if (recipe.prepTimeMinutes != null) parts.add(context.l10n.homeRecipeMinutes(recipe.prepTimeMinutes!));
  if (recipe.cuisine != null && recipe.cuisine!.isNotEmpty) parts.add(recipe.cuisine!);
  return parts.join(' · ');
}
