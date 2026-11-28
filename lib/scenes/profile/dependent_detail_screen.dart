import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/states/app_error_view.dart';
import '../../widgets/states/app_loading_view.dart';
import '../../widgets/states/view_state.dart';
import 'dependent_error_l10n.dart';
import 'dependent_list_screen.dart';
import 'domain/dependent_health_profile.dart';
import 'domain/dependent_summary.dart';
import 'stores/dependent_store.dart';
import 'stores/form_status.dart';
import 'widgets/change_guardian_sheet.dart';
import 'widgets/dependent_row.dart';
import 'widgets/dependent_state_views.dart';
import 'widgets/guardian_inactive_banner.dart';
import '../../widgets/feedback/app_toast.dart';

/// Đọc `:dependentId` từ path; [explicit] chỉ cho test/nhúng trực tiếp.
String resolveDependentId(String? explicit) {
  if (explicit != null && explicit.isNotEmpty) return explicit;
  return Get.parameters['dependentId'] ?? '';
}

/// Chi tiết hồ sơ phụ thuộc (§9.3, §16.12): summary (mọi role) + health đầy
/// đủ (guardian active / OWNER) + banner `guardianActive:false` + đổi guardian
/// / xoá (OWNER).
class DependentDetailScreen extends StatefulWidget {
  const DependentDetailScreen({super.key, this.dependentId});

  final String? dependentId;

  @override
  State<DependentDetailScreen> createState() => _DependentDetailScreenState();
}

class _DependentDetailScreenState extends State<DependentDetailScreen> {
  late final DependentStore store = Get.find<DependentStore>();
  late final String id = resolveDependentId(widget.dependentId);
  ReactionDisposer? _healthPermission;

  @override
  void initState() {
    super.initState();
    // Thiếu id → not-found ngay, KHÔNG gọi API với path rỗng.
    if (id.isEmpty) return;
    store.loadDependentDetail(id);
    // L4 (review #125): quyền đổi false → true SAU khi detail đã tải (vd.
    // roster nạp lại) → tự nạp health, không để khối health quay mãi.
    _healthPermission = reaction<bool>((_) {
      final d = store.detailFor(id);
      return d != null && store.canEditHealthOf(d);
    }, (bool can) {
      if (can) store.ensureHealthLoaded(id);
    });
  }

  @override
  void dispose() {
    _healthPermission?.call();
    store.clearDeleteStatus();
    store.clearGuardianStatus();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    AppToast.show(message, type: AppToastType.error);
  }

  Future<void> _openChangeGuardian(DependentSummary d) async {
    if (!store.canAdminister) return;
    await store.ensureRoster();
    if (!mounted) return;
    // M1 (review #125): roster tải lỗi → báo lỗi, KHÔNG mở sheet (sheet sẽ
    // hiện sai "không có ai làm giám hộ được").
    if (!store.isRosterLoaded) {
      _toast(dependentErrorMessage(context.l10n, store.rosterError));
      return;
    }
    store.clearGuardianStatus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeGuardianSheet(store: store, dependent: d),
    );
  }

  Future<void> _confirmDelete(DependentSummary d) async {
    if (!store.canAdminister) return;
    store.clearDeleteStatus();
    final l10n = context.l10n;
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDependentDialog(store: store, dependent: d),
    );
    if (deleted == null || !mounted) return;
    if (deleted) {
      backToDependentList();
      AppToast.show(l10n.dependentDeletedToast, type: AppToastType.success);
      return;
    }
    final error = store.deleteError;
    if (error == null) return; // store từ chối (guard), không phải lỗi
    if (error.code == 'ERR_DEP_001') {
      backToDependentList();
      AppToast.show(l10n.dependentNotFoundTitle, type: AppToastType.error);
      return;
    }
    _toast(dependentErrorMessage(l10n, error));
  }

  void _openHealth() => Get.toNamed<void>(
      AppRoutes.dependentHealth.replaceFirst(':dependentId', id));

  void _openAllergens() => Get.toNamed<void>(
      AppRoutes.dependentAllergens.replaceFirst(':dependentId', id));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final d = id.isEmpty ? null : store.detailFor(id);
      return AppScaffold(
        title: d?.displayName ?? l10n.dependentListTitle,
        body: _body(context, d),
      );
    });
  }

  Widget _body(BuildContext context, DependentSummary? d) {
    final l10n = context.l10n;
    if (id.isEmpty) {
      return const DependentNotFoundView(onBack: backToDependentList);
    }
    final state = store.detailState;
    if (d == null) {
      if (state is ErrorState<DependentSummary>) {
        if (state.error.code == 'ERR_DEP_001') {
          return const DependentNotFoundView(onBack: backToDependentList);
        }
        return AppErrorView(
          message: dependentErrorMessage(l10n, state.error),
          onRetry: () => store.loadDependentDetail(id),
        );
      }
      return const AppLoadingView();
    }
    // Đọc observable ở đây để Observer theo dõi.
    final isOwner = store.canAdminister;
    final canEdit = store.canEditHealthOf(d);
    final health = store.healthState;
    final guardian = store.guardianOf(d);
    final me = store.currentUserId;
    return RefreshIndicator(
      // L1: giữ nội dung khi kéo làm mới, không nháy spinner toàn màn.
      onRefresh: () => store.loadDependentDetail(id, keepCurrent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.md),
        children: <Widget>[
          if (!d.guardianActive) ...<Widget>[
            GuardianInactiveBanner(
              key: const ValueKey<String>('dependent-guardian-inactive-banner'),
              showOwnerHint: isOwner,
            ),
            const SizedBox(height: AppDimens.md),
          ],
          _Header(dependent: d),
          const SizedBox(height: AppDimens.md),
          _Section(
            title: l10n.dependentSummarySection,
            child: Wrap(
              key: const ValueKey<String>('dependent-summary'),
              spacing: 6,
              runSpacing: 4,
              children: <Widget>[
                dependentDietChip(l10n, d.dietType, showNone: true)!,
                ...dependentAllergenChips(l10n, d.allergens),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.md),
          _Section(
            title: l10n.healthProfileTitle,
            child: canEdit
                ? _HealthBlock(
                    state: health,
                    dependentId: d.id,
                    onRetry: () => store.loadHealthProfile(id),
                    onEditHealth: _openHealth,
                    onEditAllergens: _openAllergens,
                  )
                : Text(
                    l10n.dependentHealthRestricted,
                    key: const ValueKey<String>('dependent-health-restricted'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
          ),
          const SizedBox(height: AppDimens.md),
          _Section(
            title: l10n.dependentGuardianSection,
            child: _GuardianBlock(
              dependent: d,
              guardianName: guardian?.fullName,
              guardianFound: guardian != null,
              isMe: d.guardianUserId == me,
              onChange: isOwner ? () => _openChangeGuardian(d) : null,
            ),
          ),
          if (isOwner) ...<Widget>[
            const SizedBox(height: AppDimens.lg),
            AppButton(
              key: const ValueKey<String>('dependent-delete'),
              label: l10n.dependentDelete,
              icon: Icons.delete_outline,
              variant: AppButtonVariant.destructive,
              onPressed: () => _confirmDelete(d),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dependent});

  final DependentSummary dependent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birth = dependentBirthText(context, dependent.dateOfBirth) ??
        context.l10n.dependentDobNotSet;
    return Row(
      children: <Widget>[
        DependentAvatar(name: dependent.displayName, size: 56),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(dependent.displayName,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(birth,
                  key: const ValueKey<String>('dependent-birth'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppDimens.sm),
          child,
        ],
      ),
    );
  }
}

/// State 5 / 5b — chỉ render khi `canEditHealthOf == true`.
class _HealthBlock extends StatelessWidget {
  const _HealthBlock({
    required this.state,
    required this.dependentId,
    required this.onRetry,
    required this.onEditHealth,
    required this.onEditAllergens,
  });

  final ViewState<DependentHealthProfile> state;
  final String dependentId;
  final VoidCallback onRetry;
  final VoidCallback onEditHealth;
  final VoidCallback onEditAllergens;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = state;
    if (s is ErrorState<DependentHealthProfile>) {
      return Row(
        key: const ValueKey<String>('dependent-health-error'),
        children: <Widget>[
          Expanded(
            child: Text(dependentErrorMessage(l10n, s.error),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          TextButton(
            key: const ValueKey<String>('dependent-health-retry'),
            onPressed: onRetry,
            child: Text(l10n.commonRetry),
          ),
        ],
      );
    }
    if (s is! SuccessState<DependentHealthProfile> ||
        s.data.dependentId != dependentId) {
      return const Padding(
        key: ValueKey<String>('dependent-health-loading'),
        padding: EdgeInsets.symmetric(vertical: AppDimens.sm),
        child: LinearProgressIndicator(),
      );
    }
    final h = s.data;
    final calories = h.targetDailyCalories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DependentInfoRow(
          key: const ValueKey<String>('dependent-health-calories'),
          label: l10n.healthProfileTargetCalories,
          value: calories == null
              ? l10n.healthProfileCaloriesNotSet
              : l10n.healthProfileKcalValue(calories),
        ),
        DependentInfoRow(
          label: l10n.healthProfileHeight,
          value: h.heightCm == null
              ? l10n.healthProfileNotSetUp
              : formatHealthNumber(h.heightCm),
        ),
        DependentInfoRow(
          label: l10n.healthProfileWeight,
          value: h.weightKg == null
              ? l10n.healthProfileNotSetUp
              : formatHealthNumber(h.weightKg),
        ),
        const SizedBox(height: AppDimens.sm),
        Wrap(
          spacing: AppDimens.sm,
          runSpacing: AppDimens.xs,
          children: <Widget>[
            OutlinedButton.icon(
              key: const ValueKey<String>('dependent-edit-health'),
              onPressed: onEditHealth,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l10n.healthProfileEditTitle),
            ),
            OutlinedButton.icon(
              key: const ValueKey<String>('dependent-edit-allergens'),
              onPressed: onEditAllergens,
              icon: const Icon(Icons.health_and_safety_outlined, size: 18),
              label: Text(l10n.healthProfileAllergensEdit),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dòng guardian (§16.3): nhãn "Hiện tại" + tên/id rút gọn + tag.
class _GuardianBlock extends StatelessWidget {
  const _GuardianBlock({
    required this.dependent,
    required this.guardianName,
    required this.guardianFound,
    required this.isMe,
    required this.onChange,
  });

  final DependentSummary dependent;
  final String? guardianName;
  final bool guardianFound;
  final bool isMe;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = dependent;
    final name = guardianName;
    final hasName = name != null && name.isNotEmpty;
    final String value;
    if (hasName) {
      value = d.guardianActive && isMe ? l10n.dependentGuardianYou(name) : name;
    } else {
      value = shortId(d.guardianUserId);
    }
    final String? tag = d.guardianActive
        ? null
        : (guardianFound
            ? l10n.dependentGuardianNoManage
            : l10n.dependentGuardianLeft);
    final change = onChange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DependentInfoRow(
          key: const ValueKey<String>('dependent-guardian'),
          label: l10n.dependentGuardianCurrent,
          value: value,
        ),
        if (tag != null)
          Align(
            alignment: Alignment.centerRight,
            child: DependentChip(
              key: const ValueKey<String>('dependent-guardian-tag'),
              label: tag,
              warning: true,
            ),
          ),
        if (change != null) ...<Widget>[
          const SizedBox(height: AppDimens.sm),
          AppButton(
            key: const ValueKey<String>('dependent-change-guardian'),
            label: l10n.dependentChangeGuardian,
            icon: Icons.swap_horiz_rounded,
            variant: d.guardianActive
                ? AppButtonVariant.outline
                : AppButtonVariant.primary,
            onPressed: change,
          ),
        ],
      ],
    );
  }
}

/// Dòng nhãn — giá trị dùng chung cho detail/health (chép `_InfoRow` của
/// HealthProfileScreen — §16.10, gom chung là việc refactor riêng).
class DependentInfoRow extends StatelessWidget {
  const DependentInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: AppDimens.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String formatHealthNumber(double? v) {
  if (v == null) return '';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// Xác nhận xoá nêu `displayName` (state 8) — dialog tự gọi
/// `deleteDependent` (hiện loading) rồi pop bằng context CỦA DIALOG với kết
/// quả; `null` = huỷ. Mirror `_RemoveMemberDialog`.
class _DeleteDependentDialog extends StatelessWidget {
  const _DeleteDependentDialog({required this.store, required this.dependent});

  final DependentStore store;
  final DependentSummary dependent;

  Future<void> _confirm(BuildContext dialogContext) async {
    final ok = await store.deleteDependent(dependent.id);
    if (dialogContext.mounted) Navigator.of(dialogContext).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final submitting = store.deleteStatus == FormStatus.submitting;
      return PopScope(
        canPop: !submitting,
        child: AlertDialog(
          title: Text(l10n.dependentDeleteConfirmTitle(dependent.displayName)),
          content: Text(l10n.dependentDeleteConfirmBody),
          actions: <Widget>[
            TextButton(
              key: const ValueKey<String>('dependent-delete-cancel'),
              onPressed: submitting ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            AppButton(
              key: const ValueKey<String>('dependent-delete-confirm'),
              label: l10n.delete,
              variant: AppButtonVariant.destructive,
              expanded: false,
              isLoading: submitting,
              onPressed: submitting ? null : () => _confirm(context),
            ),
          ],
        ),
      );
    });
  }
}
