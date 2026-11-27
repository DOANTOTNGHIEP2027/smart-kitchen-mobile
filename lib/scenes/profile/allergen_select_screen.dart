import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../constants/app_dimens.dart';
import '../../data/network/api_exception.dart';
import '../../utils/api_error_l10n.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/states/app_empty_view.dart';
import '../../widgets/states/app_error_view.dart';
import '../../widgets/states/app_loading_view.dart';
import '../../widgets/states/view_state.dart';
import 'domain/allergen.dart';
import 'domain/health_profile.dart';
import 'stores/form_status.dart';
import 'stores/profile_store.dart';
import 'widgets/allergen_label.dart';
import 'widgets/stale_data_banner.dart';

/// Picker dị ứng (`/profile/allergens`) — 3 nhánh theo trạng thái health
/// (§10.3, Guard 12, Decision D14):
/// - A1 đang tải → spinner, KHÔNG checklist.
/// - A2 health lỗi / từ cache / catalog lỗi → error hoặc chip chỉ đọc, KHÔNG
///   checklist, KHÔNG nút Lưu. API là full-replace: `[]` sinh ra từ trạng thái
///   chưa biết = xoá sạch dị ứng.
/// - A3 `canSaveAllergens` + catalog OK → checklist seed từ
///   `healthProfileState.data.allergens` + bộ đếm + Lưu.
class AllergenSelectScreen extends StatefulWidget {
  const AllergenSelectScreen({super.key});

  @override
  State<AllergenSelectScreen> createState() => _AllergenSelectScreenState();
}

class _AllergenSelectScreenState extends State<AllergenSelectScreen> {
  late final ProfileStore store = Get.find<ProfileStore>();
  Set<int> selected = <int>{};
  bool _seeded = false;
  ReactionDisposer? _seedDisposer;

  @override
  void initState() {
    super.initState();
    // Health từ cache cũng phải tải lại: lựa chọn chỉ được seed từ dữ liệu
    // server (Guard 12/13).
    if (!store.canSaveAllergens) store.loadHealthProfile();
    store.loadAllergenCatalog();
    if (store.canSaveAllergens) {
      _applySeed();
    } else {
      // Seed MỘT lần khi health tải xong từ server — ngoài `build`.
      _seedDisposer = when((_) => store.canSaveAllergens, () {
        if (mounted) setState(_applySeed);
      });
    }
  }

  @override
  void dispose() {
    _seedDisposer?.call();
    store.clearAllergensSaveError();
    super.dispose();
  }

  void _applySeed() {
    final state = store.healthProfileState;
    if (_seeded || state is! SuccessState<HealthProfile>) return;
    _seeded = true;
    selected = state.data.allergens.map((Allergen a) => a.id).toSet();
  }

  void _retryLoads() {
    if (!store.canSaveAllergens) store.loadHealthProfile();
    store.loadAllergenCatalog();
  }

  Future<void> _save() async {
    final ok = await store.saveAllergens(selected.toList()..sort());
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.allergensSavedToast)));
      Navigator.of(context).maybePop();
      return;
    }
    if (store.allergensSaveStatus != FormStatus.failure) return;
    final error = store.mutationError;
    messenger.showSnackBar(
        SnackBar(content: Text(_saveErrorMessage(context, error))));
    // S11.3 — danh mục có thể đã đổi; giữ nguyên lựa chọn đang tick.
    if (error?.code == 'ERR_ALLERGEN_NOT_FOUND') store.loadAllergenCatalog();
  }

  String _saveErrorMessage(BuildContext context, ApiException? error) {
    final l = context.l10n;
    return switch (error?.code) {
      'ERR_NETWORK' => l.networkError,
      'ERR_ALLERGEN_NOT_FOUND' => l.allergenSaveError,
      _ => l.genericRetryError,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.allergensTitle,
      body: Observer(builder: (_) {
        final health = store.healthProfileState;
        final fromCache = store.healthProfileIsFromCache;
        final catalog = store.allergenCatalogState;
        final isSaving = store.allergensSaveStatus == FormStatus.submitting;

        // A1 — health đang tải.
        if (health is LoadingState<HealthProfile>) {
          return const AppLoadingView();
        }
        // A2 — health lỗi: KHÔNG checklist, KHÔNG nút Lưu.
        if (health is ErrorState<HealthProfile>) {
          return _HealthLoadFailedView(onRetry: _retryLoads);
        }
        // A2-cache — chỉ đọc.
        if (health is SuccessState<HealthProfile> && fromCache) {
          return _CachedAllergensView(
            allergens: health.data.allergens,
            onRetry: _retryLoads,
          );
        }
        if (!store.canSaveAllergens || !_seeded) {
          return const AppLoadingView();
        }
        return switch (catalog) {
          LoadingState<List<Allergen>>() => const AppLoadingView(),
          ErrorState<List<Allergen>>(:final error) => AppErrorView(
              message: apiErrorMessage(context.l10n, error),
              onRetry: () => store.loadAllergenCatalog(),
            ),
          EmptyState<List<Allergen>>() =>
            AppEmptyView(message: context.l10n.allergensCatalogEmpty),
          SuccessState<List<Allergen>>(:final data) when data.isEmpty =>
            AppEmptyView(message: context.l10n.allergensCatalogEmpty),
          SuccessState<List<Allergen>>(:final data) =>
            _buildChecklist(data, isSaving: isSaving),
        };
      }),
    );
  }

  /// A3 — checklist seed sẵn + bộ đếm "N đã chọn" + Lưu.
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
                    title: Text(a.label(context.l10n)),
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

/// A2 — health lỗi.
class _HealthLoadFailedView extends StatelessWidget {
  const _HealthLoadFailedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l.allergensHealthLoadFailedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            AppErrorView(
              message: l.allergensHealthLoadFailedMessage,
              onRetry: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// A2-cache — dị ứng đã lưu dạng chip chỉ đọc + cần mạng để sửa.
class _CachedAllergensView extends StatelessWidget {
  const _CachedAllergensView({required this.allergens, required this.onRetry});

  final List<Allergen> allergens;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StaleDataBanner(onRetry: onRetry),
        Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.allergensSavedSection,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppDimens.sm),
                if (allergens.isEmpty)
                  Text(l.healthProfileAllergensEmpty)
                else
                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.xs,
                    children: <Widget>[
                      for (final a in allergens) Chip(label: Text(a.label(context.l10n))),
                    ],
                  ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  l.allergenNeedsNetwork,
                  key: const ValueKey<String>('allergens-needs-network'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
