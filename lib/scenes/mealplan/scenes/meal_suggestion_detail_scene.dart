import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../domain/shopping_list_sink.dart';
import '../../shopping/scenes/shopping_list_binding.dart';
import '../../shell/app_shell_store.dart';
import '../../../routing/app_routes.dart';
import '../stores/meal_plan_store.dart';
import '../stores/suggestion_store.dart';
import '../widgets/suggestion_card.dart';

/// Chi tiết gợi ý đã lưu của một món, độc lập với trạng thái attendance.
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
      shoppingSink: _shoppingSink(),
    );
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.mealplanSuggestionsTitle,
      body: Observer(
        builder: (_) {
          if (_store.loading) {
            return const Center(child: CircularProgressIndicator());
          }
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
                    isLoading:
                        _store.actionStatus == SuggestionActionStatus.rerolling,
                    onPressed:
                        _store.actionStatus != SuggestionActionStatus.idle
                            ? null
                            : () => _store.refreshSuggestions(),
                  ),
                ],
              ),
            );
          }
          if (suggestion == null) {
            return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(context.l10n.mealplanSuggestionsExhausted),
              AppButton(
                  label: context.l10n.mealPlanGenerateSuggestions,
                  expanded: false,
                  isLoading:
                      _store.actionStatus == SuggestionActionStatus.rerolling,
                  onPressed: _store.actionStatus != SuggestionActionStatus.idle
                      ? null
                      : () => _store.refreshSuggestions()),
            ]));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (suggestion.isBlocked)
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                          context.l10n.planningCandidateBlocked(
                              suggestion.blockedReason ??
                                  context.l10n.planningCandidateBlockedUnknown),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (_store.actionStatus != SuggestionActionStatus.idle)
                      return;
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
                  canGoPrevious: _store.hasPrevious &&
                      _store.actionStatus == SuggestionActionStatus.idle,
                  canGoNext: _store.hasNext &&
                      _store.actionStatus == SuggestionActionStatus.idle,
                  onPrevious: _store.viewPrevious,
                  onNext: _store.viewNext,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.md),
                  child: AppButton(
                    label: context.l10n.mealPlanGenerateSuggestions,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.refresh,
                    isLoading:
                        _store.actionStatus == SuggestionActionStatus.rerolling,
                    onPressed:
                        _store.actionStatus != SuggestionActionStatus.idle
                            ? null
                            : () => _store.refreshSuggestions(),
                  ),
                ),
                if (suggestion.missingIngredients.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppDimens.md),
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.md),
                    child: AppButton(
                      label: context.l10n.mealplanAddShoppingList,
                      variant: AppButtonVariant.secondary,
                      icon: Icons.shopping_cart_outlined,
                      onPressed: () => _addMissingToShopping(context),
                    ),
                  ),
                ],
                Observer(
                  builder: (_) => _store.actionError != null
                      ? Padding(
                          padding: const EdgeInsets.all(AppDimens.sm),
                          child: Text(
                            apiErrorMessage(context.l10n, _store.actionError),
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
                              _store.actionStatus != SuggestionActionStatus.idle
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
                          onPressed: suggestion.isBlocked ||
                                  _store.actionStatus !=
                                      SuggestionActionStatus.idle
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

  ShoppingListSink _shoppingSink() {
    // Suggestion detail cũng có thể được mở trực tiếp qua deep-link, không chỉ
    // từ IndexedStack shell. Binding bảo đảm luôn có sink thật trong cả hai.
    ShoppingListBinding().dependencies();
    return Get.find<ShoppingListSink>();
  }

  Future<void> _addMissingToShopping(BuildContext context) async {
    final count = await _store.addMissingToShoppingList();
    if (!context.mounted) return;
    if (count == 0) {
      Get.snackbar(
        context.l10n.unavailable,
        context.l10n.mealplanShoppingListUnavailable,
      );
      return;
    }
    if (Get.isRegistered<AppShellStore>()) {
      Get.back<void>();
      Get.find<AppShellStore>().selectTab(3);
    } else {
      await Get.offNamed<void>(AppRoutes.shopping);
    }
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
