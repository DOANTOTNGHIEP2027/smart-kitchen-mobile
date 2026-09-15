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
  String get stateEmptyDefault => 'Nothing here yet';

  @override
  String get stateErrorDefault => 'Something went wrong';

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
  String get devLoginTitle => 'Sign in';

  @override
  String get devLoginSubtitle =>
      'The real sign-in flow (Google / OTP / QR join) ships with fe-onboarding.';

  @override
  String get devLoginCta => 'Continue as demo user';

  @override
  String get devLoginBanner => 'App shell demo — no backend call is made';

  @override
  String get authLandingSubtitle => 'Sign in to manage your kitchen together';

  @override
  String get googleSignIn => 'Continue with Google';

  @override
  String get emailSignIn => 'Sign in with email';

  @override
  String get emailRegister => 'Create an account';

  @override
  String get scanJoinQr => 'Scan a household QR code';

  @override
  String get googleAccountLinked => 'Your Google account is linked';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get authRateLimited => 'Too many attempts. Try again in';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get noAccountRegister => 'No account? Create one';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Start cooking together';

  @override
  String get fullName => 'Full name';

  @override
  String get passwordHint => 'At least 8 characters';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccountLogin => 'Already have an account? Sign in';

  @override
  String get otpTitle => 'Verify your email';

  @override
  String get otpSentTo => 'We sent a code to';

  @override
  String get otpCode => 'Verification code';

  @override
  String get otpExpires => 'Code expires in';

  @override
  String get verified => 'Verified';

  @override
  String get verify => 'Verify';

  @override
  String get resendOtp => 'Resend code';

  @override
  String get upgradeProfileTitle => 'Complete your profile';

  @override
  String get upgradeProfileSubtitle =>
      'Add an email and password to keep your account';

  @override
  String get fullNameOptional => 'Full name (optional)';

  @override
  String get continueToOtp => 'Continue';

  @override
  String get householdSetupTitle => 'Set up your household';

  @override
  String get householdSetupSubtitle =>
      'Create a household or join one with an invite';

  @override
  String get createHousehold => 'Create household';

  @override
  String get joinHousehold => 'Join household';

  @override
  String get householdNameRequired => 'Enter a household name';

  @override
  String get householdNameTooLong => 'Household name is too long';

  @override
  String get householdCreated => 'Household created';

  @override
  String get inviteQrSemantics => 'Household invitation QR code';

  @override
  String get inviteMembers => 'Invite members';

  @override
  String get later => 'Later';

  @override
  String get createHouseholdSubtitle => 'Give your household a name';

  @override
  String get householdName => 'Household name';

  @override
  String get joinHouseholdSubtitle => 'Scan an invite or enter its code';

  @override
  String get alreadyInHousehold => 'You already belong to a household';

  @override
  String get cameraPermissionDenied =>
      'Camera permission is required to scan QR codes';

  @override
  String get openSettings => 'Open settings';

  @override
  String get enterCodeManually => 'Enter code manually';

  @override
  String get cameraUnavailable => 'Camera is unavailable';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get previewInvite => 'Preview invite';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get householdOwner => 'Owner';

  @override
  String get memberCount => 'Members';

  @override
  String get inviteExpires => 'Invite expires';

  @override
  String get displayNameOptional => 'Display name (optional)';

  @override
  String get confirmJoin => 'Join household';

  @override
  String get networkError => 'Check your connection and try again';

  @override
  String get googleUnavailable =>
      'Google sign-in is not configured for this app';

  @override
  String get googleEmailRequired => 'A Google email address is required';

  @override
  String get googleTokenInvalid => 'Google sign-in could not be verified';

  @override
  String get otpInvalid => 'Enter the 6-digit code';

  @override
  String get otpResendLimit => 'Too many code requests. Try again later';

  @override
  String get inviteInvalid => 'This invitation is invalid or expired';

  @override
  String get inviteRace => 'This invitation is no longer available';

  @override
  String get genericRetryError => 'Something went wrong. Please try again';

  @override
  String get guestProfileBanner =>
      'Complete your profile to keep access to your household';

  @override
  String get completeProfile => 'Complete profile';
}
