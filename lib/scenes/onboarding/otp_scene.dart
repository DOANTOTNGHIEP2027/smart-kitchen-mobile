import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../stores/auth_store.dart';
import '../../stores/submission_state.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_banner.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/forms/app_text_field.dart';
import 'onboarding_router.dart';

/// S4.1–S4.5 — xác minh OTP. Dùng chung cho cả `flow=register` và
/// `flow=upgrade`; điều hướng sau khi thành công rẽ theo [AuthStore.otpFlow].
class OtpScene extends StatefulWidget {
  const OtpScene({super.key});

  @override
  State<OtpScene> createState() => _OtpSceneState();
}

class _OtpSceneState extends State<OtpScene> {
  final AuthStore _store = Get.find<AuthStore>();
  final TextEditingController _otp = TextEditingController();

  /// Ticker của đồng hồ đếm ngược resend. Timer sống ở widget (không phải
  /// store) để nó được huỷ cùng màn hình — store không có lifecycle dispose.
  ///
  /// Chỉ chạy **trong lúc đang đếm ngược**: người dùng gõ mã OTP ở đây, một
  /// `setState` mỗi giây cho cả form là chi phí thừa khi cooldown đã hết.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void dispose() {
    _stopTicker();
    _otp.dispose();
    super.dispose();
  }

  void _syncTicker() {
    if (_resendSecondsLeft <= 0) {
      _stopTicker();
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_resendSecondsLeft <= 0) _stopTicker();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  int get _resendSecondsLeft {
    final availableAt = _store.resendAvailableAt;
    if (availableAt == null) return 0;
    final left = availableAt.difference(DateTime.now()).inSeconds;
    return left > 0 ? left : 0;
  }

  Future<void> _verify() async {
    final ok = await _store.verifyOtp(_otp.text);
    if (!ok) {
      _otp.clear(); // S4.3 — xoá input để user nhập lại
      return;
    }
    if (!mounted) return;

    if (_store.otpFlow == OtpFlow.upgrade) {
      // `household_id`/`role` giữ nguyên xuyên suốt nâng cấp — không route lại.
      Get.back<void>();
      return;
    }
    await routeAfterAuth();
  }

  Future<void> _resend() async {
    final messenger = ScaffoldMessenger.of(context);
    final sentCopy = context.l10n.toastOtpSent;
    await _store.resendOtp();
    if (!mounted) return;
    _syncTicker(); // cooldown mới vừa được đặt
    if (_store.resendState is SubmissionSuccess) {
      messenger.showSnackBar(SnackBar(content: Text(sentCopy)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.otpTitle,
      body: Observer(
        builder: (_) {
          final state = _store.otpState;
          final busy = state.isBusy;
          final secondsLeft = _resendSecondsLeft;
          final resendState = _store.resendState;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      context.l10n.otpSubtitle(_store.pendingEmail ?? ''),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppDimens.lg),
                    if (resendState is SubmissionFailure &&
                        resendState.code == 'ERR_AUTH_OTP_LIMIT') ...<Widget>[
                      // S4.4 — BE không trả retry-after nên chỉ thông báo tĩnh.
                      AppBanner(
                        message: context.l10n.errOtpLimit,
                        variant: AppBannerVariant.warning,
                      ),
                      const SizedBox(height: AppDimens.md),
                    ],
                    AppTextField(
                      label: context.l10n.fieldOtp,
                      controller: _otp,
                      enabled: !busy,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      autofillHints: const <String>[AutofillHints.oneTimeCode],
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      errorText: state is SubmissionFailure
                          ? _errorCopy(context, state)
                          : null,
                      onSubmitted: (_) => busy ? null : _verify(),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    AppButton(
                      label: context.l10n.otpVerifyCta,
                      isLoading: busy,
                      onPressed: _verify,
                    ),
                    const SizedBox(height: AppDimens.sm),
                    AppButton(
                      label: secondsLeft > 0
                          ? context.l10n.otpResendIn(secondsLeft)
                          : context.l10n.otpResendCta,
                      variant: AppButtonVariant.text,
                      isLoading: resendState.isBusy,
                      onPressed:
                          secondsLeft > 0 || busy ? null : () => _resend(),
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

  String _errorCopy(BuildContext context, SubmissionFailure state) =>
      switch (state.code) {
        'ERR_AUTH_OTP_INVALID' => context.l10n.errOtpInvalid,
        'ERR_NETWORK' => context.l10n.errNetworkTitle,
        _ => context.l10n.errServerTitle,
      };
}
