import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/env_config.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../demo/fixtures/demo_fixtures.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../cooking/scenes/cooking_routes.dart';
import '../mealplan/widgets/recipe_cover_image.dart';
import 'app_shell_store.dart';

/// Chi tiết recipe chỉ dành cho lối vào demo trên Home.
///
/// Màn này đọc metadata trình bày từ [DemoFixtures], rồi chỉ tạo cooking
/// session khi người dùng bấm CTA. Không thay đổi contract recipe của backend
/// thật hay luồng start/resume trong feature Cooking.
class HomeRecipeDetailScene extends StatelessWidget {
  const HomeRecipeDetailScene({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final recipe = DemoFixtures.recipe(recipeId);
    final recipeName = recipe['recipeName']! as String;
    final description = recipe['description']! as String;
    final ingredients = (recipe['ingredients'] as List<dynamic>? ??
            const <dynamic>[])
        .whereType<String>()
        .toList(growable: false);
    final tags =
        (recipe['tags'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList(growable: false);
    final prepTimeMinutes = recipe['prepTimeMinutes']! as int;
    final calories = recipe['calories']! as int;
    final guideUrl = recipe['guideUrl']! as String;

    return AppScaffold(
      title: context.l10n.homeRecipeDetailTitle,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.lg, AppDimens.md, AppDimens.lg, AppDimens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                child: RecipeCoverImage(
                  recipeId: recipeId,
                  recipeName: recipeName,
                  height: 200,
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              Text(
                recipeName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: AppDimens.md),
              _RecipeMetaRow(
                calories: context.l10n.homeRecipeCalories(calories),
                duration: context.l10n.homeRecipeMinutes(prepTimeMinutes),
              ),
              if (tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppDimens.md),
                Wrap(
                  spacing: AppDimens.sm,
                  runSpacing: AppDimens.sm,
                  children: tags
                      .map((tag) => _TagChip(label: tag))
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: AppDimens.xl),
              Text(
                context.l10n.homeRecipeIngredients,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: AppDimens.sm),
              ...ingredients.map(
                (ingredient) => _IngredientRow(label: ingredient),
              ),
              const SizedBox(height: AppDimens.md),
              _RecipeGuide(url: guideUrl, label: context.l10n.homeRecipeGuide),
              const SizedBox(height: AppDimens.lg),
              AppButton(
                label: context.l10n.homeRecipeCook,
                icon: Icons.restaurant_rounded,
                onPressed: () {
                  if (EnvConfig.isDemoMode) {
                    Get.toNamed<void>(
                      CookingRoutes.session,
                      arguments: CookingArgs.start(recipeId),
                    );
                    return;
                  }
                  Get.back<void>();
                  Get.find<AppShellStore>().selectTab(2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeMetaRow extends StatelessWidget {
  const _RecipeMetaRow({required this.calories, required this.duration});

  final String calories;
  final String duration;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md, vertical: AppDimens.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(
            color: AppColors.border,
            width: 1.0,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Text(
              calories,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: AppDimens.lg),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Text(
              duration,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            border: Border.all(
              color: AppColors.border,
              width: 1.0,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _RecipeGuide extends StatelessWidget {
  const _RecipeGuide({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.link_rounded, color: AppColors.primary),
            const SizedBox(width: AppDimens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppDimens.xs),
                  SelectableText(
                    url,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
