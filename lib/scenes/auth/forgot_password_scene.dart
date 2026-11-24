import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'domain/auth_validators.dart';
import 'api/auth_api.dart';
import 'stores/password_reset_store.dart';
import 'widgets/auth_frame.dart';

/// Bước 1 của luồng đặt lại mật khẩu: nhập email để nhận OTP.
class ForgotPasswordScene extends StatefulWidget {
  const ForgotPasswordScene({super.key});

  @override
  State<ForgotPasswordScene> createState() => _ForgotPasswordSceneState();
}

class _ForgotPasswordSceneState extends State<ForgotPasswordScene> {
  // Store đăng ký vào GetX để chia sẻ trạng thái (email, cooldown, ttl) sang
  // ResetPasswordScene; getter ở [dispose] tránh double-delete khi màn đã bị dỡ.
  late final PasswordResetStore store = Get.put<PasswordResetStore>(PasswordResetStore(Get.find<AuthApi>()));
  final email = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    if (Get.isRegistered<PasswordResetStore>()) Get.delete<PasswordResetStore>();
    store.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (await store.requestOtp(email.text)) {
      Get.toNamed(AppRoutes.resetPassword, arguments: store.email);
    }
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
        title: 'auth_forgot_password_title'.localized(context),
        subtitle: 'auth_forgot_password_hint'.localized(context),
        child: Observer(builder: (_) => Column(children: [
              if (store.error != null) ...[
                FeatureBanner(message: errorCopy(context, store.error!.code)),
                const SizedBox(height: 16),
              ],
              AppTextField(
                label: 'email'.localized(context),
                controller: email,
                enabled: !store.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                hint: context.l10n.authEmailExample,
                prefixIcon: Icons.alternate_email_rounded,
                validator: (v) => AuthValidators.email(v)?.localized(context),
                errorText: _fieldError('email'),
                onChanged: (_) => store.clearFieldError('email'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'auth_send_reset_otp'.localized(context),
                isLoading: store.isSubmitting,
                onPressed: _submit,
              ),
            ])),
      );

  String? _fieldError(String field) {
    final key = store.fieldErrors[field];
    return key?.localized(context);
  }
}
