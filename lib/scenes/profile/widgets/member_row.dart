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
    final canChangeRole = isOwner && onChangeRole != null;
    final canRemove = isOwner && onRemove != null;
    final hasActions = canChangeRole || canRemove;
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
          title: Text(
            isMe ? l10n.familyMemberYou(name) : name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppDimens.xs),
            child: Wrap(
              spacing: AppDimens.xs,
              runSpacing: AppDimens.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (member.provider == 'GUEST')
                  _Badge(
                    key: ValueKey<String>('member-guest-${member.userId}'),
                    label: l10n.familyGuestBadge,
                    filled: false,
                  ),
                if (member.role == 'OWNER')
                  _Badge(label: l10n.householdOwner, filled: true)
                else if (member.role == 'MEMBER')
                  _Badge(label: l10n.familyRoleMember, filled: false)
                else if (member.isRemoteViewer)
                  _Badge(label: l10n.tierRoleViewOnly, filled: false),
                Text(l10n.familyJoinedAt(joined), style: AppTextStyles.label),
              ],
            ),
          ),
          trailing: hasActions
              ? PopupMenuButton<_MemberAction>(
                  key: ValueKey<String>('member-actions-${member.userId}'),
                  tooltip: l10n.familyMemberActions,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) => switch (action) {
                    _MemberAction.changeRole => onChangeRole?.call(),
                    _MemberAction.remove => onRemove?.call(),
                  },
                  itemBuilder: (_) => <PopupMenuEntry<_MemberAction>>[
                    if (canChangeRole)
                      PopupMenuItem<_MemberAction>(
                        key: ValueKey<String>(
                            'member-change-role-${member.userId}'),
                        value: _MemberAction.changeRole,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.manage_accounts_outlined),
                          title: Text(l10n.tierChangeRoleAction),
                        ),
                      ),
                    if (canRemove)
                      PopupMenuItem<_MemberAction>(
                        key: ValueKey<String>('member-remove-${member.userId}'),
                        value: _MemberAction.remove,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_remove_outlined,
                              color: AppColors.error),
                          title: Text(l10n.familyRemove),
                        ),
                      ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

enum _MemberAction { changeRole, remove }

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
