import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../constants/app_dimens.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feature_banner.dart';
import '../../widgets/states/app_loading_view.dart';
import '../../widgets/states/app_state_view.dart';
import '../../widgets/states/view_state.dart';
import 'domain/household_member.dart';
import 'domain/household_roster.dart';
import 'family_error_l10n.dart';
import 'profile_family_routes.dart';
import 'stores/family_store.dart';
import 'stores/form_status.dart';
import 'widgets/change_role_sheet.dart';
import 'widgets/household_budget_sheet.dart';
import 'widgets/household_plan_strip.dart';
import 'widgets/invite_result_sheet.dart';
import 'widgets/member_row.dart';
import 'widgets/stale_data_banner.dart';
import 'widgets/tier_widgets.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  late final FamilyStore store = Get.find<FamilyStore>();
  late final ReactionDisposer _noHouseholdRedirect;

  @override
  void initState() {
    super.initState();
    // S12.4: 404 ERR_HH_001 → về chọn tạo/tham gia Nhà (S6.2), KHÔNG render
    // lỗi + Thử lại tại chỗ (Guard 16d).
    _noHouseholdRedirect = reaction<ViewState<HouseholdRoster>>(
      (_) => store.rosterState,
      (state) {
        if (_isNoHousehold(state)) {
          Get.offAllNamed<void>(AppRoutes.householdSetup);
        }
      },
    );
    store.loadRoster();
    // Pipeline độc lập với roster (§19.3).
    store.loadBudget();
  }

  @override
  void dispose() {
    _noHouseholdRedirect();
    store.clearInviteError();
    store.clearRemoveMemberError();
    super.dispose();
  }

  static bool _isNoHousehold(ViewState<HouseholdRoster> state) =>
      state is ErrorState<HouseholdRoster> && state.error.code == 'ERR_HH_001';

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createInvite() async {
    final ok = await store.createInvite();
    if (!mounted) return;
    if (ok) {
      await _showInviteResult();
      return;
    }
    // ERR_HH_006 → banner giới hạn (S12.10) ngay dưới nút, không toast.
    if (store.mutationError?.code == 'ERR_HH_006') return;
    _toast(familyErrorMessage(context.l10n, store.mutationError));
  }

  /// S12.9 — kết quả mời BẮT BUỘC hiển thị. Đóng sheet → về idle, giữ
  /// `lastInvite` để mở lại trong phiên.
  Future<void> _showInviteResult() async {
    final invite = store.lastInvite;
    if (invite == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InviteResultSheet(invite: invite),
    );
    store.clearInviteError();
  }

  Future<void> _confirmRemove(HouseholdMember m) async {
    if (!store.canRemove(m)) return;
    final name =
        m.fullName.isEmpty ? context.l10n.familyRoleMember : m.fullName;
    store.clearRemoveMemberError();
    final removed = await showDialog<bool>(
      context: context,
      builder: (_) => _RemoveMemberDialog(store: store, member: m, name: name),
    );
    if (removed == null || !mounted) return;
    // Phòng thủ: `false` mà không có lỗi = store từ chối (guard), không phải
    // lỗi thao tác → không toast lỗi chung.
    if (!removed && store.mutationError == null) return;
    _toast(removed
        ? context.l10n.familyRemoveSuccess(name)
        : familyErrorMessage(context.l10n, store.mutationError));
  }

  void _openTierUpgrade() => Get.toNamed<void>(ProfileFamilyRoutes.tierUpgrade);

  Future<void> _openBudgetSheet() async {
    if (!store.canEditBudget) return;
    // Sheet có thể bị vuốt đóng khi đang gửi (PopScope không chặn drag) →
    // dispose bỏ qua clear; dọn lỗi cũ để lần mở sau không hiện banner cũ.
    store.clearBudgetMutationStatus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => HouseholdBudgetSheet(store: store),
    );
  }

  Future<void> _openChangeRole(HouseholdMember m) async {
    store.clearChangeRoleStatus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeRoleSheet(
        store: store,
        member: m,
        onUpgrade: store.isOwner ? _openTierUpgrade : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.familyTitle,
      body: Column(
        children: <Widget>[
          Observer(
            builder: (_) => store.rosterIsFromCache
                ? StaleDataBanner(onRetry: store.loadRoster)
                : const SizedBox.shrink(),
          ),
          // §10.4: ngay dưới AppBar, NGOÀI successBuilder — roster lỗi vẫn
          // hiện nhờ fallback JWT của isRemoteViewer.
          Observer(
            builder: (_) => RemoteViewerBanner(
              visible: store.isRemoteViewer,
              margin: const EdgeInsets.fromLTRB(
                  AppDimens.md, AppDimens.md, AppDimens.md, 0),
            ),
          ),
          Expanded(
            child: Observer(builder: (_) {
              final state = store.rosterState;
              // Đang chuyển sang S6.2 — không nháy AppErrorView + Thử lại.
              if (_isNoHousehold(state)) return const AppLoadingView();
              // Đọc trong Observer để theo dõi — successBuilder chạy ngoài
              // phạm vi theo dõi của Observer.
              final isOwner = store.isOwner;
              final fromCache = store.rosterIsFromCache;
              return RefreshIndicator(
                onRefresh: () => Future.wait(
                    <Future<void>>[store.loadRoster(), store.loadBudget()]),
                child: AppStateView<HouseholdRoster>(
                  state: state,
                  onRetry: () => store.loadRoster(),
                  emptyMessage: context.l10n.familyRosterEmpty,
                  successBuilder: (_, HouseholdRoster roster) =>
                      _roster(roster, isOwner: isOwner, fromCache: fromCache),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _roster(
    HouseholdRoster roster, {
    required bool isOwner,
    required bool fromCache,
  }) {
    final me = store.currentUserId;
    final hasOthers = roster.members.any((m) => m.userId != me);
    final invite = isOwner
        ? _InviteSection(
            store: store,
            onInvite: _createInvite,
            onShowLast: _showInviteResult,
          )
        : null;
    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.md, AppDimens.md, AppDimens.md, 0),
          child: HouseholdPlanStrip(
            store: store,
            onChangePlan: _openTierUpgrade,
            onEditBudget: _openBudgetSheet,
          ),
        ),
        if (invite != null && hasOthers) invite,
        ...roster.members.map(
          (HouseholdMember m) => MemberRow(
            member: m,
            isOwner: isOwner,
            isMe: m.userId == me,
            onTap: () => Get.toNamed(
                AppRoutes.memberDetail.replaceFirst(':userId', m.userId),
                arguments: <String, String>{
                  'userId': m.userId,
                  'fullName': m.fullName,
                }),
            // Guard 13 + 16b — canRemove đã gồm cờ cache.
            onRemove: !fromCache && store.canRemove(m)
                ? () => _confirmRemove(m)
                : null,
            onChangeRole: m.role == 'OWNER' || m.userId == me
                ? null
                : () => _openChangeRole(m),
          ),
        ),
        // Roster chỉ có mình: empty state + CTA mời (chỉ OWNER).
        if (!hasOthers) ...<Widget>[
          Padding(
            key: const ValueKey<String>('family-roster-empty'),
            padding: const EdgeInsets.fromLTRB(
                AppDimens.md, AppDimens.lg, AppDimens.md, 0),
            child: Text(
              context.l10n.familyRosterEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (invite != null) invite,
        ],
        const SizedBox(height: AppDimens.md),
      ],
    );
  }
}

/// Khối "Mời thành viên" (§10.4 F1/F2, S12.10): nút mời khoá khi cache (Guard
/// 13) hoặc đang gửi; banner giới hạn 3 lời mời; mở lại lời mời vừa tạo.
class _InviteSection extends StatelessWidget {
  const _InviteSection({
    required this.store,
    required this.onInvite,
    required this.onShowLast,
  });

  final FamilyStore store;
  final VoidCallback onInvite;
  final VoidCallback onShowLast;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.md, AppDimens.md, AppDimens.md, 0),
      child: Observer(builder: (_) {
        final submitting = store.inviteStatus == FormStatus.submitting;
        final last = store.lastInvite;
        final limitReached = store.inviteStatus == FormStatus.failure &&
            store.mutationError?.code == 'ERR_HH_006';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppButton(
              key: const ValueKey<String>('family-invite'),
              label: l10n.inviteMembers,
              icon: Icons.person_add_outlined,
              isLoading: submitting,
              onPressed: store.canInvite && !submitting ? onInvite : null,
            ),
            if (store.rosterIsFromCache) ...<Widget>[
              const SizedBox(height: AppDimens.xs),
              Text(
                l10n.familyNeedsNetwork,
                key: const ValueKey<String>('family-needs-network'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (limitReached) ...<Widget>[
              const SizedBox(height: AppDimens.sm),
              FeatureBanner(
                key: const ValueKey<String>('family-invite-limit'),
                message: l10n.familyErrorInviteLimit,
              ),
            ],
            if (last != null &&
                store.canInvite &&
                last.expiresAt.isAfter(DateTime.now()))
              TextButton(
                key: const ValueKey<String>('family-invite-show-last'),
                onPressed: submitting ? null : onShowLast,
                child: Text(l10n.familyInviteShowLast),
              ),
          ],
        );
      }),
    );
  }
}

/// S12.5 — xác nhận xoá nêu TÊN thành viên, nút xác nhận kiểu destructive.
/// Dialog tự gọi `removeMember` (hiện loading) rồi pop bằng context CỦA
/// DIALOG với kết quả; `null` = huỷ.
class _RemoveMemberDialog extends StatelessWidget {
  const _RemoveMemberDialog({
    required this.store,
    required this.member,
    required this.name,
  });

  final FamilyStore store;
  final HouseholdMember member;
  final String name;

  Future<void> _confirm(BuildContext dialogContext) async {
    final ok = await store.removeMember(member.userId);
    if (dialogContext.mounted) Navigator.of(dialogContext).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final submitting = store.isRemovingMember;
      return PopScope(
        canPop: !submitting,
        child: AlertDialog(
          title: Text(l10n.familyRemoveConfirm(name)),
          content: Text(l10n.familyRemoveConfirmBody(name)),
          actions: <Widget>[
            TextButton(
              key: const ValueKey<String>('family-remove-cancel'),
              onPressed: submitting ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.familyRemoveCancel),
            ),
            AppButton(
              key: const ValueKey<String>('family-remove-confirm'),
              label: l10n.familyRemoveConfirmAction,
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
