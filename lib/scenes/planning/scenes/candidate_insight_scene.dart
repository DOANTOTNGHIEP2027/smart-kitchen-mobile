import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feature_banner.dart';
import '../../../widgets/states/app_state_view.dart';
import '../../../widgets/states/view_state.dart';
import '../../profile/stores/form_status.dart';
import '../domain/meal_plan_candidate.dart';
import '../stores/candidate_store.dart';
import '../widgets/candidate_card.dart';

/// Ứng viên AI kèm trace hard/soft (flexible-meal-planning-screens.md §8.3).
/// Mở từ thẻ món → chỉ phiên của món đó; không biết phiên → cả tuần, nhóm
/// theo phiên (OD-08).
class CandidateInsightScene extends StatefulWidget {
  const CandidateInsightScene({super.key});

  @override
  State<CandidateInsightScene> createState() => _CandidateInsightSceneState();
}

class _CandidateInsightSceneState extends State<CandidateInsightScene> {
  late final CandidateStore _store;

  @override
  void initState() {
    super.initState();
    _store = Get.find<CandidateStore>();
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.planningCandidateTitle,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.md, AppDimens.md, AppDimens.md, 0),
            child: FeatureBanner(
              key: const ValueKey<String>('candidate-explainer'),
              message: l10n.planningCandidateExplainer,
              isError: false,
              margin: const EdgeInsets.only(bottom: AppDimens.sm),
            ),
          ),
          Observer(builder: (_) {
            if (_store.generateStatus != FormStatus.failure) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
              child: FeatureBanner(
                key: const ValueKey<String>('candidate-generate-error'),
                // ERR_UNKNOWN = lỗi không từ BE (vd. StateError) — message
                // tiếng Anh nội bộ, thay bằng copy l10n.
                message: _store.generateError?.code == 'ERR_UNKNOWN'
                    ? l10n.planningCandidateGenerateFailed
                    : (_store.generateError?.message ??
                        l10n.planningCandidateGenerateFailed),
                margin: const EdgeInsets.only(bottom: AppDimens.sm),
              ),
            );
          }),
          Expanded(
            child: Observer(builder: (_) {
              // Đọc observable ở đây để Observer theo dõi — successBuilder
              // chạy ngoài phạm vi theo dõi của Observer.
              final state = _store.groupsState;
              final generating = _store.isGenerating;
              // Không lọc theo phiên (chế độ cả tuần) → luôn hiện tiêu đề phiên,
              // kể cả khi chỉ có 1 nhóm, để không lẫn ứng viên của món khác.
              final weekMode = _store.sessionId == null;
              // Chỉ sinh khi món chưa có gợi ý VÀ chưa biết phiên: phiên đã mở
              // thì `vote/open` trả 409, không sinh lại được.
              final showGenerate = _store.canGenerate &&
                  weekMode &&
                  state is EmptyState<List<CandidateGroup>>;
              return Column(
                children: <Widget>[
                  Expanded(
                    child: AppStateView<List<CandidateGroup>>(
                      state: state,
                      onRetry: _store.load,
                      emptyMessage: _store.canGenerate
                          ? l10n.planningCandidateEmpty
                          : l10n.planningCandidateEmptyWeek,
                      emptyIcon: Icons.auto_awesome_outlined,
                      successBuilder: (_, groups) => _GroupList(
                        groups: groups,
                        showHeaders: weekMode || groups.length > 1,
                      ),
                    ),
                  ),
                  if (showGenerate)
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.md),
                      child: AppButton(
                        key: const ValueKey<String>('candidate-generate'),
                        label: l10n.planningCandidateGenerate,
                        icon: Icons.auto_awesome,
                        isLoading: generating,
                        onPressed: () {
                          _store.clearGenerateError();
                          _store.generate();
                        },
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({required this.groups, required this.showHeaders});

  final List<CandidateGroup> groups;
  final bool showHeaders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, 0, AppDimens.md, AppDimens.lg),
      children: <Widget>[
        for (final group in groups) ...<Widget>[
          if (showHeaders)
            Padding(
              padding: const EdgeInsets.only(
                  top: AppDimens.md, bottom: AppDimens.sm),
              child: Text(
                _sessionTitle(l10n, group),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          if (group.allBlocked)
            FeatureBanner(
              key: ValueKey<String>('candidate-all-blocked-${group.sessionId}'),
              message: l10n.planningCandidateAllBlocked,
              margin: const EdgeInsets.only(bottom: AppDimens.sm),
            ),
          for (final c in group.candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.sm),
              // Key theo id: state mở/gập không bị gán nhầm sang ứng viên khác
              // khi danh sách tải lại.
              child: CandidateCard(
                  key: ValueKey<String>('candidate-card-${c.id}'), candidate: c),
            ),
        ],
      ],
    );
  }

  static String _sessionTitle(AppLocalizations l10n, CandidateGroup group) {
    final at = group.evaluatedAt;
    return l10n.planningCandidateSession(
        at == null ? '—' : DateFormat('dd/MM HH:mm').format(at.toLocal()));
  }
}
