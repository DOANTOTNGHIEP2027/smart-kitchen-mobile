import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
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
              TextField(controller: fullName, enabled: !store.isSubmitting, textCapitalization: TextCapitalization.words, autofillHints: const [AutofillHints.name], decoration: InputDecoration(labelText: 'full_name'.localized(context), hintText: context.l10n.authFullNameExample, prefixIcon: const Icon(Icons.person_outline), errorText: _fieldError('fullName'))),
              const SizedBox(height: 12),
              TextField(controller: email, enabled: !store.isSubmitting, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.newUsername], decoration: InputDecoration(labelText: 'email'.localized(context), hintText: context.l10n.authEmailExample, prefixIcon: const Icon(Icons.alternate_email_rounded), errorText: _fieldError('email'))),
              const SizedBox(height: 12),
              TextField(controller: password, enabled: !store.isSubmitting, obscureText: true, autofillHints: const [AutofillHints.newPassword], onSubmitted: (_) => _submit(), decoration: InputDecoration(labelText: 'password'.localized(context), helperText: 'password_hint'.localized(context), prefixIcon: const Icon(Icons.lock_outline), errorText: _fieldError('password'))),
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
