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
        actions: <Widget>[
          Observer(
            builder: (_) =>
                _store.actionStatus == SuggestionActionStatus.rerolling
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppDimens.sm),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
          Observer(builder: (_) => _moreMenu(context)),
        ],
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
                if (suggestion == null &&
                    !_store.loading &&
                    !_store.outcomeUnknown) ...[
                  const SizedBox(height: AppDimens.md),
                  AppButton(
                    label: context.l10n.mealPlanGenerateSuggestions,
                    icon: Icons.auto_awesome,
                    isLoading:
                        _store.actionStatus == SuggestionActionStatus.rerolling,
                    onPressed:
                        _store.canWrite ? _store.refreshSuggestions : null,
                  ),
                ],
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
                if (suggestion != null) ...[
                  const SizedBox(height: AppDimens.sm),
                  Row(children: [
                    Expanded(
                        child: AppButton(
                      label: context.l10n.skip,
                      variant: AppButtonVariant.text,
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
                              // Đồ thiếu đẩy khi "Hoàn thành thêm món" của bữa.
                              final ok = await _store.acceptSuggestion();
                              if (!ok || !context.mounted) return;
                              Get.back<void>();
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

  /// Hành động phụ gom vào ⋮ để màn chỉ còn pager + "Chọn món" / "Bỏ qua".
  /// "Đọc lại" ẩn khi recovery card đang hiện (card đã có nút riêng).
  Widget _moreMenu(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<_DetailAction>(
      key: const ValueKey<String>('suggestion-more-actions'),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _DetailAction.reload:
            _store.load();
          case _DetailAction.regenerate:
            _store.refreshSuggestions();
        }
      },
      itemBuilder: (_) => <PopupMenuEntry<_DetailAction>>[
        if (!_store.outcomeUnknown)
          PopupMenuItem<_DetailAction>(
            value: _DetailAction.reload,
            enabled: !_store.isReading,
            child: _menuRow(Icons.sync, l10n.mealplanReadAgain),
          ),
        PopupMenuItem<_DetailAction>(
          value: _DetailAction.regenerate,
          enabled: _store.canWrite &&
              _store.actionStatus != SuggestionActionStatus.rerolling,
          child: _menuRow(Icons.refresh, l10n.mealPlanGenerateSuggestions),
        ),
      ],
    );
  }

  Widget _menuRow(IconData icon, String label) => Row(
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: AppDimens.md),
          Flexible(child: Text(label)),
        ],
      );

  Widget _recovery(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(context.l10n.mealplanOutcomeUnknown),
            if (_store.readError != null) ...[
              const SizedBox(height: AppDimens.xs),
              Text(apiErrorMessage(context.l10n, _store.readError),
                  style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: AppDimens.md),
            AppButton(
              label: context.l10n.mealplanReadAgain,
              variant: AppButtonVariant.secondary,
              isLoading: _store.isReading,
              onPressed: _store.isReading ? null : _store.recheck,
            ),
            const SizedBox(height: AppDimens.sm),
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
}

enum _DetailAction { reload, regenerate }

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
