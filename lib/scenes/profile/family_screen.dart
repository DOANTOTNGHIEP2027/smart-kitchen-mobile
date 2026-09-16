import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/states/app_state_view.dart';
import 'domain/household_member.dart';
import 'domain/household_roster.dart';
import 'stores/family_store.dart';
import 'stores/form_status.dart';
import 'widgets/member_row.dart';
import 'widgets/stale_data_banner.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  late final FamilyStore store = Get.find<FamilyStore>();

  @override
  void initState() {
    super.initState();
    store.loadRoster();
  }

  @override
  void dispose() {
    store.clearInviteError();
    super.dispose();
  }

  Future<void> _createInvite() async {
    final ok = await store.createInvite();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_inviteErrorCopy(context, store.mutationError))),
      );
    }
  }

  Future<void> _confirmRemove(HouseholdMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(context.l10n.familyRemoveConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.familyRemoveCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.familyRemove),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final removed = await store.removeMember(m.userId);
    if (!removed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(store.mutationError?.message ?? '')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.familyTitle,
      body: Column(
        children: <Widget>[
          Observer(
            builder: (_) => store.rosterIsFromCache
                ? const StaleDataBanner()
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Observer(
              builder: (_) => RefreshIndicator(
                onRefresh: () => store.loadRoster(),
                child: AppStateView<HouseholdRoster>(
                  state: store.rosterState,
                  onRetry: () => store.loadRoster(),
                  emptyMessage: context.l10n.familyRosterEmpty,
                  successBuilder: (_, HouseholdRoster roster) {
                    final isOwner = roster.callerRole == 'OWNER';
                    return ListView(
                      children: <Widget>[
                        ...roster.members.map(
                          (HouseholdMember m) => MemberRow(
                            member: m,
                            isOwner: isOwner,
                            onTap: () => Get.toNamed(
                                AppRoutes.memberDetail,
                                arguments: <String, String>{
                                  'userId': m.userId,
                                  'fullName': m.fullName,
                                }),
                            onRemove: () => _confirmRemove(m),
                          ),
                        ),
                        if (isOwner) ...<Widget>[
                          const Divider(height: AppDimens.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.md),
                            child: Observer(
                              builder: (_) => AppButton(
                                label: context.l10n.familyCreateInvite,
                                icon: Icons.person_add_outlined,
                                isLoading: store.inviteStatus ==
                                    FormStatus.submitting,
                                onPressed: store.inviteStatus ==
                                        FormStatus.submitting
                                    ? null
                                    : _createInvite,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimens.md),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _inviteErrorCopy(BuildContext context, Object? e) {
    final code = e.toString();
    if (code.contains('ERR_HH_006')) return context.l10n.familyInviteRateLimited;
    return context.l10n.genericRetryError;
  }
}
