import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../constants/app_text_styles.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/cards/app_card.dart';
import '../domain/household_member.dart';

/// Một dòng roster trong FamilyScreen. `_isMe` → không tap được.
class MemberRow extends StatelessWidget {
  const MemberRow({
    super.key,
    required this.member,
    required this.isOwner,
    this.onTap,
    this.onRemove,
  });

  final HouseholdMember member;
  final bool isOwner;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final avatar = member.avatarUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, AppDimens.sm, AppDimens.md, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            backgroundImage: avatar == null
                ? null
                : NetworkImage(avatar) as ImageProvider<Object>,
            radius: 20,
            child: avatar == null
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          title: Text(member.fullName, style: AppTextStyles.bodyMedium),
          subtitle: member.provider == 'GUEST'
              ? const Text('GUEST', style: AppTextStyles.label)
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (member.role == 'OWNER')
                _Badge(label: context.l10n.householdOwner, filled: true)
              else if (member.role == 'MEMBER')
                _Badge(label: member.role, filled: false),
              if (isOwner && onRemove != null) ...<Widget>[
                const SizedBox(width: AppDimens.sm),
                IconButton(
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
  const _Badge({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : Colors.transparent,
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
