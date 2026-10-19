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
import '../domain/repetition_summary.dart';
import '../stores/repetition_store.dart';
import '../widgets/repetition_bar_chart.dart';

/// Món lặp lại trong rolling window 7/14 ngày (flexible-meal-planning-screens.md
/// §8.4). Danh sách rỗng là kết quả TÍCH CỰC, không phải lỗi.
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
          Expanded(
            child: Observer(
              builder: (_) => AppStateView<RepetitionSummary>(
                state: _store.summaryState,
                onRetry: _store.load,
                successBuilder: (_, summary) => summary.repeatedDishes.isEmpty
                    ? AppEmptyView(
                        key: const ValueKey<String>('repetition-empty'),
                        icon: Icons.celebration_outlined,
                        message: l10n.planningRepetitionEmpty(summary.windowDays),
                      )
                    : _SummaryList(summary: summary),
              ),
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
    final dateFormat = DateFormat('dd/MM');
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, 0, AppDimens.md, AppDimens.lg),
      children: <Widget>[
        AppCard(
          child: SizedBox(
            height: 200,
            child: RepetitionBarChart(dishes: summary.repeatedDishes),
          ),
        ),
        const SizedBox(height: AppDimens.md),
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
                trailing: Text(
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
