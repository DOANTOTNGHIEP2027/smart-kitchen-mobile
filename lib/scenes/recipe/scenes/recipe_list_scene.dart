import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../routing/app_routes.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/recipe_images.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../widgets/app_cached_image.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/inputs/chip_choice_group.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../domain/recipe.dart';
import '../data/recipe_catalog_api.dart';
import '../stores/recipe_store.dart';

/// Tiền tố `ValueKey` của card recipe — harness đo #93 tìm card theo key
/// thay vì tên class private (LOW-5 review #93).
const String kRecipeCardKeyPrefix = 'recipe-card-';

class RecipeListScene extends StatefulWidget {
  const RecipeListScene({super.key, this.onSelect});
  final ValueChanged<Recipe>? onSelect;

  @override
  State<RecipeListScene> createState() => _RecipeListSceneState();
}

class _RecipeListSceneState extends State<RecipeListScene> {
  late final RecipeStore _store;

  @override
  void initState() {
    super.initState();
    _store = widget.onSelect == null
        ? Get.find<RecipeStore>()
        : RecipeStore(Get.find<RecipeCatalogApi>());
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
      return AppErrorView(
          message: apiErrorMessage(context.l10n, _store.error),
          onRetry: _store.refresh);
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
          _InlineError(
              message: apiErrorMessage(context.l10n, _store.error),
              onRetry: _store.refresh),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _store.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.md,
                    AppDimens.md,
                    AppDimens.md,
                    0,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppDimens.sm,
                      mainAxisSpacing: AppDimens.sm,
                      // #201: chiều cao ô tính theo bề rộng (ảnh 4:3) + cỡ
                      // chữ hệ thống → không tràn ở 360dp, text scale 1.3.
                      mainAxisExtent: _RecipeCard.extentFor(
                        (MediaQuery.sizeOf(context).width -
                                AppDimens.md * 2 -
                                AppDimens.sm) /
                            2,
                        MediaQuery.textScalerOf(context),
                      ),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final recipe = _store.recipes[index];
                        return _RecipeCard(
                          key: ValueKey<String>(
                              '$kRecipeCardKeyPrefix${recipe.id}'),
                          recipe: recipe,
                          isFavoritePending:
                              _store.isFavoritePending(recipe.id),
                          onOpen: widget.onSelect != null
                              ? () => widget.onSelect!(recipe)
                              : () => Get.toNamed(
                                    AppRoutes.recipeDetail
                                        .replaceFirst(':id', recipe.id),
                                  ),
                          onToggleFavorite: () =>
                              _store.toggleFavorite(recipe.id),
                        );
                      },
                      childCount: _store.recipes.length,
                    ),
                  ),
                ),
                // #201: tải thêm / tải lại nằm dưới lưới, không chiếm một ô.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.md),
                    child: _store.favoritesListDirty
                        ? _ReloadCard(
                            message: context.l10n.recipesListChanged,
                            label: context.l10n.recipesReload,
                            onPressed: _store.refresh,
                          )
                        : _store.hasMore
                            ? _LoadMoreCard(
                                isLoading: _store.status ==
                                    RecipeListStatus.loadingMore,
                                label: context.l10n.recipesLoadMore,
                                onPressed: _store.loadMore,
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
              ],
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
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        // #201: chip thay dropdown; phần chip cuộn được, nút cố định đáy.
        builder: (_, setSheetState) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.md,
                  ),
                  child: Text(
                    l10n.recipesFilters,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimens.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        ChipChoiceGroup<String>(
                          groupKey: 'recipe-filter-diet',
                          icon: Icons.eco_outlined,
                          title: l10n.recipesFilterDiet,
                          allLabel: l10n.all,
                          value: dietType,
                          options: <ChipChoiceOption<String>>[
                            for (final entry in _dietTypes(context).entries)
                              ChipChoiceOption<String>(
                                  entry.key, entry.value, entry.key),
                          ],
                          onChanged: (value) =>
                              setSheetState(() => dietType = value),
                        ),
                        const SizedBox(height: AppDimens.md),
                        ChipChoiceGroup<String>(
                          groupKey: 'recipe-filter-difficulty',
                          icon: Icons.signal_cellular_alt_rounded,
                          title: l10n.recipesFilterDifficulty,
                          allLabel: l10n.all,
                          value: difficulty,
                          options: <ChipChoiceOption<String>>[
                            for (final entry
                                in _difficultyLabels(context).entries)
                              ChipChoiceOption<String>(
                                  entry.key, entry.value, entry.key),
                          ],
                          onChanged: (value) =>
                              setSheetState(() => difficulty = value),
                        ),
                        const SizedBox(height: AppDimens.md),
                        ChipChoiceGroup<int>(
                          groupKey: 'recipe-filter-time',
                          icon: Icons.schedule_rounded,
                          title: l10n.recipesFilterPrepTime,
                          allLabel: l10n.all,
                          value: maxPrepTime,
                          options: <ChipChoiceOption<int>>[
                            for (final minutes in const <int>[15, 30, 60])
                              ChipChoiceOption<int>(
                                minutes,
                                l10n.recipesFilterMaxMinutes(minutes),
                                '$minutes',
                              ),
                          ],
                          onChanged: (value) =>
                              setSheetState(() => maxPrepTime = value),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.md,
                    0,
                    AppDimens.md,
                    AppDimens.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey<String>('recipe-filter-reset'),
                          onPressed: () => setSheetState(() {
                            dietType = null;
                            difficulty = null;
                            maxPrepTime = null;
                          }),
                          child: Text(l10n.recipesFilterReset),
                        ),
                      ),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey<String>('recipe-filter-apply'),
                          onPressed: () {
                            _store.setFilters(
                              dietType: dietType,
                              difficulty: difficulty,
                              maxPrepTime: maxPrepTime,
                            );
                            Navigator.pop(sheetContext);
                          },
                          child: Text(l10n.recipesFilterApply),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
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
    super.key,
    required this.recipe,
    required this.isFavoritePending,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  final Recipe recipe;
  final bool isFavoritePending;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;

  static const double _radius = 16;
  static const double _bodyPadding = 12;
  static const double _lineHeight = 1.25;
  static const double _titleSize = 13;
  static const double _smallSize = 11;
  static const double _metaIcon = 14;
  static const double _badgeVPadding = 3;

  /// Chiều cao ô lưới: ảnh 4:3 + thân thẻ (2 dòng tên, 1 hàng meta, 1 hàng
  /// badge) theo [textScaler]. Chữ trong thân thẻ đặt `height` cố định nên
  /// đo trước được.
  static double extentFor(double tileWidth, TextScaler textScaler) {
    final title = textScaler.scale(_titleSize) * _lineHeight * 2;
    final small = textScaler.scale(_smallSize) * _lineHeight;
    final meta = small > _metaIcon ? small : _metaIcon;
    final badge = _badgeHeight(textScaler);
    const gaps = 4 + 6 + 4; // 2 khoảng cách + dư an toàn
    return tileWidth * 3 / 4 + _bodyPadding * 2 + title + meta + badge + gaps;
  }

  static double _badgeHeight(TextScaler textScaler) =>
      textScaler.scale(_smallSize) * _lineHeight + _badgeVPadding * 2;

  @override
  Widget build(BuildContext context) {
    final totalMinutes =
        (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0);
    final calories = recipe.nutrition?.calories;
    final serves = recipe.serves;
    const smallStyle = TextStyle(
      fontSize: _smallSize,
      height: _lineHeight,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.ambientShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(child: _RecipeArtwork(recipe: recipe)),
                    if (totalMinutes > 0)
                      Positioned(
                        left: AppDimens.sm,
                        bottom: AppDimens.sm,
                        child: _TimePill(
                          label: context.l10n.homeRecipeMinutes(totalMinutes),
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _FavoriteButton(
                        isFavorite: recipe.favorite.myFavorite,
                        isPending: isFavoritePending,
                        onPressed: onToggleFavorite,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(_bodyPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: _titleSize,
                        height: _lineHeight,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        if (calories != null) ...<Widget>[
                          const Icon(Icons.local_fire_department_rounded,
                              size: _metaIcon, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              context.l10n
                                  .homeRecipeCalories(calories.round()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: smallStyle,
                            ),
                          ),
                          const SizedBox(width: AppDimens.sm),
                        ],
                        if (serves != null) ...<Widget>[
                          const Icon(Icons.people_alt_outlined,
                              size: _metaIcon, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              context.l10n.recipeCardServes(serves),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: smallStyle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Một hàng badge: badge không vừa bị cắt thay vì đẩy thẻ
                    // tràn xuống.
                    SizedBox(
                      height: _badgeHeight(MediaQuery.textScalerOf(context)),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        clipBehavior: Clip.hardEdge,
                        children: <Widget>[
                          if (recipe.difficulty != null)
                            _Badge(
                              label:
                                  _difficultyLabel(context, recipe.difficulty!),
                            ),
                          for (final diet in recipe.dietTypes.take(1))
                            _Badge(
                              label: _dietLabel(context, diet),
                              color: AppColors.sageLight,
                              textColor: AppColors.sageDark,
                            ),
                          if (recipe.favorite.avgRating != null)
                            _Badge(
                              icon: Icons.star_rounded,
                              label: recipe.favorite.avgRating!
                                  .toStringAsFixed(1),
                              color: AppColors.warningSurface,
                              textColor: AppColors.warning,
                            ),
                        ],
                      ),
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
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.isPending,
    required this.onPressed,
  });

  final bool isFavorite;
  final bool isPending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isPending ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: isPending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
          ),
        ),
      );
}

/// Pill thời gian (chuẩn bị + nấu) đè lên góc dưới trái ảnh.
class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

class _RecipeArtwork extends StatelessWidget {
  const _RecipeArtwork({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final imageUrl = recipeImageUrl(
        recipeId: recipe.id,
        recipeName: recipe.name,
        thumbnailUrl: recipe.thumbnailUrl);
    if (imageUrl == null || imageUrl.isEmpty) {
      return const _RecipeArtworkFallback();
    }
    return AppCachedImage(
      url: imageUrl,
      width: double.infinity,
      height: double.infinity,
      shape: AppCachedImageShape.rectangle,
      borderRadius: BorderRadius.zero,
      placeholderIcon: Icons.restaurant_menu_rounded,
      errorIcon: Icons.restaurant_menu_rounded,
    );
  }
}

class _RecipeArtworkFallback extends StatelessWidget {
  const _RecipeArtworkFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.primaryContainer, AppColors.primaryLight],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.ramen_dining_rounded,
            color: AppColors.primary,
            size: 44,
          ),
        ),
      );
}

/// Badge dạng pill (DESIGN_SYSTEM §4.3): radius 999, chữ 11sp w700.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.icon,
    this.color,
    this.textColor,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: _RecipeCard._badgeVPadding,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _RecipeCard._smallSize,
                height: _RecipeCard._lineHeight,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreCard extends StatelessWidget {
  const _LoadMoreCard(
      {required this.isLoading, required this.label, required this.onPressed});

  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(label),
        ),
      );
}

class _ReloadCard extends StatelessWidget {
  const _ReloadCard(
      {required this.message, required this.label, required this.onPressed});

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
        actions: <Widget>[
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry))
        ],
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

String _dietLabel(BuildContext context, String value) =>
    _dietTypes(context)[value] ?? value;
String _difficultyLabel(BuildContext context, String value) =>
    _difficultyLabels(context)[value] ?? value;
