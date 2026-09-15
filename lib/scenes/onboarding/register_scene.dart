import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../stores/auth_store.dart';
import '../../stores/submission_state.dart';
import '../../utils/l10n_x.dart';
import '../../utils/validators.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/forms/app_text_field.dart';
import 'onboarding_routes.dart';

/// S3.1–S3.5 — đăng ký bằng email.
class RegisterScene extends StatefulWidget {
  const RegisterScene({super.key});

  @override
  State<RegisterScene> createState() => _RegisterSceneState();
}

class _RegisterSceneState extends State<RegisterScene> {
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
    final ok = await _store.register(
      email: _email.text,
      password: _password.text,
      fullName: _fullName.text,
    );
    if (!ok || !mounted) return;
    await Get.toNamed<void>(OnboardingRoutes.otp);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.registerTitle,
      body: Observer(
        builder: (_) {
          final state = _store.registerState;
          final busy = state.isBusy;
          final fieldErrors = _store.registerFieldErrors;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (state is SubmissionFailure)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppDimens.md),
                        child: _RegisterFailureBanner(state: state),
                      ),
                    AppTextField(
                      label: context.l10n.fieldEmail,
                      controller: _email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      errorText: _emailError(context, state, fieldErrors),
                    ),
                    const SizedBox(height: AppDimens.md),
                    AppTextField(
                      label: context.l10n.fieldPassword,
                      controller: _password,
                      enabled: !busy,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.newPassword],
                      errorText: _localError(context, fieldErrors['password']),
                    ),
                    const SizedBox(height: AppDimens.md),
                    AppTextField(
                      label: context.l10n.fieldFullName,
                      controller: _fullName,
                      enabled: !busy,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      maxLength: Validators.fullNameMaxLength,
                      autofillHints: const <String>[AutofillHints.name],
                      errorText: _localError(context, fieldErrors['fullName']),
                      onSubmitted: (_) => busy ? null : _submit(),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    AppButton(
                      label: context.l10n.registerCta,
                      isLoading: busy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppDimens.sm),
                    AppButton(
                      label: context.l10n.registerHaveAccount,
                      variant: AppButtonVariant.text,
                      onPressed: busy
                          ? null
                          : () => Get.offNamed<void>(
                                OnboardingRoutes.emailLogin,
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

  /// S3.4 — `ERR_AUTH_003` hiện inline ngay dưới field email kèm lối sang đăng
  /// nhập, không phải một banner chung.
  String? _emailError(
    BuildContext context,
    SubmissionState state,
    Map<String, String> fieldErrors,
  ) {
    if (state is SubmissionFailure && state.code == 'ERR_AUTH_003') {
      return context.l10n.errEmailTaken;
    }
    return _localError(context, fieldErrors['email']);
  }

  String? _localError(BuildContext context, String? key) => switch (key) {
        'invalidEmail' => context.l10n.errInvalidEmail,
        'passwordTooShort' => context.l10n.errPasswordTooShort,
        'fullNameRequired' => context.l10n.errFullNameRequired,
        null => null,
        _ => key, // message theo từng field do BE trả về
      };
}

class _RegisterFailureBanner extends StatelessWidget {
  const _RegisterFailureBanner({required this.state});

  final SubmissionFailure state;

  @override
  Widget build(BuildContext context) {
    // ERR_AUTH_003 đã hiện inline dưới field email — không lặp lại ở banner.
    if (state.code == 'ERR_AUTH_003') return const SizedBox.shrink();

    final message = switch (state.code) {
      'ERR_NETWORK' => context.l10n.errNetworkTitle, // S3.5
      _ => context.l10n.errServerTitle,
    };
    return AppBanner(message: message, variant: AppBannerVariant.error);
  }
}
