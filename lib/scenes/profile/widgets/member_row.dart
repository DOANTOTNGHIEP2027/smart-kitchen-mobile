import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../constants/app_text_styles.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_cached_image.dart';
import '../../../widgets/cards/app_card.dart';
import '../domain/household_member.dart';

/// Một dòng roster trong FamilyScreen (§10.4 F1): tên + "(bạn)" ở dòng của
/// mình, badge role, badge "Khách" khi `provider == GUEST`, ngày tham gia.
class MemberRow extends StatelessWidget {
  const MemberRow({
    super.key,
    required this.member,
    required this.isOwner,
    this.isMe = false,
    this.onTap,
    this.onRemove,
    this.onChangeRole,
  });

  final HouseholdMember member;
  final bool isOwner;
  final bool isMe;
  final VoidCallback? onTap;

  /// `null` = không có nút Xóa. FamilyScreen chỉ truyền khi
  /// `FamilyStore.canRemove(member)` (Guard 16b).
  final VoidCallback? onRemove;

  /// Chỉ OWNER, không trên dòng của chính mình / OWNER khác (tier-gate §10.3).
  final VoidCallback? onChangeRole;

  @override
  Widget build(BuildContext context) {
    final avatar = member.avatarUrl;
    final l10n = context.l10n;
    final name =
        member.fullName.isEmpty ? l10n.familyRoleMember : member.fullName;
    final joined = DateFormat.yMd(Localizations.localeOf(context).toString())
        .format(member.joinedAt.toLocal());
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, AppDimens.sm, AppDimens.md, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          leading: AppCachedImage(
            url: avatar,
            width: 40,
            height: 40,
            shape: AppCachedImageShape.circle,
            placeholderIcon: Icons.person,
          ),
          title: Wrap(
            spacing: AppDimens.xs,
            runSpacing: AppDimens.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(isMe ? l10n.familyMemberYou(name) : name,
                  style: AppTextStyles.bodyMedium),
              if (member.provider == 'GUEST')
                _Badge(
                  key: ValueKey<String>('member-guest-${member.userId}'),
                  label: l10n.familyGuestBadge,
                  filled: false,
                ),
            ],
          ),
          subtitle:
              Text(l10n.familyJoinedAt(joined), style: AppTextStyles.label),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (member.role == 'OWNER')
                _Badge(label: context.l10n.householdOwner, filled: true)
              else if (member.role == 'MEMBER')
                _Badge(label: context.l10n.familyRoleMember, filled: false)
              else if (member.isRemoteViewer)
                _Badge(label: context.l10n.tierRoleViewOnly, filled: false),
              if (isOwner && onChangeRole != null) ...<Widget>[
                const SizedBox(width: AppDimens.xs),
                IconButton(
                  key: ValueKey<String>('member-change-role-${member.userId}'),
                  tooltip: context.l10n.tierChangeRoleAction,
                  icon: const Icon(Icons.manage_accounts_outlined, size: 20),
                  onPressed: onChangeRole,
                ),
              ],
              if (isOwner && onRemove != null) ...<Widget>[
                const SizedBox(width: AppDimens.sm),
                IconButton(
                  key: ValueKey<String>('member-remove-${member.userId}'),
                  tooltip: context.l10n.familyRemove,
                  icon: const Icon(Icons.person_remove_outlined, size: 20),
                  onPressed: onRemove,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimens.sm, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? AppColors.sage : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: filled ? null : Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: filled ? AppColors.textOnPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
