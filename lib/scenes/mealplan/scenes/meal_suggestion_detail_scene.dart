import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../data/meal_plan_api.dart';
import '../domain/shopping_list_sink.dart';
import '../../shopping/domain/shopping_list_sink_impl.dart';
import '../../shopping/stores/shopping_store.dart';
import '../stores/meal_plan_store.dart';
import '../stores/suggestion_store.dart';
import '../widgets/suggestion_card.dart';

/// Chi tiết 1 suggestion (FE-7 §12). Route chỉ từ dish VOTING.
/// Hiển thị: SuggestionCard đầy đủ + AllergenBanner + nút Accept/Reject/Re-roll.
class MealSuggestionDetailScene extends StatefulWidget {
  const MealSuggestionDetailScene({super.key});

  @override
  State<MealSuggestionDetailScene> createState() =>
      _MealSuggestionDetailSceneState();
}

class _MealSuggestionDetailSceneState extends State<MealSuggestionDetailScene> {
  late final SuggestionStore _store;

  @override
  void initState() {
    super.initState();
    final slotId = Get.parameters['slotId']!;
    final dishId = Get.parameters['dishId']!;
    _store = SuggestionStore(
      slotId: slotId,
      dishId: dishId,
      mealPlanStore: Get.find<MealPlanStore>(),
      api: Get.find<MealPlanApi>(),
      shoppingSink: Get.isRegistered<ShoppingStore>()
          ? ShoppingListSinkImpl(Get.find<ShoppingStore>())
          : const NoOpShoppingListSink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.mealplanSuggestionsTitle,
      body: Observer(
        builder: (_) {
          final suggestion = _store.currentSuggestion;
          if (_store.suggestionsUnavailable) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppEmptyView(
                    icon: Icons.cloud_off,
                    message: context.l10n.mealplanSuggestionsUnavailable,
                  ),
                  const SizedBox(height: AppDimens.md),
                  AppButton(
                    label: context.l10n.refresh,
                    expanded: false,
                    icon: Icons.refresh,
                    onPressed: () => _store.refreshSuggestions(),
                  ),
                ],
              ),
            );
          }
          if (suggestion == null) {
            return AppEmptyView(
              icon: Icons.search_off,
              message: context.l10n.mealplanSuggestionsExhausted,
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity <= -240) {
                      _store.viewNext();
                    } else if (velocity >= 240) {
                      _store.viewPrevious();
                    }
                  },
                  child: SuggestionCard(suggestion: suggestion),
                ),
                _SuggestionPager(
                  current: _store.index + 1,
                  total: _store.suggestionCount,
                  canGoPrevious: _store.hasPrevious,
                  canGoNext: _store.hasNext,
                  onPrevious: _store.viewPrevious,
                  onNext: _store.viewNext,
                ),
                if (suggestion.missingIngredients.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppDimens.md),
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.md),
                    child: AppButton(
                      label: context.l10n.mealplanAddShoppingList,
                      variant: AppButtonVariant.secondary,
                      icon: Icons.shopping_cart_outlined,
                      onPressed: _store.addMissingToShoppingList,
                    ),
                  ),
                ],
                Observer(
                  builder: (_) => _store.actionError != null
                      ? Padding(
                          padding: const EdgeInsets.all(AppDimens.sm),
                          child: Text(
                            _store.actionError!.message,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.md),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: AppButton(
                          label: context.l10n.skip,
                          variant: AppButtonVariant.secondary,
                          icon: Icons.close,
                          onPressed:
                              _store.actionStatus ==
                                      SuggestionActionStatus.accepting
                                  ? null
                                  : () => _store.rejectSuggestion(),
                        ),
                      ),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: AppButton(
                          label: context.l10n.mealplanChooseDish,
                          icon: Icons.check,
                          isLoading: _store.actionStatus ==
                              SuggestionActionStatus.accepting,
                          onPressed: _store.actionStatus ==
                                  SuggestionActionStatus.accepting
                              ? null
                              : () async {
                                  final ok = await _store.acceptSuggestion();
                                  if (!mounted) return;
                                  if (ok) {
                                    Get.back<void>();
                                  } else {
                                    if (!context.mounted) return;
                                    Get.snackbar(
                                      context.l10n.mealplanUnableToChoose,
                                      context.l10n.mealplanActionRolledBack,
                                    );
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuggestionPager extends StatelessWidget {
  const _SuggestionPager({
    required this.current,
    required this.total,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final int current;
  final int total;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md, vertical: AppDimens.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _PagerButton(
              icon: Icons.arrow_back_rounded,
              enabled: canGoPrevious,
              onPressed: onPrevious,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
              child: Text(
                '$current/$total',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            _PagerButton(
              icon: Icons.arrow_forward_rounded,
              enabled: canGoNext,
              onPressed: onNext,
            ),
          ],
        ),
      );
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: enabled ? AppColors.primaryLight : AppColors.secondaryFill,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon),
          color: enabled ? AppColors.primaryDark : AppColors.textDisabled,
        ),
      );
}
