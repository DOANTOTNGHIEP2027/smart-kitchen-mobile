import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../constants/app_dimens.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/states/app_empty_view.dart';
import '../../widgets/states/app_error_view.dart';
import '../../widgets/states/app_loading_view.dart';
import '../../widgets/states/view_state.dart';
import 'dependent_detail_screen.dart';
import 'dependent_error_l10n.dart';
import 'dependent_list_screen.dart';
import 'domain/allergen.dart';
import 'domain/dependent_health_profile.dart';
import 'domain/dependent_summary.dart';
import 'stores/dependent_store.dart';
import 'stores/form_status.dart';
import 'widgets/dependent_state_views.dart';

/// Picker dị ứng của một dependent (§9.6, §16.10) — tinh thần
/// `AllergenSelectScreen` (S11.x) bind `DependentStore`.
///
/// S-A0: `!canEditHealthOf` (chỉ đánh giá khi detail Success) → Blocked, KHÔNG
/// gọi health/catalog. Checklist chỉ seed từ health của server
/// (`canSaveAllergensFor`) — full-replace từ trạng thái chưa biết = xoá sạch dị
/// ứng (Guard 15).
class DependentAllergenSelectScreen extends StatefulWidget {
  const DependentAllergenSelectScreen({super.key, this.dependentId});

  final String? dependentId;

  @override
  State<DependentAllergenSelectScreen> createState() =>
      _DependentAllergenSelectScreenState();
}

class _DependentAllergenSelectScreenState
    extends State<DependentAllergenSelectScreen> {
  late final DependentStore store = Get.find<DependentStore>();
  late final String id = resolveDependentId(widget.dependentId);
  Set<int> selected = <int>{};
  bool _seeded = false;
  ReactionDisposer? _seedDisposer;

  @override
  void initState() {
    super.initState();
    if (id.isEmpty) return;
    _init();
    if (store.canSaveAllergensFor(id)) {
      _applySeed();
    } else {
      // Seed MỘT lần khi health của đúng id tải xong — ngoài `build`.
      _seedDisposer = when((_) => store.canSaveAllergensFor(id), () {
        if (mounted) setState(_applySeed);
      });
    }
  }

  Future<void> _init() async {
    if (!store.isDetailLoadedFor(id)) await store.loadDependentDetail(id);
    if (!mounted) return;
    final d = store.detailFor(id);
    if (d == null || !store.canEditHealthOf(d)) return; // S-A0
    await store.ensureHealthLoaded(id); // L3 — không GET trùng
    if (!mounted) return;
    store.loadAllergenCatalog();
  }

  @override
  void dispose() {
    _seedDisposer?.call();
    store.clearAllergensSaveStatus();
    super.dispose();
  }

  void _applySeed() {
    final state = store.healthState;
    if (_seeded ||
        state is! SuccessState<DependentHealthProfile> ||
        state.data.dependentId != id) {
      return;
    }
    _seeded = true;
    selected = state.data.allergens.map((Allergen a) => a.id).toSet();
  }

  Future<void> _save() async {
    final ok = await store.saveAllergens(id, selected.toList()..sort());
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (ok) {
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.allergensSavedToast)));
      Navigator.of(context).maybePop();
      return;
    }
    if (store.allergensSaveStatus != FormStatus.failure) return;
    final error = store.allergensSaveError;
    if (error?.code == 'ERR_DEP_001') {
      backToDependentList();
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.dependentNotFoundTitle)));
      return;
    }
    // ERR_ALLERGEN_NOT_FOUND: store đã nạp lại catalog; GIỮ lựa chọn (S-A3).
    messenger.showSnackBar(
        SnackBar(content: Text(dependentErrorMessage(l10n, error))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final d = id.isEmpty ? null : store.detailFor(id);
      return AppScaffold(
        title: d == null
            ? l10n.healthProfileAllergensSection
            : l10n.dependentAllergensTitle(d.displayName),
        body: _body(context, d),
      );
    });
  }

  Widget _body(BuildContext context, DependentSummary? d) {
    final l10n = context.l10n;
    if (id.isEmpty) {
      return const DependentNotFoundView(onBack: backToDependentList);
    }
    if (d == null) {
      final state = store.detailState;
      if (state is ErrorState<DependentSummary>) {
        if (state.error.code == 'ERR_DEP_001') {
          return const DependentNotFoundView(onBack: backToDependentList);
        }
        return AppErrorView(
          message: dependentErrorMessage(l10n, state.error),
          onRetry: _init,
        );
      }
      return const AppLoadingView();
    }
    if (!store.canEditHealthOf(d)) {
      return DependentBlockedView(
        key: const ValueKey<String>('dependent-allergens-blocked'),
        message: l10n.dependentNoAccessAllergens,
      );
    }
    final health = store.healthState;
    final catalog = store.catalogState;
    final isSaving = store.allergensSaveStatus == FormStatus.submitting;
    if (health is ErrorState<DependentHealthProfile>) {
      return AppErrorView(
        message: dependentErrorMessage(l10n, health.error),
        onRetry: _init,
      );
    }
    if (!store.canSaveAllergensFor(id) || !_seeded) {
      return const AppLoadingView();
    }
    return switch (catalog) {
      LoadingState<List<Allergen>>() => const AppLoadingView(),
      ErrorState<List<Allergen>>(:final error) => AppErrorView(
          message: dependentErrorMessage(l10n, error),
          onRetry: () => store.loadAllergenCatalog(),
        ),
      EmptyState<List<Allergen>>() =>
        AppEmptyView(message: l10n.allergensCatalogEmpty),
      SuccessState<List<Allergen>>(:final data) when data.isEmpty =>
        AppEmptyView(message: l10n.allergensCatalogEmpty),
      SuccessState<List<Allergen>>(:final data) =>
        _buildChecklist(data, isSaving: isSaving),
    };
  }

  /// S-A2 — checklist seed sẵn + bộ đếm "N đã chọn" + Lưu.
  Widget _buildChecklist(List<Allergen> catalog, {required bool isSaving}) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.md, AppDimens.md, AppDimens.md, AppDimens.xs),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(l.allergensCatalogCount(catalog.length),
                    style: theme.textTheme.bodyMedium),
              ),
              Text(
                l.allergensSelectedCount(selected.length),
                key: const ValueKey<String>('allergens-selected-count'),
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
            itemCount: catalog.length,
            itemBuilder: (_, int i) {
              final a = catalog[i];
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.md, 0, AppDimens.md, AppDimens.sm),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm),
                  child: CheckboxListTile(
                    key: ValueKey<String>('allergen-${a.id}'),
                    value: selected.contains(a.id),
                    contentPadding: EdgeInsets.zero,
                    onChanged: isSaving
                        ? null
                        : (bool? v) => setState(() {
                              if (v == true) {
                                selected.add(a.id);
                              } else {
                                selected.remove(a.id);
                              }
                            }),
                    title: Text(a.name),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: AppButton(
            key: const ValueKey<String>('allergens-save'),
            label: l.allergensSave,
            isLoading: isSaving,
            onPressed: isSaving ? null : _save,
          ),
        ),
      ],
    );
  }
}
