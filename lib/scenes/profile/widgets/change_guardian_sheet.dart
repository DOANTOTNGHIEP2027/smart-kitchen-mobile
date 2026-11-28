import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feature_banner.dart';
import '../dependent_error_l10n.dart';
import '../domain/dependent_summary.dart';
import '../domain/household_member.dart';
import '../stores/dependent_store.dart';
import '../stores/form_status.dart';
import '../../../widgets/feedback/app_toast.dart';

/// Picker guardian mới (§9.4, §16.6) — OWNER only, caller đảm bảo roster đã
/// tải trước khi mở. Candidate: OWNER/MEMBER, loại REMOTE_VIEWER, loại guardian
/// hiện tại khi họ còn active.
class ChangeGuardianSheet extends StatefulWidget {
  const ChangeGuardianSheet({
    super.key,
    required this.store,
    required this.dependent,
  });

  final DependentStore store;
  final DependentSummary dependent;

  @override
  State<ChangeGuardianSheet> createState() => _ChangeGuardianSheetState();
}

class _ChangeGuardianSheetState extends State<ChangeGuardianSheet> {
  String? _selected;

  DependentStore get _store => widget.store;

  @override
  void dispose() {
    _store.clearGuardianStatus();
    super.dispose();
  }

  Future<void> _submit(String userId) async {
    final ok = await _store.changeGuardian(widget.dependent.id, userId);
    if (!ok || !mounted) return;
    final toast = context.l10n.dependentGuardianChangedToast;
    Navigator.of(context).pop();
    AppToast.show(toast, type: AppToastType.success);
  }

  String _roleLabel(BuildContext context, HouseholdMember m) =>
      m.role == 'OWNER'
          ? context.l10n.householdOwner
          : context.l10n.familyRoleMember;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final submitting = _store.guardianStatus == FormStatus.submitting;
      final error = _store.guardianStatus == FormStatus.failure
          ? _store.guardianError
          : null;
      // Đọc trong Observer: ERR_DEP_004 → store nạp lại roster → list đổi.
      final candidates = _store.guardianCandidates(widget.dependent);
      final selected =
          candidates.any((m) => m.userId == _selected) ? _selected : null;
      return PopScope(
        canPop: !submitting,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppDimens.md,
            right: AppDimens.md,
            top: AppDimens.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.dependentChangeGuardianTitle(
                    widget.dependent.displayName),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimens.sm),
              if (error != null)
                FeatureBanner(
                  key: const ValueKey<String>('change-guardian-error'),
                  message: dependentErrorMessage(l10n, error),
                  margin: const EdgeInsets.only(bottom: AppDimens.sm),
                ),
              if (candidates.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                  child: Text(
                    l10n.dependentChangeGuardianEmpty,
                    key: const ValueKey<String>('change-guardian-empty'),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                RadioGroup<String>(
                  groupValue: selected,
                  onChanged: (String? v) {
                    if (submitting || v == null) return;
                    setState(() => _selected = v);
                    if (error != null) _store.clearGuardianStatus();
                  },
                  child: Column(
                    children: <Widget>[
                      for (final m in candidates)
                        RadioListTile<String>(
                          key: ValueKey<String>('change-guardian-${m.userId}'),
                          contentPadding: EdgeInsets.zero,
                          value: m.userId,
                          enabled: !submitting,
                          title: Text(m.fullName.isEmpty
                              ? shortId(m.userId)
                              : m.fullName),
                          subtitle: Text(_roleLabel(context, m)),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimens.sm),
              AppButton(
                key: const ValueKey<String>('change-guardian-confirm'),
                label: l10n.commonConfirm,
                isLoading: submitting,
                onPressed: selected == null ? null : () => _submit(selected),
              ),
            ],
          ),
        ),
      );
    });
  }
}
