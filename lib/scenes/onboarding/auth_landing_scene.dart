import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';
import '../../constants/app_text_styles.dart';
import '../../stores/auth_store.dart';
import '../../stores/submission_state.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/states/app_error_view.dart';
import 'onboarding_routes.dart';
import 'onboarding_router.dart';

/// S1.1 — landing chọn phương thức, và S2.1–S2.4 (các state Google Sign-In)
/// vì Flow 2 không có màn hình riêng: nó phủ lên chính landing.
class AuthLandingScene extends StatelessWidget {
  const AuthLandingScene({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<AuthStore>();

    return Observer(
      builder: (_) {
        final googleState = store.googleState;
        if (googleState is SubmissionFailure) {
          return AppScaffold(
            title: context.l10n.appTitle,
            body: _GoogleErrorView(state: googleState, store: store),
          );
        }

        return AppScaffold(
          body: Stack(
            children: <Widget>[
              const _LandingBody(),
              if (googleState.isBusy)
                _BlockingOverlay(message: context.l10n.authGoogleLoading),
            ],
          ),
        );
      },
    );
  }
}

class _LandingBody extends StatelessWidget {
  const _LandingBody();

  @override
  Widget build(BuildContext context) {
    final store = Get.find<AuthStore>();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppDimens.lg),
              Text(
                context.l10n.authLandingTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                context.l10n.authLandingSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.xl),
              AppButton(
                label: context.l10n.authGoogleCta,
                icon: Icons.account_circle_outlined,
                onPressed: () => _signInWithGoogle(context, store),
              ),
              const SizedBox(height: AppDimens.sm),
              AppButton(
                label: context.l10n.authEmailLoginCta,
                variant: AppButtonVariant.secondary,
                onPressed: () => Get.toNamed<void>(OnboardingRoutes.emailLogin),
              ),
              const SizedBox(height: AppDimens.sm),
              AppButton(
                label: context.l10n.authEmailRegisterCta,
                variant: AppButtonVariant.secondary,
                onPressed: () => Get.toNamed<void>(OnboardingRoutes.register),
              ),
              const SizedBox(height: AppDimens.lg),
              AppButton(
                label: context.l10n.authQrJoinCta,
                icon: Icons.qr_code_scanner,
                variant: AppButtonVariant.text,
                onPressed: () => Get.toNamed<void>(OnboardingRoutes.inviteScan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, AuthStore store) async {
    final messenger = ScaffoldMessenger.of(context);
    final linkedCopy = context.l10n.toastAccountLinked;

    final ok = await store.signInWithGoogle();
    if (!ok) return; // hủy hoặc lỗi — state của store đã phản ánh, không toast

    if (store.showAccountLinkedToast) {
      store.consumeAccountLinkedToast();
      messenger.showSnackBar(SnackBar(content: Text(linkedCopy)));
    }
    await routeAfterAuth();
  }
}

/// S2.2 / S2.3 / S2.4 — rẽ nhánh theo `error.code`, không theo `message`.
class _GoogleErrorView extends StatelessWidget {
  const _GoogleErrorView({required this.state, required this.store});

  final SubmissionFailure state;
  final AuthStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (String message, bool offerEmailInstead) = switch (state.code) {
      'ERR_AUTH_FIREBASE_UNAVAILABLE' => (l10n.errGoogleUnavailable, true),
      'ERR_AUTH_GOOGLE_EMAIL_REQUIRED' => (l10n.errGoogleNoEmail, true),
      'ERR_AUTH_001' => (l10n.errGoogleFailed, false),
      'ERR_NETWORK' => (l10n.errNetworkTitle, false),
      _ => (l10n.errServerTitle, false),
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: AppErrorView(
            message: message,
            onRetry: () async {
              store.resetGoogleState();
              await Get.find<AuthStore>().signInWithGoogle();
            },
          ),
        ),
        if (offerEmailInstead)
          Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: AppButton(
              label: l10n.authUseEmailInstead,
              variant: AppButtonVariant.text,
              onPressed: store.resetGoogleState,
            ),
          ),
      ],
    );
  }
}

/// S2.1 — overlay chặn tương tác trong lúc popup Google + gọi BE đang chạy.
class _BlockingOverlay extends StatelessWidget {
  const _BlockingOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.textPrimary.withValues(alpha: 0.45),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(color: AppColors.surface),
              const SizedBox(height: AppDimens.md),
              Text(
                message,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ),
      );
}
