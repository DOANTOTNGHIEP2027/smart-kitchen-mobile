import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../stores/realtime_store.dart';
import '../../../stores/session_store.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../data/vote_api.dart';
import '../domain/vote_session_summary.dart';
import '../stores/meal_plan_store.dart';
import '../stores/vote_session_store.dart';
import '../widgets/suggestion_card.dart';

/// Bottom-sheet vote session (FE-7 §12). Hiển thị danh sách suggestion + tally
/// + nút Vote / Đóng / Làm mới.
class VoteSessionScene extends StatefulWidget {
  const VoteSessionScene({super.key});

  @override
  State<VoteSessionScene> createState() => _VoteSessionSceneState();
}

class _VoteSessionSceneState extends State<VoteSessionScene> {
  late final VoteSessionStore _store;
  late final MealPlanStore _mealPlanStore;

  @override
  void initState() {
    super.initState();
    final slotId = Get.parameters['slotId']!;
    final dishId = Get.parameters['dishId']!;
    _mealPlanStore = Get.find<MealPlanStore>();
    _store = VoteSessionStore(
      slotId: slotId,
      dishId: dishId,
      mealPlanStore: _mealPlanStore,
      voteApi: Get.find<VoteApi>(),
      realtimeStore: Get.find<RealtimeStore>(),
      sessionStore: Get.find<SessionStore>(),
    );
    _store.init();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Phiên vote',
      body: Observer(
        builder: (_) {
          final session = _store.session;
          // Auto-close khi winner_selected / dish bị xoá (§8).
          if (session == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Get.back<void>();
            });
            return const AppLoadingView();
          }
          return RefreshIndicator(
            onRefresh: () => _store.refreshTally(),
            child: Column(
              children: <Widget>[
                if (session.deadlineAt != null)
                  Padding(
                    padding: const EdgeInsets.all(AppDimens.md),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.md, vertical: AppDimens.sm),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusSm),
                            ),
                            child: const Icon(Icons.how_to_vote_outlined,
                                color: AppColors.primaryDark, size: 19),
                          ),
                          const SizedBox(width: AppDimens.sm),
                          Expanded(
                            child: Text(
                              'Đóng lúc: ${session.deadlineAt!}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Icon(Icons.timer_outlined,
                              size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                if (session.suggestionsSourceDegraded &&
                    session.suggestions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppDimens.md),
                    child: Text(
                      'Phiên đã tồn tại nhưng chưa tải lại được danh sách gợi '
                      'ý. Bấm "Làm mới" hoặc chờ thành viên khác vote.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: session.suggestions.isEmpty
                      ? ListView(
                          children: const <Widget>[
                            AppEmptyView(
                              icon: Icons.how_to_vote,
                              message: 'Chưa ai vote.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: AppDimens.sm),
                          itemCount: session.suggestions.length,
                          itemBuilder: (_, int i) {
                            final suggestion = session.suggestions[i];
                            final tallyItem = session.tally
                                // ignore: always_specify_types
                                .where((VoteTallyItem t) =>
                                    t.recipeId == suggestion.recipeId)
                                .firstOrNull;
                            return Column(
                              children: <Widget>[
                                SuggestionCard(
                                  suggestion: suggestion,
                                  tallyCount: tallyItem?.count,
                                  isMyVote: session.myVote ==
                                      suggestion.recipeId,
                                  compact: true,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimens.md),
                                  child: AppButton(
                                    label: session.myVote == suggestion.recipeId
                                        ? 'Đã vote'
                                        : 'Vote',
                                    variant:
                                        session.myVote == suggestion.recipeId
                                            ? AppButtonVariant.secondary
                                            : AppButtonVariant.primary,
                                    isLoading: _store.isCasting,
                                    expanded: false,
                                    onPressed: _store.isCasting
                                        ? null
                                        : () => _store
                                            .castVote(suggestion.recipeId),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                Observer(
                  builder: (_) {
                    if (_store.castError != null) {
                      return Padding(
                        padding: const EdgeInsets.all(AppDimens.sm),
                        child: Text(
                          _store.castError!.message,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.md),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: AppButton(
                          label: 'Làm mới',
                          variant: AppButtonVariant.secondary,
                          icon: Icons.refresh,
                          onPressed: () => _store.refreshTally(),
                        ),
                      ),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: AppButton(
                          label: 'Đóng vote',
                          variant: AppButtonVariant.text,
                          onPressed: () async {
                            await _store.closeManually();
                            if (mounted) Get.back<void>();
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

/// Binding cho `/meal-plan/slot/:slotId/dish/:dishId/vote`.
class VoteSessionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<VoteApi>()) {
      Get.lazyPut<VoteApi>(() => VoteApiImpl(Get.find()));
    }
    // VoteSessionStore + MealPlanStore lookup qua Get.find trong initState.
  }
}
