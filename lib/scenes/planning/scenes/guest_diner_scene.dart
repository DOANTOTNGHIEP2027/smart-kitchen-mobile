import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/states/app_state_view.dart';
import '../../../widgets/states/view_state.dart';
import '../../profile/domain/allergen.dart';
import '../domain/guest_diner.dart';
import '../stores/guest_diner_store.dart';
import '../widgets/allergen_multi_select.dart';
import '../../../widgets/feature_banner.dart';

/// Thêm/sửa/xoá khách ăn tạm thời của kế hoạch tuần
/// (flexible-meal-planning-screens.md §8.2). Phạm vi = cả tuần (OD-06).
class GuestDinerScene extends StatefulWidget {
  const GuestDinerScene({super.key});

  @override
  State<GuestDinerScene> createState() => _GuestDinerSceneState();
}

class _GuestDinerSceneState extends State<GuestDinerScene> {
  late final GuestDinerStore _store;

  @override
  void initState() {
    super.initState();
    _store = Get.find<GuestDinerStore>();
    _store.loadAll();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openForm({GuestDiner? editing}) async {
    _store.clearMutationStatus();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GuestDinerForm(store: _store, editing: editing),
    );
    if (ok == true && mounted) _toast(context.l10n.planningGuestUpdated);
  }

  Future<void> _confirmRemove(GuestDiner diner) async {
    _store.clearMutationStatus();
    await showDialog<void>(
      context: context,
      // §8.2 — dialog không tự đóng cho tới khi có kết quả xoá.
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return Observer(builder: (_) {
          final busy = _store.isSubmitting;
          return PopScope(
            canPop: !busy,
            child: AlertDialog(
              title: Text(l10n.planningGuestDelete),
              content: Text(_store.mutationError == null
                  ? l10n.planningGuestDeleteConfirm
                  : apiErrorMessage(l10n, _store.mutationError)),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      busy ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                AppButton(
                  key: const ValueKey<String>('guest-delete-confirm'),
                  expanded: false,
                  label: l10n.planningGuestDelete,
                  isLoading: busy,
                  onPressed: () async {
                    final ok = await _store.remove(diner);
                    if (ok && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.planningGuestTitle,
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey<String>('guest-add'),
        heroTag: 'guest-diner-fab',
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(
          l10n.planningGuestAdd,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.md, AppDimens.md, AppDimens.md, 0),
            child: FeatureBanner(
              key: const ValueKey<String>('guest-scope-banner'),
              message: l10n.planningGuestScopeBanner,
              isError: false,
              margin: const EdgeInsets.only(bottom: AppDimens.sm),
            ),
          ),
          Observer(builder: (_) {
            if (_store.lastRemoved == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FeatureBanner(
                      key: const ValueKey<String>('guest-removed-hint'),
                      message: l10n.planningGuestRemovedHint(
                          _store.lastRemoved!.trimmedName ??
                              l10n.planningGuestUnnamed),
                      isError: false,
                      margin: const EdgeInsets.only(bottom: AppDimens.sm),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _store.clearLastRemoved,
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: Observer(
              builder: (_) => AppStateView<List<GuestDiner>>(
                state: _store.dinersState,
                onRetry: _store.loadAll,
                emptyMessage: l10n.planningGuestEmpty,
                emptyIcon: Icons.group_outlined,
                successBuilder: (_, data) => ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppDimens.xxl * 2),
                  itemCount: data.length,
                  itemBuilder: (_, i) => _GuestDinerRow(
                    diner: data[i],
                    onEdit: () => _openForm(editing: data[i]),
                    onDelete: () => _confirmRemove(data[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestDinerRow extends StatelessWidget {
  const _GuestDinerRow({
    required this.diner,
    required this.onEdit,
    required this.onDelete,
  });

  final GuestDiner diner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, AppDimens.sm, AppDimens.md, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: _tile(l10n),
      ),
    );
  }

  Widget _tile(AppLocalizations l10n) {
    return ListTile(
      key: ValueKey<String>('guest-row-${diner.id}'),
      leading: const Icon(Icons.person_outline, color: AppColors.sage),
      title: Text(diner.trimmedName ?? l10n.planningGuestUnnamed),
      subtitle: diner.allergens.isEmpty
          ? Text(l10n.planningGuestNoAllergen)
          : Wrap(
              spacing: AppDimens.xs,
              children: <Widget>[
                for (final a in diner.allergens)
                  Chip(
                    label: Text(a.name),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: l10n.planningGuestEditAllergens,
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            key: ValueKey<String>('guest-delete-${diner.id}'),
            tooltip: l10n.planningGuestDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Form thêm khách (tên + dị ứng) hoặc sửa dị ứng của khách có sẵn.
class _GuestDinerForm extends StatefulWidget {
  const _GuestDinerForm({required this.store, this.editing});

  final GuestDinerStore store;
  final GuestDiner? editing;

  @override
  State<_GuestDinerForm> createState() => _GuestDinerFormState();
}

class _GuestDinerFormState extends State<_GuestDinerForm> {
  final TextEditingController _name = TextEditingController();
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = <int>{
      for (final Allergen a in widget.editing?.allergens ?? const <Allergen>[])
        a.id,
    };
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final editing = widget.editing;
    final ok = editing == null
        ? await widget.store.add(displayName: _name.text, allergenIds: _selected)
        : await widget.store.updateAllergens(editing.id, _selected);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.md,
        right: AppDimens.md,
        top: AppDimens.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.md,
      ),
      child: SingleChildScrollView(
        child: Observer(builder: (_) {
          final store = widget.store;
          final catalog = store.catalogState;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.editing == null
                    ? l10n.planningGuestAdd
                    : l10n.planningGuestEditAllergens,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimens.sm),
              if (widget.editing == null)
                TextField(
                  key: const ValueKey<String>('guest-form-name'),
                  controller: _name,
                  maxLength: 100,
                  decoration:
                      InputDecoration(labelText: l10n.planningGuestNameOptional),
                ),
              Text(l10n.planningGuestAllergens),
              const SizedBox(height: AppDimens.xs),
              ..._catalogSection(l10n, catalog),
              if (store.mutationError != null)
                FeatureBanner(
                  key: const ValueKey<String>('guest-form-error'),
                  message: apiErrorMessage(l10n, store.mutationError),
                  isError: true,
                  margin: const EdgeInsets.only(bottom: AppDimens.sm),
                ),
              const SizedBox(height: AppDimens.sm),
              AppButton(
                key: const ValueKey<String>('guest-form-submit'),
                label: widget.editing == null
                    ? l10n.planningGuestAdd
                    : l10n.planningGuestSave,
                isLoading: store.isSubmitting,
                // I9 — không cho gửi khi catalog chưa sẵn sàng.
                onPressed: store.isCatalogReady ? _submit : null,
              ),
            ],
          );
        }),
      ),
    );
  }

  List<Widget> _catalogSection(
      AppLocalizations l10n, ViewState<List<Allergen>> catalog) {
    return switch (catalog) {
      SuccessState<List<Allergen>>(:final data) => <Widget>[
          AllergenMultiSelect(
            catalog: data,
            selectedIds: _selected,
            enabled: !widget.store.isSubmitting,
            onChanged: (ids) => setState(() => _selected = ids),
          ),
        ],
      ErrorState<List<Allergen>>() => <Widget>[
          FeatureBanner(
            key: const ValueKey<String>('guest-catalog-error'),
            message: l10n.planningGuestCatalogFailed,
            isError: true,
            margin: const EdgeInsets.only(bottom: AppDimens.sm),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.store.loadCatalog,
              child: Text(l10n.commonRetry),
            ),
          ),
        ],
      _ => const <Widget>[
          Padding(
            padding: EdgeInsets.all(AppDimens.sm),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
    };
  }
}
