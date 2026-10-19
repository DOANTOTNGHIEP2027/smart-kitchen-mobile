import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../stores/session_store.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/states/view_state.dart';
import '../../profile/domain/household_member.dart';
import '../../profile/domain/household_roster.dart';
import '../../profile/stores/family_store.dart';
import '../domain/shopping_item.dart';
import '../stores/shopping_store.dart';

/// Roster dùng chung — `null` khi FamilyStore chưa đăng ký (degrade, §9.5 B).
FamilyStore? shoppingFamilyStore() =>
    Get.isRegistered<FamilyStore>() ? Get.find<FamilyStore>() : null;

/// Chỉ OWNER/MEMBER được giao — whitelist, role lạ tự bị loại (§9.5).
const Set<String> _assignableRoles = <String>{'OWNER', 'MEMBER'};

/// Chip người phụ trách trên 1 món (#134). KHÔNG BAO GIỜ in UUID thô (Guard #15):
/// roster chưa tải → skeleton không chữ; tải xong mà không thấy → "Thành viên cũ".
class AssigneeChip extends StatelessWidget {
  const AssigneeChip({
    super.key,
    required this.item,
    required this.familyStore,
    required this.currentUserId,
    required this.enabled,
    required this.onTap,
    this.onDisabledTap,
  });

  final ShoppingItem item;
  final FamilyStore? familyStore;
  final String? currentUserId;
  final bool enabled;
  final VoidCallback onTap;

  /// Bấm lúc disabled — vd. báo "Đang đồng bộ…" thay vì im lặng (§14).
  final VoidCallback? onDisabledTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = item.assignedTo;
    final roster = familyStore?.rosterState;
    final Widget label;
    if (id == null) {
      label = Text(l10n.shoppingAssign);
    } else if (id == currentUserId) {
      label = Text(l10n.shoppingAssignedMe);
    } else if (roster is! SuccessState<HouseholdRoster>) {
      // Chưa biết — không được khẳng định gì (AM-TB-2).
      label = const SizedBox(width: 40, height: 10);
    } else {
      final member =
          roster.data.members.where((m) => m.userId == id).firstOrNull;
      // Roster từ cache có thể thiếu người MỚI vào — không thấy trong bản cũ
      // thì vẫn là "chưa biết", không phải "Thành viên cũ".
      label = member != null
          ? Text(member.fullName)
          : familyStore!.rosterIsFromCache
              ? const SizedBox(width: 40, height: 10)
              : Text(l10n.shoppingAssigneeFormer);
    }
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        key: ValueKey<String>('assignee-chip-${item.id}'),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        // Disabled vẫn phải NUỐT tap — `null` để tap lọt xuống InkWell của
        // tile và tick món (Guard #18).
        onTap: enabled ? onTap : (onDisabledTap ?? () {}),
        splashFactory: enabled ? null : NoSplash.splashFactory,
        highlightColor: enabled ? null : Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: id == null ? Colors.transparent : AppColors.sageLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
                color: id == null ? AppColors.border : AppColors.sageBorder),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: id == null ? AppColors.textSecondary : AppColors.sageDark,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  id == null ? Icons.person_add_alt_1_outlined : Icons.person,
                  size: 12,
                  color: id == null ? AppColors.textSecondary : AppColors.sageDark,
                ),
                const SizedBox(width: 4),
                label,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mở picker — ONLINE-ONLY (§9.5): mất mạng thì báo "Cần mạng để giao việc".
Future<void> openAssigneePicker(
  BuildContext context,
  ShoppingStore store,
  ShoppingItem item, {
  required Future<bool> Function() isOnline,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  if (!await isOnline()) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.shoppingAssignNeedsNetwork)));
    return;
  }
  if (!context.mounted) return;
  // Roster lỗi hoặc lấy từ cache (có thể thiếu người mới) — đang online nên
  // nạp lại; scene chỉ initState 1 lần nên không ai làm thay.
  final family = shoppingFamilyStore();
  if (family != null &&
      (family.rosterState is ErrorState<HouseholdRoster> ||
          family.rosterIsFromCache)) {
    family.loadRoster();
  }
  final session = Get.find<SessionStore>();
  final me = session.currentUser?.id;
  final choice = await showModalBottomSheet<_AssigneeChoice>(
    context: context,
    builder: (_) => AssigneePickerSheet(
      item: item,
      familyStore: shoppingFamilyStore(),
      currentUserId: me,
      selfRole: session.role,
    ),
  );
  if (choice == null) return;
  final ok = await store.assign(item, assigneeId: choice.userId);
  if (!ok && store.assignError == null) {
    // assign() không gửi gì: mất mạng SAU khi mở picker, hoặc món vừa thành
    // PENDING_* (đang đồng bộ) — phải báo, không im lặng.
    messenger.showSnackBar(SnackBar(
        content: Text(await isOnline()
            ? l10n.shoppingAssignSyncing
            : l10n.shoppingAssignNeedsNetwork)));
    return;
  }
  if (!ok && store.assignError != null) {
    messenger.showSnackBar(SnackBar(
      content: Text(store.assignError!.code == 'ERR_SHOP_ASSIGNEE_INVALID'
          ? l10n.shoppingAssigneeInvalid
          : apiErrorMessage(l10n, store.assignError)),
    ));
    store.clearAssignError();
  }
}

class _AssigneeChoice {
  const _AssigneeChoice(this.userId);

  /// `null` = bỏ giao.
  final String? userId;
}

/// "Tôi nhận" luôn ở đầu; "Bỏ giao" khi món đang có người; roster lọc theo
/// whitelist. Không có FamilyStore → picker rút gọn, không crash (§9.5 B).
class AssigneePickerSheet extends StatelessWidget {
  const AssigneePickerSheet({
    super.key,
    required this.item,
    required this.familyStore,
    required this.currentUserId,
    this.selfRole,
  });

  final ShoppingItem item;
  final FamilyStore? familyStore;
  final String? currentUserId;

  /// Role JWT của chính mình — fallback khi roster chưa có (roster thắng).
  final String? selfRole;

  /// "Tôi nhận" chỉ khi CHÍNH MÌNH thuộc whitelist — REMOTE_VIEWER tự gán sẽ
  /// ăn 400 ERR_SHOP_ASSIGNEE_INVALID. Chưa biết role → vẫn cho (BE chặn cuối).
  bool _canSelfAssign() {
    final roster = familyStore?.rosterState;
    final effective =
        roster is SuccessState<HouseholdRoster> ? roster.data.callerRole : selfRole;
    return effective == null || _assignableRoles.contains(effective);
  }

  @override
  Widget build(BuildContext context) =>
      familyStore == null ? _build(context) : Observer(builder: _build);

  /// Trong Observer: mở sheet lúc roster đang tải thì danh sách tự hiện khi về.
  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final roster = familyStore?.rosterState;
    final others = roster is SuccessState<HouseholdRoster>
        ? roster.data.members
            .where((HouseholdMember m) =>
                _assignableRoles.contains(m.role) && m.userId != currentUserId)
            .toList()
        : const <HouseholdMember>[];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text(item.name, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (currentUserId != null &&
              item.assignedTo != currentUserId &&
              _canSelfAssign())
            ListTile(
              key: const ValueKey<String>('assignee-me'),
              leading: const Icon(Icons.front_hand_outlined, color: AppColors.sage),
              title: Text(l10n.shoppingAssignToMe),
              onTap: () => Navigator.of(context).pop(_AssigneeChoice(currentUserId)),
            ),
          for (final m in others)
            ListTile(
              key: ValueKey<String>('assignee-${m.userId}'),
              leading: const Icon(Icons.person_outline),
              title: Text(m.fullName),
              selected: item.assignedTo == m.userId,
              onTap: () => Navigator.of(context).pop(_AssigneeChoice(m.userId)),
            ),
          if (item.assignedTo != null)
            ListTile(
              key: const ValueKey<String>('assignee-clear'),
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
              title: Text(l10n.shoppingUnassign),
              onTap: () => Navigator.of(context).pop(const _AssigneeChoice(null)),
            ),
        ],
      ),
    );
  }
}
