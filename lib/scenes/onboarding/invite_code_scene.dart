import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../stores/household_store.dart';
import '../../stores/submission_state.dart';
import '../../utils/l10n_x.dart';
import '../../utils/validators.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/forms/app_text_field.dart';
import 'onboarding_routes.dart';

/// S8.3 — nhập mã mời thủ công. Cũng là fallback khi bị từ chối quyền camera.
class InviteCodeScene extends StatefulWidget {
  const InviteCodeScene({super.key});

  @override
  State<InviteCodeScene> createState() => _InviteCodeSceneState();
}

class _InviteCodeSceneState extends State<InviteCodeScene> {
  final HouseholdStore _store = Get.find<HouseholdStore>();
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await _store.loadPreview(_code.text);
    if (!ok || !mounted) return;
    await Get.toNamed<void>(OnboardingRoutes.invitePreview);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.inviteCodeTitle,
      body: Observer(
        builder: (_) {
          final state = _store.previewState;
          final busy = state.isBusy;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (state is SubmissionFailure &&
                        state.code == 'ERR_NETWORK') ...<Widget>[
                      AppBanner(
                        message: context.l10n.errNetworkTitle,
                        variant: AppBannerVariant.error,
                      ),
                      const SizedBox(height: AppDimens.md),
                    ],
                    AppTextField(
                      label: context.l10n.fieldInviteCode,
                      controller: _code,
                      enabled: !busy,
                      maxLength: Validators.inviteCodeLength,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9]'),
                        ),
                        TextInputFormatter.withFunction(
                          (TextEditingValue _, TextEditingValue next) =>
                              next.copyWith(text: next.text.toUpperCase()),
                        ),
                      ],
                      errorText: state is SubmissionFailure &&
                              state.code == 'ERR_HH_002'
                          ? context.l10n.errInviteInvalid
                          : null,
                      onSubmitted: (_) => busy ? null : _submit(),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    AppButton(
                      label: context.l10n.inviteCodeCta,
                      isLoading: busy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppDimens.sm),
                    AppButton(
                      label: context.l10n.scanRetry,
                      icon: Icons.qr_code_scanner,
                      variant: AppButtonVariant.text,
                      onPressed: busy
                          ? null
                          : () => Get.toNamed<void>(
                                OnboardingRoutes.inviteScan,
                              ),
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
}
