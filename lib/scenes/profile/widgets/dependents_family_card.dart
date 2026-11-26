import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../routing/app_routes.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/states/view_state.dart';
import '../domain/dependent_summary.dart';
import '../stores/dependent_store.dart';
import 'dependent_row.dart';

/// Card "Người phụ thuộc" trong FamilyScreen (§8.1, §16.7) — đặt DƯỚI
/// "Household plan" strip (Guard 12). Tap bất kỳ trạng thái nào → list; nút
/// thêm thật nằm trong DependentListScreen.
class DependentsFamilyCard extends StatelessWidget {
  const DependentsFamilyCard({super.key, required this.store});

  final DependentStore store;

  void _open() => Get.toNamed<void>(AppRoutes.dependents);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Observer(builder: (_) {
      final state = store.listState;
      final canAdd = store.canAdd;
      final isOwner = store.isOwner;
      final Widget subtitle;
      Widget? trailing;
      var needsGuardian = false;
      switch (state) {
        case SuccessState<List<DependentSummary>>(:final data):
          subtitle = Text(
            data.isEmpty
                ? l10n.dependentCardEmpty
                : l10n.dependentCardCount(data.length),
            key: const ValueKey<String>('family-dependents-subtitle'),
            style: theme.textTheme.bodySmall,
          );
          needsGuardian = isOwner && data.any((d) => !d.guardianActive);
          final addFirst = canAdd && data.isEmpty;
          trailing = Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (addFirst)
                Icon(Icons.add_rounded,
                    size: 18, color: theme.colorScheme.primary),
              Text(
                addFirst
                    ? l10n.dependentAddProfile
                    : (canAdd
                        ? l10n.dependentCardViewAll
                        : l10n.dependentCardView),
                key: const ValueKey<String>('family-dependents-action'),
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          );
        case ErrorState<List<DependentSummary>>():
          subtitle = Text(
            l10n.dependentLoadFailed,
            key: const ValueKey<String>('family-dependents-error'),
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
          );
          trailing = TextButton(
            key: const ValueKey<String>('family-dependents-retry'),
            onPressed: () => store.loadDependents(),
            child: Text(l10n.commonRetry),
          );
        case LoadingState<List<DependentSummary>>() ||
              EmptyState<List<DependentSummary>>():
          subtitle = const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              key: ValueKey<String>('family-dependents-loading'),
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
      }
      final trailingWidget = trailing;
      return AppCard(
        onTap: _open,
        child: Row(
          children: <Widget>[
            const Icon(Icons.child_care_rounded, color: AppColors.sage),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.dependentListTitle,
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  subtitle,
                  if (needsGuardian) ...<Widget>[
                    const SizedBox(height: AppDimens.xs),
                    const GuardianInactiveTag(
                        key: ValueKey<String>('family-dependents-inactive')),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) trailingWidget,
          ],
        ),
      );
    });
  }
}
