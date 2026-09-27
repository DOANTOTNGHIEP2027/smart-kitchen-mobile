import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_state_view.dart';
import '../domain/recipe.dart';
import '../stores/recipe_detail_store.dart';

class RecipeDetailScene extends StatefulWidget {
  const RecipeDetailScene({super.key, required this.recipeId});

  final String recipeId;

  @override
  State<RecipeDetailScene> createState() => _RecipeDetailSceneState();
}

class _RecipeDetailSceneState extends State<RecipeDetailScene> {
  late final RecipeDetailStore _store;

  @override
  void initState() {
    super.initState();
    _store = Get.find<RecipeDetailStore>(tag: widget.recipeId);
    _store.load();
  }

  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) => AppScaffold(
          title: context.l10n.homeRecipeDetailTitle,
          actions: <Widget>[
            IconButton(
              tooltip: context.l10n.recipesFavorites,
              onPressed: _store.recipe == null || _store.isMutatingFavorite
                  ? null
                  : _store.toggleFavorite,
              icon: _store.isMutatingFavorite
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _store.recipe?.favorite.myFavorite == true
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _store.recipe?.favorite.myFavorite == true
                          ? AppColors.error
                          : null,
                    ),
            ),
          ],
          body: AppStateView<Recipe>(
            state: _store.state,
            onRetry: _store.load,
            successBuilder: (context, recipe) => _RecipeDetailBody(
              recipe: recipe,
              store: _store,
            ),
          ),
        ),
      );
}

class _RecipeDetailBody extends StatelessWidget {
  const _RecipeDetailBody({required this.recipe, required this.store});

  final Recipe recipe;
  final RecipeDetailStore store;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(AppDimens.md),
        children: <Widget>[
          _Header(recipe: recipe),
          if (store.mutationError != null) ...<Widget>[
            const SizedBox(height: AppDimens.sm),
            MaterialBanner(
              content: Text(store.mutationError!.message),
              actions: <Widget>[
                TextButton(
                  onPressed: store.load,
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          ],
          if (recipe.nutrition != null) ...<Widget>[
            const SizedBox(height: AppDimens.lg),
            _SectionTitle(title: context.l10n.recipeNutrition),
            _NutritionCard(nutrition: recipe.nutrition!),
          ],
          const SizedBox(height: AppDimens.lg),
          _SectionTitle(title: context.l10n.recipeIngredients),
          _Ingredients(ingredients: recipe.ingredients),
          const SizedBox(height: AppDimens.lg),
          _SectionTitle(title: context.l10n.recipeSteps),
          _Steps(steps: recipe.steps),
          const SizedBox(height: AppDimens.lg),
          _RatingCard(recipe: recipe, store: store),
          const SizedBox(height: AppDimens.xl),
          if (recipe.hasSteps)
            AppButton(
              label: context.l10n.recipeStartCooking,
              icon: Icons.restaurant_rounded,
              onPressed: store.startCooking,
            )
          else
            _NoStepsNotice(message: context.l10n.recipeNoSteps),
        ],
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DetailArtwork(recipe: recipe),
          const SizedBox(height: AppDimens.md),
          Text(
            recipe.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppDimens.xs),
          Wrap(
            spacing: AppDimens.sm,
            runSpacing: AppDimens.xs,
            children: <Widget>[
              if (recipe.prepTimeMinutes != null)
                _InfoChip(label: context.l10n.recipePrepTime(recipe.prepTimeMinutes!)),
              if (recipe.cookTimeMinutes != null)
                _InfoChip(label: context.l10n.recipeCookTime(recipe.cookTimeMinutes!)),
              if (recipe.serves != null)
                _InfoChip(label: context.l10n.recipeServes(recipe.serves!)),
              if (recipe.difficulty != null)
                _InfoChip(label: _difficultyLabel(context, recipe.difficulty!)),
            ],
          ),
          if (recipe.cuisine != null && recipe.cuisine!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppDimens.sm),
            Text(recipe.cuisine!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (recipe.favorite.favoriteCount > 0 || recipe.favorite.avgRating != null) ...<Widget>[
            const SizedBox(height: AppDimens.sm),
            Wrap(
              spacing: AppDimens.sm,
              children: <Widget>[
                if (recipe.favorite.favoriteCount > 0)
                  Text(
                    context.l10n.recipeHouseholdFavorites(recipe.favorite.favoriteCount),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (recipe.favorite.avgRating != null)
                  Text(
                    '★ ${recipe.favorite.avgRating!.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ],
      );
}

class _DetailArtwork extends StatelessWidget {
  const _DetailArtwork({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 64,
          color: AppColors.primaryDark,
        ),
      ),
    );
    final imageUrl = recipe.thumbnailUrl;
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: imageUrl == null || imageUrl.isEmpty
            ? placeholder
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
      );
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.nutrition});

  final RecipeNutrition nutrition;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Wrap(
            spacing: AppDimens.lg,
            runSpacing: AppDimens.sm,
            children: <Widget>[
              if (nutrition.calories != null) Text('${nutrition.calories!.round()} kcal'),
              if (nutrition.proteinG != null) Text('P ${nutrition.proteinG!.toStringAsFixed(1)}g'),
              if (nutrition.fatG != null) Text('F ${nutrition.fatG!.toStringAsFixed(1)}g'),
              if (nutrition.carbsG != null) Text('C ${nutrition.carbsG!.toStringAsFixed(1)}g'),
            ],
          ),
        ),
      );
}

class _Ingredients extends StatelessWidget {
  const _Ingredients({required this.ingredients});

  final List<RecipeIngredient>? ingredients;

  @override
  Widget build(BuildContext context) {
    final values = ingredients;
    if (values == null || values.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Column(
        children: values
            .map(
              (ingredient) => ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: Text(ingredient.name),
                subtitle: ingredient.note == null ? null : Text(ingredient.note!),
                trailing: ingredient.quantity == null
                    ? null
                    : Text(_quantity(ingredient.quantity!, ingredient.unit)),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.steps});

  final List<RecipeStep>? steps;

  @override
  Widget build(BuildContext context) {
    final values = steps;
    if (values == null || values.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Column(
        children: values
            .map(
              (step) => ListTile(
                leading: CircleAvatar(child: Text('${step.stepNumber}')),
                title: Text(step.instruction),
                subtitle: step.durationMinutes == null
                    ? null
                    : Text(context.l10n.cookingSuggestedDuration(step.durationMinutes!)),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.recipe, required this.store});

  final Recipe recipe;
  final RecipeDetailStore store;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.recipeYourRating,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppDimens.xs),
              Row(
                children: List<Widget>.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    tooltip: '$value',
                    onPressed: store.isMutatingRating
                        ? null
                        : () => store.setRating(value),
                    icon: Icon(
                      (recipe.favorite.myRating ?? 0) >= value
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.secondary,
                    ),
                  );
                }),
              ),
              if (recipe.favorite.myRating != null)
                TextButton(
                  onPressed: store.isMutatingRating ? null : () => store.setRating(null),
                  child: Text(context.l10n.recipeClearRating),
                ),
            ],
          ),
        ),
      );
}

class _NoStepsNotice extends StatelessWidget {
  const _NoStepsNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark),
            const SizedBox(width: AppDimens.sm),
            Expanded(child: Text(message)),
          ],
        ),
      );
}

String _difficultyLabel(BuildContext context, String value) => switch (value) {
      'EASY' => context.l10n.recipeDifficultyEasy,
      'MEDIUM' => context.l10n.recipeDifficultyMedium,
      'HARD' => context.l10n.recipeDifficultyHard,
      _ => value,
    };

String _quantity(double quantity, String? unit) {
  final text = quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();
  return unit == null || unit.isEmpty ? text : '$text $unit';
}
