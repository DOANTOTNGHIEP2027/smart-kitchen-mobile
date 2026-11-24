import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'domain/auth_validators.dart';
import 'otp_scene.dart';
import 'stores/auth_store.dart';
import 'stores/otp_store.dart';
import 'widgets/auth_frame.dart';

class EmailRegisterScene extends StatefulWidget {
  const EmailRegisterScene({super.key});

  @override
  State<EmailRegisterScene> createState() => _EmailRegisterSceneState();
}

class _EmailRegisterSceneState extends State<EmailRegisterScene> {
  late final AuthStore store = Get.find<AuthStore>();
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    fullName.dispose();
    store.reset();
    super.dispose();
  }

  Future<void> _submit() async {
    final registeredEmail = await store.register(email: email.text, password: password.text, fullName: fullName.text);
    if (registeredEmail != null) {
      Get.toNamed(AppRoutes.otp, arguments: OtpArguments(email: registeredEmail, flow: OtpFlow.register));
    }
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'register_title'.localized(context),
        subtitle: 'register_subtitle'.localized(context),
        child: Observer(builder: (_) => Column(children: [
              if (store.error != null && store.error!.code != 'ERR_AUTH_003') ...[
                FeatureBanner(message: errorCopy(context, store.error!.code)),
                const SizedBox(height: 16),
              ],
              AppTextField(
                key: const ValueKey<String>('register-full-name'),
                label: 'full_name'.localized(context),
                controller: fullName,
                enabled: !store.isSubmitting,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                hint: context.l10n.authFullNameExample,
                prefixIcon: Icons.person_outline,
                validator: (v) => AuthValidators.fullName(v)?.localized(context),
                errorText: _fieldError('fullName'),
                onChanged: (_) => store.clearFieldError('fullName'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: const ValueKey<String>('register-email'),
                label: 'email'.localized(context),
                controller: email,
                enabled: !store.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.newUsername],
                hint: context.l10n.authEmailExample,
                prefixIcon: Icons.alternate_email_rounded,
                validator: (v) => AuthValidators.email(v)?.localized(context),
                errorText: _fieldError('email'),
                onChanged: (_) => store.clearFieldError('email'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: const ValueKey<String>('register-password'),
                label: 'password'.localized(context),
                controller: password,
                enabled: !store.isSubmitting,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                helperText: 'password_hint'.localized(context),
                prefixIcon: Icons.lock_outline,
                validator: (v) => AuthValidators.password(v)?.localized(context),
                errorText: _fieldError('password'),
                onChanged: (_) => store.clearFieldError('password'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              AppButton(label: 'create_account'.localized(context), isLoading: store.isSubmitting, onPressed: _submit),
              AppButton(label: 'have_account_login'.localized(context), variant: AppButtonVariant.text, onPressed: () => Get.offNamed(AppRoutes.emailLogin)),
            ])),
      );

  String? _fieldError(String field) {
    final key = store.fieldErrors[field];
    return key?.localized(context);
  }
}
