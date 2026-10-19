import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feature_banner.dart';
import '../domain/household_member.dart';
import '../domain/household_tier.dart';
import '../stores/family_store.dart';
import '../stores/form_status.dart';
import 'tier_widgets.dart';

/// Picker 2 vai trò MEMBER ↔ REMOTE_VIEWER (tier-gate-screens.md §8). KHÔNG có
/// OWNER (Guard 3). Hint ghế chỉ là gợi ý — không bao giờ chặn cứng lựa chọn
/// (Guard 1); quyết định cuối là `403 ERR_TIER_SEAT_LIMIT` từ BE.
class ChangeRoleSheet extends StatefulWidget {
  const ChangeRoleSheet({
    super.key,
    required this.store,
    required this.member,
    required this.onUpgrade,
  });

  final FamilyStore store;
  final HouseholdMember member;

  /// Mở màn nâng cấp gói — `null` khi caller không phải OWNER.
  final VoidCallback? onUpgrade;

  @override
  State<ChangeRoleSheet> createState() => _ChangeRoleSheetState();
}

class _ChangeRoleSheetState extends State<ChangeRoleSheet> {
  late String _selected = widget.member.role;

  FamilyStore get _store => widget.store;

  Future<void> _submit() async {
    final ok = await _store.changeRole(widget.member.userId, _selected);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.tierChangeRoleSuccess)),
    );
  }

  /// Reset ở `dispose` (sau khi animation đóng sheet xong), KHÔNG ở lúc pop:
  /// reset sớm làm Observer vẽ lại picker ngay trong lúc sheet đang trượt xuống
  /// (upsell/lỗi nháy về picker). Đang submit thì store tự bỏ qua.
  @override
  void dispose() {
    _store.clearChangeRoleStatus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final submitting = _store.isSubmittingChangeRole;
      return PopScope(
        canPop: !submitting,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppDimens.md,
            right: AppDimens.md,
            top: AppDimens.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.md,
          ),
          child: _store.isSeatLimitError
              ? _upsell()
              : _picker(context, l10n, submitting),
        ),
      );
    });
  }

  Widget _upsell() => TierUpsellBanner(
        limit: _store.tier.remoteViewerSeatLimit,
        // PREMIUM đầy 5 ghế cũng nhận ERR_TIER_SEAT_LIMIT — không mời "nâng
        // cấp lên Premium" khi đã là Premium.
        isMaxTier: _store.tier == HouseholdTier.premium,
        onUpgrade: widget.onUpgrade == null
            ? null
            : () {
                Navigator.of(context).pop();
                widget.onUpgrade!();
              },
        onDismiss: () => Navigator.of(context).pop(),
      );

  Widget _picker(BuildContext context, AppLocalizations l10n, bool submitting) {
    final seat = _store.seatInfo;
    final failed = _store.changeRoleStatus == FormStatus.failure;
    // Guard 10: hint chỉ khi THÊM MỚI 1 Remote Viewer.
    final showHint = seat != null &&
        seat.isFull &&
        _selected == 'REMOTE_VIEWER' &&
        !widget.member.isRemoteViewer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.tierChangeRoleTitle(widget.member.fullName),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimens.sm),
        if (showHint)
          FeatureBanner(
            key: const ValueKey<String>('change-role-soft-hint'),
            message: l10n.tierChangeRoleSoftHint(
                tierLabel(l10n, seat.tier), seat.used, seat.limit),
            isError: false,
            margin: const EdgeInsets.only(bottom: AppDimens.sm),
          ),
        RadioGroup<String>(
          groupValue: _selected,
          onChanged: (v) {
            if (submitting || v == null) return;
            setState(() => _selected = v);
            if (failed) _store.clearChangeRoleStatus();
          },
          child: Column(
            children: <Widget>[
              for (final role in const <String>['MEMBER', 'REMOTE_VIEWER'])
                RadioListTile<String>(
                  key: ValueKey<String>('change-role-$role'),
                  contentPadding: EdgeInsets.zero,
                  value: role,
                  enabled: !submitting,
                  title: Text(role == 'MEMBER'
                      ? l10n.tierChangeRoleMember
                      : l10n.tierChangeRoleViewer),
                ),
            ],
          ),
        ),
        if (failed && _store.changeRoleError != null)
          FeatureBanner(
            key: const ValueKey<String>('change-role-error'),
            message: apiErrorMessage(l10n, _store.changeRoleError),
            margin: const EdgeInsets.only(bottom: AppDimens.sm),
          ),
        const SizedBox(height: AppDimens.sm),
        AppButton(
          key: const ValueKey<String>('change-role-confirm'),
          label: l10n.tierConfirm,
          isLoading: submitting,
          // Không đổi gì → không cho gửi no-op.
          onPressed: _selected == widget.member.role ? null : _submit,
        ),
      ],
    );
  }
}
