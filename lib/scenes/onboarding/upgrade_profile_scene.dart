import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../stores/auth_store.dart';
import '../../stores/submission_state.dart';
import '../../utils/l10n_x.dart';
import '../../utils/validators.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/forms/app_text_field.dart';
import 'onboarding_routes.dart';

/// S9.2–S9.5 — nâng cấp tài khoản GUEST thành tài khoản email.
///
/// Banner S9.1 nằm ở màn hình profile (Flow 10, thuộc #29); màn hình này là
/// đích của CTA đó.
class UpgradeProfileScene extends StatefulWidget {
  const UpgradeProfileScene({super.key});

  @override
  State<UpgradeProfileScene> createState() => _UpgradeProfileSceneState();
}

class _UpgradeProfileSceneState extends State<UpgradeProfileScene> {
  final AuthStore _store = Get.find<AuthStore>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _fullName = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await _store.upgradeProfile(
      email: _email.text,
      password: _password.text,
      fullName: _fullName.text,
    );
    if (!ok || !mounted) return;
    // S9.5 — vẫn phải verify OTP; `flow=upgrade` nên sau khi xong quay lại
    // đây chứ không route lại theo household.
    await Get.offNamed<void>(OnboardingRoutes.otp);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.upgradeTitle,
      body: Observer(
        builder: (_) {
          final state = _store.upgradeState;
          final busy = state.isBusy;
          final fieldErrors = _store.upgradeFieldErrors;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      context.l10n.upgradeSubtitle,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppDimens.lg),
                    if (state is SubmissionFailure &&
                        state.code != 'ERR_AUTH_003') ...<Widget>[
                      AppBanner(
                        message: state.code == 'ERR_NETWORK'
                            ? context.l10n.errNetworkTitle
                            // ERR_AUTH_GUEST_ONLY rơi vào đây theo chủ ý: nó
                            // báo hiệu lệch state client/server, không phải
                            // luồng người dùng thường (ghi chú phòng thủ S9).
                            : context.l10n.errServerTitle,
                        variant: AppBannerVariant.error,
                      ),
                      const SizedBox(height: AppDimens.md),
                    ],
                    AppTextField(
                      label: context.l10n.fieldEmail,
                      controller: _email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      errorText: state is SubmissionFailure &&
                              state.code == 'ERR_AUTH_003'
                          ? context.l10n.errEmailTaken // S9.4, cùng copy S3.4
                          : fieldErrors['email'] == 'invalidEmail'
                              ? context.l10n.errInvalidEmail
                              : null,
                    ),
                    const SizedBox(height: AppDimens.md),
                    AppTextField(
                      label: context.l10n.fieldPassword,
                      controller: _password,
                      enabled: !busy,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      errorText: fieldErrors['password'] == 'passwordTooShort'
                          ? context.l10n.errPasswordTooShort
                          : null,
                    ),
                    const SizedBox(height: AppDimens.md),
                    AppTextField(
                      label: context.l10n.fieldFullNameOptional,
                      controller: _fullName,
                      enabled: !busy,
                      maxLength: Validators.fullNameMaxLength,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => busy ? null : _submit(),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    AppButton(
                      label: context.l10n.upgradeCta,
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
