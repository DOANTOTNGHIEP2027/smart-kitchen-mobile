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

class _MealSuggestionDetailSceneState extends State<MealSuggestionDetailScene>
    with WidgetsBindingObserver {
  late final SuggestionStore _store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _store.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: context.l10n.mealplanSuggestionsTitle,
        body: Observer(builder: (_) {
          final suggestion = _store.currentSuggestion;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_store.outcomeUnknown) _recovery(context),
                if (_store.isReading) const LinearProgressIndicator(),
                if (_store.actionError != null && !_store.outcomeUnknown)
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.sm),
                    child: Text(
                      _store.actionError?.code ==
                              'ERR_PLAN_SUGGESTION_NOT_FOUND'
                          ? context.l10n.mealplanSuggestionsChanged
                          : apiErrorMessage(context.l10n, _store.actionError),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                if (suggestion == null && !_store.loading)
                  AppEmptyView(
                    icon: _store.suggestionsUnavailable
                        ? Icons.cloud_off
                        : Icons.restaurant_menu,
                    message: _store.suggestionsUnavailable
                        ? context.l10n.mealplanSuggestionsUnavailable
                        : context.l10n.mealplanSuggestionsExhausted,
                  ),
                if (suggestion != null) ...[
                  if (suggestion.isBlocked)
                    Text(
                        context.l10n.planningCandidateBlocked(
                            suggestion.blockedReason ??
                                context.l10n.planningCandidateBlockedUnknown),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (_store.actionStatus != SuggestionActionStatus.idle) {
                        return;
                      }
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity <= -240) _store.viewNext();
                      if (velocity >= 240) _store.viewPrevious();
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
                ],
                if (!_store.outcomeUnknown)
                  AppButton(
                    label: context.l10n.mealplanReadAgain,
                    variant: AppButtonVariant.secondary,
                    onPressed: _store.isReading ? null : _store.load,
                  ),
                const SizedBox(height: AppDimens.sm),
                AppButton(
                  label: context.l10n.mealPlanGenerateSuggestions,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.refresh,
                  isLoading:
                      _store.actionStatus == SuggestionActionStatus.rerolling,
                  onPressed: _store.canWrite ? _store.refreshSuggestions : null,
                ),
                if (suggestion != null) ...[
                  if (suggestion.missingIngredients.isNotEmpty)
                    AppButton(
                      label: context.l10n.mealplanAddShoppingList,
                      variant: AppButtonVariant.secondary,
                      icon: Icons.shopping_cart_outlined,
                      onPressed: !_store.outcomeUnknown &&
                              _store.actionStatus == SuggestionActionStatus.idle
                          ? () => _addMissingToShopping(context)
                          : null,
                    ),
                  const SizedBox(height: AppDimens.sm),
                  Row(children: [
                    Expanded(
                        child: AppButton(
                      label: context.l10n.skip,
                      variant: AppButtonVariant.secondary,
                      onPressed:
                          _store.actionStatus == SuggestionActionStatus.idle
                              ? _store.rejectSuggestion
                              : null,
                    )),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                        child: AppButton(
                      label: context.l10n.mealplanChooseDish,
                      icon: Icons.check,
                      isLoading: _store.actionStatus ==
                          SuggestionActionStatus.accepting,
                      onPressed: _store.canWrite && !suggestion.isBlocked
                          ? () async {
                              final ok = await _store.acceptSuggestion();
                              if (ok && mounted) Get.back<void>();
                            }
                          : null,
                    )),
                  ]),
                ],
              ],
            ),
          );
        }),
      );

  Widget _recovery(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.l10n.mealplanOutcomeUnknown),
            if (_store.readError != null)
              Text(apiErrorMessage(context.l10n, _store.readError),
                  style: const TextStyle(color: AppColors.error)),
            AppButton(
              label: context.l10n.mealplanReadAgain,
              variant: AppButtonVariant.secondary,
              isLoading: _store.isReading,
              onPressed: _store.isReading ? null : _store.recheck,
            ),
            AppButton(
              label: context.l10n.mealplanContinueSnapshot,
              onPressed:
                  _store.canContinue ? _store.continueFromSnapshot : null,
            ),
          ]),
        ),
      );

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
