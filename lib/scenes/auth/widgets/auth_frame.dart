import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../utils/l10n_x.dart';

class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.title, required this.subtitle, required this.child, this.showBrand = false});

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBrand;

  @override
  Widget build(BuildContext context) => AppScaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showBrand) ...[
                      const Align(child: BrandMark()),
                      const SizedBox(height: AppDimens.lg),
                    ],
                    Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                    const SizedBox(height: AppDimens.sm),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: AppDimens.xl),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryGradientStart, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.primaryShadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const SizedBox(width: 56, height: 56, child: Icon(Icons.soup_kitchen_rounded, color: Colors.white, size: 30)),
      );
}

class FeatureBanner extends StatelessWidget {
  const FeatureBanner({super.key, required this.message, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFFFEEEE) : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Row(children: [
            Icon(isError ? Icons.error_outline : Icons.info_outline, color: isError ? AppColors.error : AppColors.primary),
            const SizedBox(width: AppDimens.sm),
            Expanded(child: Text(message)),
          ]),
        ),
      );
}

String errorCopyKey(String code) => switch (code) {
      'ERR_NETWORK' => 'network_error',
      'ERR_AUTH_FIREBASE_UNAVAILABLE' => 'google_unavailable',
      'ERR_AUTH_GOOGLE_EMAIL_REQUIRED' => 'google_email_required',
      'ERR_AUTH_001' => 'google_token_invalid',
      'ERR_AUTH_RATE_LIMIT' => 'auth_rate_limited',
      'ERR_AUTH_OTP_INVALID' => 'otp_invalid',
      'ERR_AUTH_OTP_LIMIT' => 'otp_resend_limit',
      'ERR_HH_002' => 'invite_invalid',
      'ERR_HH_003' || 'CLIENT_ALREADY_IN_HOUSEHOLD' => 'already_in_household',
      'ERR_HH_005' || 'ERR_AUTH_INVITE_INVALID' => 'invite_race',
      _ => 'generic_retry_error',
    };

String errorCopy(BuildContext context, String code) =>
    errorCopyKey(code).localized(context);
