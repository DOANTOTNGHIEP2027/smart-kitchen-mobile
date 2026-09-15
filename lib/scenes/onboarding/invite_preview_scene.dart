import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../routing/app_routes.dart';
import '../../stores/household_store.dart';
import '../../stores/submission_state.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/forms/app_text_field.dart';
import '../../widgets/states/app_loading_view.dart';
import 'onboarding_routes.dart';

/// S8.4–S8.9 — preview mã mời rồi xác nhận tham gia.
class InvitePreviewScene extends StatefulWidget {
  const InvitePreviewScene({super.key});

  @override
  State<InvitePreviewScene> createState() => _InvitePreviewSceneState();
}

class _InvitePreviewSceneState extends State<InvitePreviewScene> {
  final HouseholdStore _store = Get.find<HouseholdStore>();
  final TextEditingController _displayName = TextEditingController();

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final messenger = ScaffoldMessenger.of(context);
    final joinedCopy = context.l10n.toastJoined;

    final ok = await _store.confirmJoin(displayName: _displayName.text);
    if (!ok || !mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(joinedCopy)));
    await Get.offAllNamed<void>(AppRoutes.shellRoot);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.previewTitle,
      body: Observer(
        builder: (_) {
          final previewState = _store.previewState;
          if (previewState.isBusy) return const AppLoadingView(); // S8.4

          // S8.7 — đã thuộc household khác: chặn ở client, không chạm BE.
          if (_store.joinRoute == JoinRoute.blocked) {
            return _BlockedBody(message: context.l10n.errAlreadyInHousehold);
          }

          if (previewState is SubmissionFailure) {
            return _InvalidBody(state: previewState); // S8.6
          }

          final preview = _store.preview;
          if (preview == null) return const AppLoadingView();

          final joinState = _store.joinState;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (joinState is SubmissionFailure) ...<Widget>[
                      AppBanner(
                        message: _joinErrorCopy(context, joinState),
                        variant: AppBannerVariant.error,
                      ),
                      const SizedBox(height: AppDimens.md),
                    ],
                    AppCard(
                      padding: const EdgeInsets.all(AppDimens.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            preview.householdName,
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: AppDimens.xs),
                          Text(
                            context.l10n.previewOwner(preview.ownerName),
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppDimens.xs),
                          Text(
                            context.l10n.previewMembers(preview.memberCount),
                            style: AppTextStyles.bodyMedium,
                          ),
                          if (preview.expiresAt != null) ...<Widget>[
                            const SizedBox(height: AppDimens.xs),
                            Text(
                              context.l10n.inviteExpiresAt(preview.expiresAt!),
                              style: AppTextStyles.label,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Chỉ luồng QR-join (chưa có JWT) mới hỏi tên hiển thị —
                    // Guard G9: BE mặc định "Thành viên" và không tự đánh số,
                    // nên để user tự đặt thay vì dựa vào default.
                    if (_store.asksForDisplayName) ...<Widget>[
                      const SizedBox(height: AppDimens.lg),
                      AppTextField(
                        label: context.l10n.fieldDisplayName,
                        controller: _displayName,
                        enabled: !joinState.isBusy,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 100,
                      ),
                    ],
                    const SizedBox(height: AppDimens.lg),
                    AppButton(
                      label: context.l10n.previewJoinCta,
                      isLoading: joinState.isBusy,
                      onPressed: _join,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// S8.9 — invite bị người khác dùng mất giữa lúc preview và confirm.
  String _joinErrorCopy(BuildContext context, SubmissionFailure state) =>
      switch (state.code) {
        'ERR_HH_005' ||
        'ERR_AUTH_INVITE_INVALID' ||
        'ERR_HH_003' =>
          context.l10n.errInviteRace,
        'ERR_HH_002' => context.l10n.errInviteInvalid,
        'ERR_NETWORK' => context.l10n.errNetworkTitle,
        _ => context.l10n.errServerTitle,
      };
}

/// S8.6 — mã không hợp lệ/hết hạn.
class _InvalidBody extends StatelessWidget {
  const _InvalidBody({required this.state});

  final SubmissionFailure state;

  @override
  Widget build(BuildContext context) {
    final message = switch (state.code) {
      'ERR_HH_002' => context.l10n.errInviteInvalid,
      'ERR_NETWORK' => context.l10n.errNetworkTitle,
      _ => context.l10n.errServerTitle,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              label: context.l10n.inviteTryAnother,
              expanded: false,
              onPressed: () {
                Get.find<HouseholdStore>().resetJoin();
                Get.offNamed<void>(OnboardingRoutes.inviteCode);
              },
            ),
            const SizedBox(height: AppDimens.sm),
            AppButton(
              label: context.l10n.scanRetry,
              variant: AppButtonVariant.text,
              expanded: false,
              onPressed: () {
                Get.find<HouseholdStore>().resetJoin();
                Get.offNamed<void>(OnboardingRoutes.inviteScan);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// S8.7 — thông báo chặn, **không** đưa ra hành động join nào.
class _BlockedBody extends StatelessWidget {
  const _BlockedBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.groups, size: AppDimens.stateIcon),
              const SizedBox(height: AppDimens.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppDimens.lg),
              AppButton(
                label: context.l10n.inviteContinueCta,
                expanded: false,
                onPressed: () => Get.offAllNamed<void>(AppRoutes.shellRoot),
              ),
            ],
          ),
        ),
      );
}
