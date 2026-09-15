import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// Application name shown in the OS task switcher
  ///
  /// In en, this message translates to:
  /// **'Smart Kitchen'**
  String get appTitle;

  /// Retry button on the shared error state
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get commonLater;

  /// Fallback copy for AppEmptyView when the caller gives no message
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateEmptyDefault;

  /// Fallback copy for AppErrorView when the caller gives no message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get stateErrorDefault;

  /// S13.1 — full-screen network-down retry state
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errNetworkTitle;

  /// S13.2 — generic catch-all server error
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again'**
  String get errServerTitle;

  /// Placeholder body of every shell tab until its feature ships
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get navPlanning;

  /// No description provided for @navShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get navShopping;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// S1.1 auth landing headline
  ///
  /// In en, this message translates to:
  /// **'Welcome to Smart Kitchen'**
  String get authLandingTitle;

  /// No description provided for @authLandingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan meals, track your pantry, and cut food waste together.'**
  String get authLandingSubtitle;

  /// No description provided for @authGoogleCta.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogleCta;

  /// No description provided for @authEmailLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get authEmailLoginCta;

  /// No description provided for @authEmailRegisterCta.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authEmailRegisterCta;

  /// No description provided for @authQrJoinCta.
  ///
  /// In en, this message translates to:
  /// **'Join a family with a QR code'**
  String get authQrJoinCta;

  /// S2.1 overlay copy
  ///
  /// In en, this message translates to:
  /// **'Signing you in with Google…'**
  String get authGoogleLoading;

  /// No description provided for @authUseEmailInstead.
  ///
  /// In en, this message translates to:
  /// **'Use email instead'**
  String get authUseEmailInstead;

  /// S2.2 — ERR_AUTH_FIREBASE_UNAVAILABLE
  ///
  /// In en, this message translates to:
  /// **'We can\'t reach Google right now.'**
  String get errGoogleUnavailable;

  /// S2.3 — ERR_AUTH_GOOGLE_EMAIL_REQUIRED
  ///
  /// In en, this message translates to:
  /// **'That Google account has no email we can use. Sign up with email instead.'**
  String get errGoogleNoEmail;

  /// S2.4 — ERR_AUTH_001
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed, please try again.'**
  String get errGoogleFailed;

  /// No description provided for @toastAccountLinked.
  ///
  /// In en, this message translates to:
  /// **'Your Google account was linked to your existing email.'**
  String get toastAccountLinked;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @fieldFullNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Full name (optional)'**
  String get fieldFullNameOptional;

  /// No description provided for @fieldOtp.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get fieldOtp;

  /// No description provided for @fieldHouseholdName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get fieldHouseholdName;

  /// No description provided for @fieldInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get fieldInviteCode;

  /// No description provided for @fieldDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Your display name'**
  String get fieldDisplayName;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get errInvalidEmail;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get errPasswordTooShort;

  /// No description provided for @errPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get errPasswordRequired;

  /// No description provided for @errFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get errFullNameRequired;

  /// No description provided for @errHouseholdNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a family name'**
  String get errHouseholdNameRequired;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get registerTitle;

  /// No description provided for @registerCta.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerCta;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get registerHaveAccount;

  /// S3.4 / S9.4 — ERR_AUTH_003, inline under the email field
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get errEmailTaken;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String otpSubtitle(String email);

  /// No description provided for @otpVerifyCta.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerifyCta;

  /// No description provided for @otpResendCta.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResendCta;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String otpResendIn(int seconds);

  /// S4.3 — ERR_AUTH_OTP_INVALID
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired'**
  String get errOtpInvalid;

  /// S4.4 — ERR_AUTH_OTP_LIMIT, static wait notice with no countdown
  ///
  /// In en, this message translates to:
  /// **'You\'ve requested too many codes. Please wait before trying again.'**
  String get errOtpLimit;

  /// No description provided for @toastOtpSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent'**
  String get toastOtpSent;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginCta;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Create one'**
  String get loginNoAccount;

  /// S5.3 — ERR_AUTH_004. Never distinguish unknown email from wrong password.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect'**
  String get errBadCredentials;

  /// No description provided for @errLoginLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s.'**
  String errLoginLocked(int seconds);

  /// S6.2
  ///
  /// In en, this message translates to:
  /// **'Set up your family'**
  String get householdSetupTitle;

  /// No description provided for @householdSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Kitchen works around a shared family pantry. Create one or join an existing family.'**
  String get householdSetupSubtitle;

  /// No description provided for @householdCreateCta.
  ///
  /// In en, this message translates to:
  /// **'Create a new family'**
  String get householdCreateCta;

  /// No description provided for @householdJoinCta.
  ///
  /// In en, this message translates to:
  /// **'Join with an invite code'**
  String get householdJoinCta;

  /// No description provided for @createHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a family'**
  String get createHouseholdTitle;

  /// No description provided for @createHouseholdCta.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createHouseholdCta;

  /// S7.4
  ///
  /// In en, this message translates to:
  /// **'Family created'**
  String get createHouseholdDoneTitle;

  /// No description provided for @createHouseholdDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share this code so your family can join.'**
  String get createHouseholdDoneSubtitle;

  /// S7.3 — ERR_HH_003
  ///
  /// In en, this message translates to:
  /// **'You already belong to a family. Taking you there…'**
  String get errHouseholdRace;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCopyCta.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get inviteCopyCta;

  /// No description provided for @toastInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied'**
  String get toastInviteCopied;

  /// No description provided for @inviteExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String inviteExpiresAt(DateTime date);

  /// No description provided for @inviteContinueCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get inviteContinueCta;

  /// S8.1
  ///
  /// In en, this message translates to:
  /// **'Scan invite QR'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the invite QR code'**
  String get scanHint;

  /// S8.2
  ///
  /// In en, this message translates to:
  /// **'Smart Kitchen needs camera access to scan the invite QR code.'**
  String get scanPermissionDenied;

  /// No description provided for @scanEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get scanEnterManually;

  /// No description provided for @scanRetry.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanRetry;

  /// S8.3
  ///
  /// In en, this message translates to:
  /// **'Enter invite code'**
  String get inviteCodeTitle;

  /// No description provided for @inviteCodeCta.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get inviteCodeCta;

  /// No description provided for @errInviteCodeFormat.
  ///
  /// In en, this message translates to:
  /// **'Invite codes are 8 letters or digits'**
  String get errInviteCodeFormat;

  /// S8.5
  ///
  /// In en, this message translates to:
  /// **'Join this family?'**
  String get previewTitle;

  /// No description provided for @previewOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner: {name}'**
  String previewOwner(String name);

  /// No description provided for @previewMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String previewMembers(int count);

  /// No description provided for @previewJoinCta.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get previewJoinCta;

  /// S8.6 — ERR_HH_002
  ///
  /// In en, this message translates to:
  /// **'This invite code is invalid or has expired'**
  String get errInviteInvalid;

  /// No description provided for @inviteTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try another code'**
  String get inviteTryAnother;

  /// S8.7 — client-side block, no BE call
  ///
  /// In en, this message translates to:
  /// **'You already belong to another family.'**
  String get errAlreadyInHousehold;

  /// S8.9 — ERR_HH_005 / ERR_AUTH_INVITE_INVALID
  ///
  /// In en, this message translates to:
  /// **'Someone just used this invite code'**
  String get errInviteRace;

  /// No description provided for @toastJoined.
  ///
  /// In en, this message translates to:
  /// **'You\'ve joined the family'**
  String get toastJoined;

  /// S9.1 — non-blocking banner for GUEST sessions
  ///
  /// In en, this message translates to:
  /// **'Add an email so you don\'t lose this account'**
  String get upgradeBannerText;

  /// No description provided for @upgradeBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Set up email'**
  String get upgradeBannerCta;

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get upgradeTitle;

  /// No description provided for @upgradeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an email and password so you can sign back in on any device.'**
  String get upgradeSubtitle;

  /// No description provided for @upgradeCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get upgradeCta;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
