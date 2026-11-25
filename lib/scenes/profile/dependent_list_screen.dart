import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/states/app_error_view.dart';
import '../../widgets/states/app_loading_view.dart';
import '../../widgets/states/state_view_layout.dart';
import '../../widgets/states/view_state.dart';
import 'dependent_error_l10n.dart';
import 'domain/dependent_summary.dart';
import 'stores/dependent_store.dart';
import 'widgets/add_dependent_sheet.dart';
import 'widgets/dependent_row.dart';
import 'widgets/stale_data_banner.dart';

/// Helper điều hướng DUY NHẤT về `/dependents` ([v1.2 review-125] MEDIUM-3,
/// Guard 20): dùng cho not-found, 404 `ERR_DEP_001` sau mutation, xoá thành
/// công. Có `/dependents` trong stack → pop về đúng nó; cold deep-link (không
/// có) → pop về route đầu rồi PUSH list — không bao giờ để màn đen.
void backToDependentList() {
  var found = false;
  Get.until((Route<dynamic> route) {
    if (route.settings.name == AppRoutes.dependents) found = true;
    return found || route.isFirst;
  });
  if (!found) Get.toNamed<void>(AppRoutes.dependents);
}

/// Điều hướng tới chi tiết — LUÔN qua `Get.toNamed` để route có
/// `settings.name` (cần cho [backToDependentList]).
void openDependentDetail(String id) => Get.toNamed<void>(
    AppRoutes.dependentDetail.replaceFirst(':dependentId', id));

/// Danh sách người phụ thuộc (§9.1, §16.12).
class DependentListScreen extends StatefulWidget {
  const DependentListScreen({super.key});

  @override
  State<DependentListScreen> createState() => _DependentListScreenState();
}

class _DependentListScreenState extends State<DependentListScreen> {
  late final DependentStore store = Get.find<DependentStore>();

  @override
  void initState() {
    super.initState();
    store.loadDependents();
    // Role đúng (ẩn "+ Thêm" cho Remote Viewer) khi vào thẳng từ Profile.
    store.ensureRoster();
  }

  Future<void> _openAddSheet() async {
    if (!store.canAdd) return;
    store.clearCreateStatus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddDependentSheet(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.dependentListTitle,
      body: Observer(builder: (_) {
        final state = store.listState;
        final fromCache = store.listFromCache;
        final canAdd = store.canAdd;
        return Column(
          children: <Widget>[
            if (fromCache)
              StaleDataBanner(onRetry: () => store.loadDependents()),
            Expanded(
              child: switch (state) {
                LoadingState<List<DependentSummary>>() ||
                EmptyState<List<DependentSummary>>() =>
                  const AppLoadingView(),
                ErrorState<List<DependentSummary>>(:final error) =>
                  AppErrorView(
                    message: dependentErrorMessage(l10n, error,
                        fallback: l10n.dependentLoadFailed),
                    onRetry: () => store.loadDependents(),
                  ),
                SuccessState<List<DependentSummary>>(:final data) =>
                  RefreshIndicator(
                    onRefresh: () => store.loadDependents(keepCurrent: true),
                    child: data.isEmpty
                        ? _scrollableEmpty(canAdd)
                        : _list(data, canAdd: canAdd),
                  ),
              },
            ),
          ],
        );
      }),
    );
  }

  /// L6 (review #125): empty phải cuộn được để RefreshIndicator kích hoạt.
  Widget _scrollableEmpty(bool canAdd) => LayoutBuilder(
        builder: (_, BoxConstraints c) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: _EmptyView(onAdd: canAdd ? _openAddSheet : null),
            ),
          ],
        ),
      );

  Widget _list(List<DependentSummary> items, {required bool canAdd}) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, AppDimens.md, AppDimens.md, AppDimens.xxl),
      children: <Widget>[
        // "✗" = không render (không phải disabled) — §16.6.
        if (canAdd) ...<Widget>[
          AppButton(
            key: const ValueKey<String>('dependent-add'),
            label: context.l10n.dependentAddProfile,
            icon: Icons.add_rounded,
            onPressed: _openAddSheet,
          ),
          const SizedBox(height: AppDimens.md),
        ],
        Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: AppColors.sageLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.health_and_safety_outlined,
                  color: AppColors.sageDark, size: 22),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Text(
                  context.l10n.dependentAllergenInfo,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.sageDark, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.md),
        for (final d in items)
          DependentRow(dependent: d, onTap: () => openDependentDetail(d.id)),
      ],
    );
  }
}

/// Empty (§9.1): tiêu đề + mô tả + CTA "+ Thêm hồ sơ" khi được phép.
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final add = onAdd;
    return StateViewLayout(
      key: const ValueKey<String>('dependent-empty'),
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
              color: AppColors.sageLight, shape: BoxShape.circle),
          child: const Icon(Icons.child_care_rounded,
              size: 36, color: AppColors.sage),
        ),
        const SizedBox(height: AppDimens.md),
        Text(l10n.dependentEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppDimens.xs),
        Text(l10n.dependentEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        if (add != null) ...<Widget>[
          const SizedBox(height: AppDimens.lg),
          AppButton(
            key: const ValueKey<String>('dependent-add'),
            label: l10n.dependentAddProfile,
            icon: Icons.add_rounded,
            expanded: false,
            onPressed: add,
          ),
        ],
      ],
    );
  }
}
