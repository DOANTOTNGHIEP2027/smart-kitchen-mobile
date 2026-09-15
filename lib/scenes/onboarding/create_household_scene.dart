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
import '../../widgets/forms/app_text_field.dart';
import '../../widgets/invite_code_card.dart';
import 'onboarding_routes.dart';

/// S7.1–S7.4 — tạo household rồi hiển thị ngay mã mời đầu tiên.
class CreateHouseholdScene extends StatefulWidget {
  const CreateHouseholdScene({super.key});

  @override
  State<CreateHouseholdScene> createState() => _CreateHouseholdSceneState();
}

class _CreateHouseholdSceneState extends State<CreateHouseholdScene> {
  final HouseholdStore _store = Get.find<HouseholdStore>();
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await _store.createHousehold(_name.text);
    if (ok || !mounted) return;

    // S7.3 — ERR_HH_003: user đã có household (race giữa hai tab/thiết bị).
    // Không hiện lỗi tại chỗ; quay lại Flow 6 để re-resolve state thật.
    final state = _store.createState;
    if (state is SubmissionFailure && state.code == 'ERR_HH_003') {
      Get.snackbar('', context.l10n.errHouseholdRace);
      await Get.offAllNamed<void>(OnboardingRoutes.householdSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.createHouseholdTitle,
      body: Observer(
        builder: (_) {
          final created = _store.createdHousehold;
          if (created != null) return _SuccessBody(inviteCode: created.inviteCode);

          final state = _store.createState;
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
                        state.code != 'ERR_HH_003') ...<Widget>[
                      AppBanner(
                        message: state.code == 'ERR_NETWORK'
                            ? context.l10n.errNetworkTitle
                            : context.l10n.errServerTitle,
                        variant: AppBannerVariant.error,
                      ),
                      const SizedBox(height: AppDimens.md),
                    ],
                    AppTextField(
                      label: context.l10n.fieldHouseholdName,
                      controller: _name,
                      enabled: !busy,
                      maxLength: 255,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      errorText: _store.createNameError == null
                          ? null
                          : context.l10n.errHouseholdNameRequired,
                      onSubmitted: (_) => busy ? null : _submit(),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    AppButton(
                      label: context.l10n.createHouseholdCta,
                      isLoading: busy,
                      onPressed: _submit,
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

/// S7.4 — household đã tồn tại; mời thành viên là việc *có thể để sau*, khác
/// với bỏ qua toàn bộ việc thiết lập household.
class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.inviteCode});

  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.l10n.createHouseholdDoneTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                context.l10n.createHouseholdDoneSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.lg),
              Builder(
                builder: (BuildContext innerContext) => InviteCodeCard(
                  code: inviteCode,
                  onCopied: () => ScaffoldMessenger.of(innerContext).showSnackBar(
                    SnackBar(content: Text(innerContext.l10n.toastInviteCopied)),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              AppButton(
                label: context.l10n.inviteContinueCta,
                onPressed: () => Get.offAllNamed<void>(AppRoutes.shellRoot),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
