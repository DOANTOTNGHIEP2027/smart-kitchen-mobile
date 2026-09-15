import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../stores/auth_store.dart';
import '../../stores/submission_state.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/forms/app_text_field.dart';
import 'onboarding_routes.dart';
import 'onboarding_router.dart';

/// S5.1–S5.4 — đăng nhập bằng email.
class LoginScene extends StatefulWidget {
  const LoginScene({super.key});

  @override
  State<LoginScene> createState() => _LoginSceneState();
}

class _LoginSceneState extends State<LoginScene> {
  final AuthStore _store = Get.find<AuthStore>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  /// Đếm ngược khóa tạm thời (S5.4). Timer thuộc widget để huỷ được, và chỉ
  /// chạy trong lúc đang khoá — trạng thái bình thường không tick gì cả.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void dispose() {
    _stopTicker();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _syncTicker() {
    if (_store.loginLockedUntil == null) {
      _stopTicker();
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_store.isLoginLocked) {
        // Xoá observable → Observer tự rebuild và mở lại form; không cần
        // setState cho cả màn hình nữa.
        _store.clearLoginLock();
        _stopTicker();
        return;
      }
      setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  int get _lockSecondsLeft {
    final until = _store.loginLockedUntil;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds;
    return left > 0 ? left : 0;
  }

  Future<void> _submit() async {
    final ok = await _store.login(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    _syncTicker(); // ERR_AUTH_RATE_LIMIT vừa có thể đã bật khoá
    if (!ok) return;
    await routeAfterAuth();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.loginTitle,
      body: Observer(
        builder: (_) {
          final state = _store.loginState;
          final locked = _store.isLoginLocked;
          final busy = state.isBusy;
          final disabled = busy || locked;
          final fieldErrors = _store.loginFieldErrors;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (locked) ...<Widget>[
                      AppBanner(
                        message: context.l10n.errLoginLocked(_lockSecondsLeft),
                        variant: AppBannerVariant.warning,
                      ),
                      const SizedBox(height: AppDimens.md),
                    ] else if (state is SubmissionFailure &&
                        state.code == 'ERR_NETWORK') ...<Widget>[
                      AppBanner(
                        message: context.l10n.errNetworkTitle,
                        variant: AppBannerVariant.error,
                      ),
                      const SizedBox(height: AppDimens.md),
                    ],
                    AppTextField(
                      label: context.l10n.fieldEmail,
                      controller: _email,
                      enabled: !disabled,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      errorText: fieldErrors['email'] == 'invalidEmail'
                          ? context.l10n.errInvalidEmail
                          : null,
                    ),
                    const SizedBox(height: AppDimens.md),
                    AppTextField(
                      label: context.l10n.fieldPassword,
                      controller: _password,
                      enabled: !disabled,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.password],
                      errorText: _passwordError(context, state, fieldErrors),
                      onSubmitted: (_) => disabled ? null : _submit(),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    AppButton(
                      label: context.l10n.loginCta,
                      isLoading: busy,
                      onPressed: locked ? null : _submit,
                    ),
                    const SizedBox(height: AppDimens.sm),
                    AppButton(
                      label: context.l10n.loginNoAccount,
                      variant: AppButtonVariant.text,
                      onPressed: disabled
                          ? null
                          : () => Get.offNamed<void>(OnboardingRoutes.register),
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

  /// S5.3 — một lỗi chung duy nhất dưới field mật khẩu. **Không bao giờ** tách
  /// "không tìm thấy email" khỏi "sai mật khẩu": BE cố ý trả cùng một code để
  /// chặn dò email, tách ra ở FE sẽ phá vỡ điều đó.
  String? _passwordError(
    BuildContext context,
    SubmissionState state,
    Map<String, String> fieldErrors,
  ) {
    if (state is SubmissionFailure && state.code == 'ERR_AUTH_004') {
      return context.l10n.errBadCredentials;
    }
    if (fieldErrors['password'] == 'passwordRequired') {
      return context.l10n.errPasswordRequired;
    }
    return null;
  }
}
