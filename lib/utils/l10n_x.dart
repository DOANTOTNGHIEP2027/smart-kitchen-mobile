import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Truy cập chuỗi i18n: `context.l10n.appTitle`.
///
/// Không hardcode text ở bất kỳ widget nào — mọi chuỗi hiển thị phải đi qua
/// đây (CONTEXT_FE.md "Quy tắc bắt buộc khi thực thi FE").
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Temporary adapter while Feature 1's screen copy is progressively expressed
/// as typed ARB entries. It deliberately uses the app's generated
/// [AppLocalizations], never GetX's legacy translation registry.
extension FeatureL10nKeyX on String {
  String localized(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      'app_title' => l10n.appTitle,
      'auth_landing_subtitle' => l10n.authLandingSubtitle,
      'google_sign_in' => l10n.googleSignIn,
      'email_sign_in' => l10n.emailSignIn,
      'email_register' => l10n.emailRegister,
      'scan_join_qr' => l10n.scanJoinQr,
      'google_account_linked' => l10n.googleAccountLinked,
      'login_title' => l10n.loginTitle,
      'login_subtitle' => l10n.loginSubtitle,
      'auth_rate_limited' => l10n.authRateLimited,
      'email' => l10n.email,
      'password' => l10n.password,
      'sign_in' => l10n.signIn,
      'no_account_register' => l10n.noAccountRegister,
      'register_title' => l10n.registerTitle,
      'register_subtitle' => l10n.registerSubtitle,
      'full_name' => l10n.fullName,
      'password_hint' => l10n.passwordHint,
      'create_account' => l10n.createAccount,
      'have_account_login' => l10n.haveAccountLogin,
      'otp_title' => l10n.otpTitle,
      'otp_sent_to' => l10n.otpSentTo,
      'otp_code' => l10n.otpCode,
      'otp_expires' => l10n.otpExpires,
      'verified' => l10n.verified,
      'verify' => l10n.verify,
      'resend_otp' => l10n.resendOtp,
      'upgrade_profile_title' => l10n.upgradeProfileTitle,
      'upgrade_profile_subtitle' => l10n.upgradeProfileSubtitle,
      'full_name_optional' => l10n.fullNameOptional,
      'continue_to_otp' => l10n.continueToOtp,
      'household_setup_title' => l10n.householdSetupTitle,
      'household_setup_subtitle' => l10n.householdSetupSubtitle,
      'create_household' => l10n.createHousehold,
      'join_household' => l10n.joinHousehold,
      'household_name_required' => l10n.householdNameRequired,
      'household_name_too_long' => l10n.householdNameTooLong,
      'household_created' => l10n.householdCreated,
      'invite_qr_semantics' => l10n.inviteQrSemantics,
      'invite_members' => l10n.inviteMembers,
      'later' => l10n.later,
      'create_household_subtitle' => l10n.createHouseholdSubtitle,
      'household_name' => l10n.householdName,
      'join_household_subtitle' => l10n.joinHouseholdSubtitle,
      'already_in_household' => l10n.alreadyInHousehold,
      'camera_permission_denied' => l10n.cameraPermissionDenied,
      'open_settings' => l10n.openSettings,
      'enter_code_manually' => l10n.enterCodeManually,
      'camera_unavailable' => l10n.cameraUnavailable,
      'invite_code' => l10n.inviteCode,
      'preview_invite' => l10n.previewInvite,
      'scan_again' => l10n.scanAgain,
      'household_owner' => l10n.householdOwner,
      'member_count' => l10n.memberCount,
      'invite_expires' => l10n.inviteExpires,
      'display_name_optional' => l10n.displayNameOptional,
      'confirm_join' => l10n.confirmJoin,
      'network_error' => l10n.networkError,
      'google_unavailable' => l10n.googleUnavailable,
      'google_email_required' => l10n.googleEmailRequired,
      'google_token_invalid' => l10n.googleTokenInvalid,
      'otp_invalid' => l10n.otpInvalid,
      'otp_resend_limit' => l10n.otpResendLimit,
      'invite_invalid' => l10n.inviteInvalid,
      'invite_race' => l10n.inviteRace,
      'generic_retry_error' => l10n.genericRetryError,
      'guest_profile_banner' => l10n.guestProfileBanner,
      'complete_profile' => l10n.completeProfile,
      _ => this,
    };
  }
}
