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

  /// Title of the temporary sign-in placeholder replaced by fe-onboarding (#28)
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get devLoginTitle;

  /// No description provided for @devLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The real sign-in flow (Google / OTP / QR join) ships with fe-onboarding.'**
  String get devLoginSubtitle;

  /// No description provided for @devLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Continue as demo user'**
  String get devLoginCta;

  /// No description provided for @devLoginBanner.
  ///
  /// In en, this message translates to:
  /// **'App shell demo — no backend call is made'**
  String get devLoginBanner;

  /// No description provided for @authLandingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your kitchen together'**
  String get authLandingSubtitle;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleSignIn;

  /// No description provided for @emailSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get emailSignIn;

  /// No description provided for @emailRegister.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get emailRegister;

  /// No description provided for @scanJoinQr.
  ///
  /// In en, this message translates to:
  /// **'Scan a household QR code'**
  String get scanJoinQr;

  /// No description provided for @googleAccountLinked.
  ///
  /// In en, this message translates to:
  /// **'Your Google account is linked'**
  String get googleAccountLinked;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @authRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in'**
  String get authRateLimited;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'No account? Create one'**
  String get noAccountRegister;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start cooking together'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordHint;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccountLogin;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to'**
  String get otpSentTo;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpCode;

  /// No description provided for @otpExpires.
  ///
  /// In en, this message translates to:
  /// **'Code expires in'**
  String get otpExpires;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendOtp;

  /// No description provided for @upgradeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get upgradeProfileTitle;

  /// No description provided for @upgradeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an email and password to keep your account'**
  String get upgradeProfileSubtitle;

  /// No description provided for @fullNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Full name (optional)'**
  String get fullNameOptional;

  /// No description provided for @continueToOtp.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueToOtp;

  /// No description provided for @householdSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your household'**
  String get householdSetupTitle;

  /// No description provided for @householdSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a household or join one with an invite'**
  String get householdSetupSubtitle;

  /// No description provided for @createHousehold.
  ///
  /// In en, this message translates to:
  /// **'Create household'**
  String get createHousehold;

  /// No description provided for @joinHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get joinHousehold;

  /// No description provided for @householdNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a household name'**
  String get householdNameRequired;

  /// No description provided for @householdNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Household name is too long'**
  String get householdNameTooLong;

  /// No description provided for @householdCreated.
  ///
  /// In en, this message translates to:
  /// **'Household created'**
  String get householdCreated;

  /// No description provided for @inviteQrSemantics.
  ///
  /// In en, this message translates to:
  /// **'Household invitation QR code'**
  String get inviteQrSemantics;

  /// No description provided for @inviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get inviteMembers;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @createHouseholdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give your household a name'**
  String get createHouseholdSubtitle;

  /// No description provided for @householdName.
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get householdName;

  /// No description provided for @joinHouseholdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan an invite or enter its code'**
  String get joinHouseholdSubtitle;

  /// No description provided for @alreadyInHousehold.
  ///
  /// In en, this message translates to:
  /// **'You already belong to a household'**
  String get alreadyInHousehold;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan QR codes'**
  String get cameraPermissionDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @enterCodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get enterCodeManually;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable'**
  String get cameraUnavailable;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @previewInvite.
  ///
  /// In en, this message translates to:
  /// **'Preview invite'**
  String get previewInvite;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @householdOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get householdOwner;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get memberCount;

  /// No description provided for @inviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Invite expires'**
  String get inviteExpires;

  /// No description provided for @displayNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get displayNameOptional;

  /// No description provided for @confirmJoin.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get confirmJoin;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get networkError;

  /// No description provided for @googleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not configured for this app'**
  String get googleUnavailable;

  /// No description provided for @googleEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'A Google email address is required'**
  String get googleEmailRequired;

  /// No description provided for @googleTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in could not be verified'**
  String get googleTokenInvalid;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get otpInvalid;

  /// No description provided for @otpResendLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many code requests. Try again later'**
  String get otpResendLimit;

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invitation is invalid or expired'**
  String get inviteInvalid;

  /// No description provided for @inviteRace.
  ///
  /// In en, this message translates to:
  /// **'This invitation is no longer available'**
  String get inviteRace;

  /// No description provided for @genericRetryError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again'**
  String get genericRetryError;

  /// No description provided for @guestProfileBanner.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to keep access to your household'**
  String get guestProfileBanner;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfile;
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
