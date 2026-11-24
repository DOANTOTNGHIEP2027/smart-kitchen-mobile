import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'domain/auth_validators.dart';
import 'api/auth_api.dart';
import 'otp_scene.dart';
import 'stores/otp_store.dart';
import 'stores/upgrade_profile_store.dart';
import 'widgets/auth_frame.dart';

class UpgradeProfileScene extends StatefulWidget {
  const UpgradeProfileScene({super.key});

  @override
  State<UpgradeProfileScene> createState() => _UpgradeProfileSceneState();
}

class _UpgradeProfileSceneState extends State<UpgradeProfileScene> {
  late final UpgradeProfileStore store = UpgradeProfileStore(Get.find<AuthApi>(), Get.find());
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    fullName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (await store.submit(email: email.text, password: password.text, fullName: fullName.text)) {
      Get.toNamed(AppRoutes.otp, arguments: OtpArguments(email: email.text.trim(), flow: OtpFlow.upgrade));
    }
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'upgrade_profile_title'.localized(context),
        subtitle: 'upgrade_profile_subtitle'.localized(context),
        child: Observer(builder: (_) => Column(children: [
              if (store.error != null && store.error!.code != 'ERR_AUTH_003') ...[
                FeatureBanner(message: errorCopy(context, store.error!.code)),
                const SizedBox(height: 16),
              ],
              AppTextField(
                label: 'email'.localized(context),
                controller: email,
                enabled: !store.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                hint: context.l10n.authEmailExample,
                prefixIcon: Icons.alternate_email_rounded,
                validator: (v) => AuthValidators.email(v)?.localized(context),
                errorText: _fieldError('email'),
                onChanged: (_) => store.clearFieldError('email'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'password'.localized(context),
                controller: password,
                enabled: !store.isSubmitting,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => AuthValidators.password(v)?.localized(context),
                errorText: _fieldError('password'),
                onChanged: (_) => store.clearFieldError('password'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'full_name_optional'.localized(context),
                controller: fullName,
                enabled: !store.isSubmitting,
                textCapitalization: TextCapitalization.words,
                hint: context.l10n.authFullNameExample,
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    AuthValidators.fullName(v, required: false)?.localized(context),
                errorText: _fieldError('fullName'),
                onChanged: (_) => store.clearFieldError('fullName'),
              ),
              const SizedBox(height: 20),
              AppButton(label: 'continue_to_otp'.localized(context), isLoading: store.isSubmitting, onPressed: _submit),
            ])),
      );

  String? _fieldError(String field) {
    final key = store.fieldErrors[field];
    return key?.localized(context);
  }
}
