import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../routing/app_routes.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'domain/auth_validators.dart';
import 'stores/password_reset_store.dart';
import 'widgets/auth_frame.dart';

/// Bước 2 của luồng đặt lại mật khẩu: xác thực OTP + đặt mật khẩu mới.
///
/// Email nhận qua `Get.arguments` từ [ForgotPasswordScene]. Thiếu email thì
/// quay lại bước 1 để tránh màn rỗng.
class ResetPasswordScene extends StatefulWidget {
  const ResetPasswordScene({super.key});

  @override
  State<ResetPasswordScene> createState() => _ResetPasswordSceneState();
}

class _ResetPasswordSceneState extends State<ResetPasswordScene> {
  late final String email =
      Get.arguments is String ? Get.arguments as String : '';
  // Store do ForgotPasswordScene đăng ký, dùng chung để giữ cooldown/ttl giữa
  // hai bước. Màn này KHÔNG dispose store (không phải chủ sở hữu) — nếu người
  // dùng back về bước 1, store vẫn phải sống.
  PasswordResetStore? store;
  final emailField = TextEditingController();
  final otp = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    emailField.text = email;
    if (email.isEmpty || !Get.isRegistered<PasswordResetStore>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Get.offNamed(AppRoutes.forgotPassword);
      });
      return;
    }
    store = Get.find<PasswordResetStore>()..email = email;
  }

  @override
  void dispose() {
    emailField.dispose();
    otp.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = store;
    if (current == null) return;
    if (!await current.reset(
        otp: otp.text,
        newPassword: newPassword.text,
        confirmPassword: confirmPassword.text)) {
      if (current.error?.code == 'ERR_AUTH_OTP_INVALID') otp.clear();
      return;
    }
    if (!mounted) return;
    AppToast.show('auth_reset_success'.localized(context),
        type: AppToastType.success);
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final current = store;
    if (current == null) return const SizedBox.shrink();
    return AuthFrame(
      title: 'auth_reset_password_title'.localized(context),
      subtitle: '${'otp_sent_to'.localized(context)}\n$email',
      child: Observer(
        builder: (_) => Column(
          children: <Widget>[
            ..._banners(context, current),
            _emailField(context),
            const SizedBox(height: 12),
            _otpField(context, current),
            const SizedBox(height: 12),
            _newPasswordField(context, current),
            const SizedBox(height: 12),
            _confirmPasswordField(context, current),
            const SizedBox(height: 12),
            Text(
                '${'otp_expires'.localized(context)} ${_clock(current.ttlSeconds)}'),
            const SizedBox(height: 20),
            AppButton(
              label: 'auth_reset_password_submit'.localized(context),
              isLoading: current.isSubmitting,
              onPressed: _submit,
            ),
            AppButton(
              label: current.cooldownSeconds > 0
                  ? '${'resend_otp'.localized(context)} (${current.cooldownSeconds}s)'
                  : 'resend_otp'.localized(context),
              variant: AppButtonVariant.text,
              onPressed: current.canResend ? current.resendOtp : null,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _banners(BuildContext context, PasswordResetStore current) {
    if (current.isLocked) {
      return <Widget>[
        FeatureBanner(
            message:
                '${'auth_rate_limited'.localized(context)} ${current.lockSeconds}s'),
        const SizedBox(height: 16),
      ];
    }
    final error = current.error;
    if (error != null && error.code != 'ERR_AUTH_OTP_INVALID') {
      return <Widget>[
        FeatureBanner(message: errorCopy(context, error.code)),
        const SizedBox(height: 16),
      ];
    }
    return const <Widget>[];
  }

  Widget _emailField(BuildContext context) => AppTextField(
        label: 'email'.localized(context),
        controller: emailField,
        readOnly: true,
        enabled: false,
        prefixIcon: Icons.alternate_email_rounded,
      );

  Widget _otpField(BuildContext context, PasswordResetStore current) =>
      TextField(
        controller: otp,
        enabled: !current.isSubmitting,
        keyboardType: TextInputType.number,
        autofocus: true,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'otp_code'.localized(context),
          prefixIcon: const Icon(Icons.password_rounded),
          errorText: _fieldError('otp'),
        ),
      );

  Widget _newPasswordField(BuildContext context, PasswordResetStore current) =>
      AppTextField(
        label: 'auth_new_password'.localized(context),
        controller: newPassword,
        enabled: !current.isSubmitting,
        obscureText: true,
        autofillHints: const <String>[AutofillHints.newPassword],
        prefixIcon: Icons.lock_outline,
        validator: (v) => AuthValidators.password(v)?.localized(context),
        errorText: _fieldError('newPassword'),
        onChanged: (_) => current.clearFieldError('newPassword'),
      );

  Widget _confirmPasswordField(
          BuildContext context, PasswordResetStore current) =>
      AppTextField(
        label: 'auth_confirm_password'.localized(context),
        controller: confirmPassword,
        enabled: !current.isSubmitting,
        obscureText: true,
        autofillHints: const <String>[AutofillHints.newPassword],
        prefixIcon: Icons.lock_outline,
        validator: (v) => v == newPassword.text
            ? null
            : 'auth_password_mismatch'.localized(context),
        errorText: _fieldError('confirmPassword'),
        onChanged: (_) => current.clearFieldError('confirmPassword'),
        onSubmitted: (_) => _submit(),
      );

  String? _fieldError(String field) {
    final key = store?.fieldErrors[field];
    return key?.localized(context);
  }

  String _clock(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
