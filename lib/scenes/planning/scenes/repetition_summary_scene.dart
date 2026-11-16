import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/states/app_empty_view.dart';
import '../../../widgets/states/app_state_view.dart';
import '../../../widgets/states/view_state.dart';
import '../domain/repetition_summary.dart';
import '../stores/repetition_store.dart';
import '../widgets/repetition_bar_chart.dart';

/// Món đã gán lặp trong kế hoạch; range inclusive do server quyết định.
class RepetitionSummaryScene extends StatefulWidget {
  const RepetitionSummaryScene({super.key});

  @override
  State<RepetitionSummaryScene> createState() => _RepetitionSummarySceneState();
}

class _RepetitionSummarySceneState extends State<RepetitionSummaryScene> {
  late final RepetitionStore _store;

  @override
  void initState() {
    super.initState();
    _store = Get.find<RepetitionStore>();
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.planningRepetitionTitle,
      body: Column(
        children: <Widget>[
          Observer(
            builder: (_) => Padding(
              padding: const EdgeInsets.all(AppDimens.md),
              child: Wrap(
                spacing: AppDimens.sm,
                children: <Widget>[
                  for (final days in RepetitionStore.allowedWindows)
                    ChoiceChip(
                      key: ValueKey<String>('repetition-window-$days'),
                      label: Text(l10n.planningRepetitionWindow(days)),
                      selected: _store.windowDays == days,
                      selectedColor: AppColors.sageLight,
                      labelStyle: TextStyle(
                        color: _store.windowDays == days
                            ? AppColors.sageDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => _store.setWindowDays(days),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.md, 0, AppDimens.md, AppDimens.md),
            child: Text(l10n.planningRepetitionWindowHint),
          ),
          Expanded(
            child: Observer(
              builder: (_) {
                final state = _store.summaryState;
                final view = AppStateView<RepetitionSummary>(
                  state: state,
                  onRetry: _store.load,
                  successBuilder: (_, summary) =>
                      _SummaryList(summary: summary),
                );
                if (state is SuccessState<RepetitionSummary>) return view;
                // Keep retry reachable when the selector/hint or text scale
                // leaves less room than the shared error view needs.
                return LayoutBuilder(
                  builder: (_, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: view,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.summary});

  final RepetitionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // LocalDate components are already parsed; do not shift them to another zone.
    final dateFormat =
        DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return ListView(
      key: PageStorageKey<String>('repetition-list-${summary.windowDays}'),
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, 0, AppDimens.md, AppDimens.lg),
      children: <Widget>[
        Text(
          l10n.planningRepetitionRange(dateFormat.format(summary.windowStart),
              dateFormat.format(summary.windowEnd)),
          key: const ValueKey<String>('repetition-range'),
        ),
        const SizedBox(height: AppDimens.md),
        if (summary.repeatedDishes.isEmpty)
          AppEmptyView(
            key: const ValueKey<String>('repetition-empty'),
            message: l10n.planningRepetitionEmpty(summary.windowDays),
          ),
        if (summary.repeatedDishes.isNotEmpty) ...<Widget>[
          AppCard(
            child: SizedBox(
              height: 200,
              child: RepetitionBarChart(dishes: summary.repeatedDishes),
            ),
          ),
          const SizedBox(height: AppDimens.md),
        ],
        for (final dish in summary.repeatedDishes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.sm),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                key: ValueKey<String>('repetition-dish-${dish.recipeId}'),
                shape: const Border(),
                title: Text(
                  dish.recipeName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l10n.planningRepetitionCount(dish.occurrenceCount),
                  style: TextStyle(
                    color: dish.occurrenceCount >= 3
                        ? AppColors.error
                        : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                children: <Widget>[
                  for (final o in dish.occurrences)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.event_outlined, size: 18),
                      title: Text(
                          '${dateFormat.format(o.mealDate)} · ${o.slotLabel}'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
