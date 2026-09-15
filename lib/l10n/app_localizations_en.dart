// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Kitchen';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonLater => 'Later';

  @override
  String get stateEmptyDefault => 'Nothing here yet';

  @override
  String get stateErrorDefault => 'Something went wrong';

  @override
  String get errNetworkTitle => 'No internet connection';

  @override
  String get errServerTitle => 'Something went wrong, please try again';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get navHome => 'Home';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navPlanning => 'Planning';

  @override
  String get navShopping => 'Shopping';

  @override
  String get navProfile => 'Profile';

  @override
  String get authLandingTitle => 'Welcome to Smart Kitchen';

  @override
  String get authLandingSubtitle =>
      'Plan meals, track your pantry, and cut food waste together.';

  @override
  String get authGoogleCta => 'Continue with Google';

  @override
  String get authEmailLoginCta => 'Sign in with email';

  @override
  String get authEmailRegisterCta => 'Create an account';

  @override
  String get authQrJoinCta => 'Join a family with a QR code';

  @override
  String get authGoogleLoading => 'Signing you in with Google…';

  @override
  String get authUseEmailInstead => 'Use email instead';

  @override
  String get errGoogleUnavailable => 'We can\'t reach Google right now.';

  @override
  String get errGoogleNoEmail =>
      'That Google account has no email we can use. Sign up with email instead.';

  @override
  String get errGoogleFailed => 'Google sign-in failed, please try again.';

  @override
  String get toastAccountLinked =>
      'Your Google account was linked to your existing email.';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldFullNameOptional => 'Full name (optional)';

  @override
  String get fieldOtp => '6-digit code';

  @override
  String get fieldHouseholdName => 'Family name';

  @override
  String get fieldInviteCode => 'Invite code';

  @override
  String get fieldDisplayName => 'Your display name';

  @override
  String get errInvalidEmail => 'Enter a valid email address';

  @override
  String get errPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get errPasswordRequired => 'Enter your password';

  @override
  String get errFullNameRequired => 'Enter your name';

  @override
  String get errHouseholdNameRequired => 'Enter a family name';

  @override
  String get registerTitle => 'Create an account';

  @override
  String get registerCta => 'Create account';

  @override
  String get registerHaveAccount => 'Already have an account? Sign in';

  @override
  String get errEmailTaken => 'This email is already registered';

  @override
  String get otpTitle => 'Verify your email';

  @override
  String otpSubtitle(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String get otpVerifyCta => 'Verify';

  @override
  String get otpResendCta => 'Resend code';

  @override
  String otpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get errOtpInvalid => 'That code is wrong or has expired';

  @override
  String get errOtpLimit =>
      'You\'ve requested too many codes. Please wait before trying again.';

  @override
  String get toastOtpSent => 'Code sent';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginCta => 'Sign in';

  @override
  String get loginNoAccount => 'No account yet? Create one';

  @override
  String get errBadCredentials => 'Email or password is incorrect';

  @override
  String errLoginLocked(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s.';
  }

  @override
  String get householdSetupTitle => 'Set up your family';

  @override
  String get householdSetupSubtitle =>
      'Smart Kitchen works around a shared family pantry. Create one or join an existing family.';

  @override
  String get householdCreateCta => 'Create a new family';

  @override
  String get householdJoinCta => 'Join with an invite code';

  @override
  String get createHouseholdTitle => 'Create a family';

  @override
  String get createHouseholdCta => 'Create';

  @override
  String get createHouseholdDoneTitle => 'Family created';

  @override
  String get createHouseholdDoneSubtitle =>
      'Share this code so your family can join.';

  @override
  String get errHouseholdRace =>
      'You already belong to a family. Taking you there…';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get inviteCopyCta => 'Copy link';

  @override
  String get toastInviteCopied => 'Invite link copied';

  @override
  String inviteExpiresAt(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Expires $dateString';
  }

  @override
  String get inviteContinueCta => 'Continue';

  @override
  String get scanTitle => 'Scan invite QR';

  @override
  String get scanHint => 'Point the camera at the invite QR code';

  @override
  String get scanPermissionDenied =>
      'Smart Kitchen needs camera access to scan the invite QR code.';

  @override
  String get scanEnterManually => 'Enter code manually';

  @override
  String get scanRetry => 'Scan again';

  @override
  String get inviteCodeTitle => 'Enter invite code';

  @override
  String get inviteCodeCta => 'Look up';

  @override
  String get errInviteCodeFormat => 'Invite codes are 8 letters or digits';

  @override
  String get previewTitle => 'Join this family?';

  @override
  String previewOwner(String name) {
    return 'Owner: $name';
  }

  @override
  String previewMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get previewJoinCta => 'Join';

  @override
  String get errInviteInvalid => 'This invite code is invalid or has expired';

  @override
  String get inviteTryAnother => 'Try another code';

  @override
  String get errAlreadyInHousehold => 'You already belong to another family.';

  @override
  String get errInviteRace => 'Someone just used this invite code';

  @override
  String get toastJoined => 'You\'ve joined the family';

  @override
  String get upgradeBannerText =>
      'Add an email so you don\'t lose this account';

  @override
  String get upgradeBannerCta => 'Set up email';

  @override
  String get upgradeTitle => 'Secure your account';

  @override
  String get upgradeSubtitle =>
      'Add an email and password so you can sign back in on any device.';

  @override
  String get upgradeCta => 'Continue';
}
