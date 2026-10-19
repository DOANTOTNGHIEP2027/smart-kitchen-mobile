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

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreeting;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do today?'**
  String get homeQuickActions;

  /// No description provided for @homeStartCooking.
  ///
  /// In en, this message translates to:
  /// **'Start cooking'**
  String get homeStartCooking;

  /// No description provided for @homeStartCookingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a dish in your plan to start cooking'**
  String get homeStartCookingSubtitle;

  /// No description provided for @homeInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Food inventory'**
  String get homeInventoryTitle;

  /// No description provided for @homeInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep track of ingredients in your kitchen'**
  String get homeInventorySubtitle;

  /// No description provided for @homeMealPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal plan'**
  String get homeMealPlanTitle;

  /// No description provided for @homeMealPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan and vote on meals with your household'**
  String get homeMealPlanSubtitle;

  /// No description provided for @homeRecommendedMeals.
  ///
  /// In en, this message translates to:
  /// **'Recommended meals'**
  String get homeRecommendedMeals;

  /// No description provided for @homeRecipeAction.
  ///
  /// In en, this message translates to:
  /// **'View cooking steps'**
  String get homeRecipeAction;

  /// No description provided for @homeRecipeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe details'**
  String get homeRecipeDetailTitle;

  /// No description provided for @homeRecipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get homeRecipeIngredients;

  /// No description provided for @homeRecipeGuide.
  ///
  /// In en, this message translates to:
  /// **'Recipe source'**
  String get homeRecipeGuide;

  /// No description provided for @homeRecipeCook.
  ///
  /// In en, this message translates to:
  /// **'Cook this meal'**
  String get homeRecipeCook;

  /// No description provided for @homeRecipeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String homeRecipeMinutes(int minutes);

  /// No description provided for @homeRecipeCalories.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String homeRecipeCalories(int calories);

  /// No description provided for @authEmailExample.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailExample;

  /// No description provided for @authFullNameExample.
  ///
  /// In en, this message translates to:
  /// **'Alex Johnson'**
  String get authFullNameExample;

  /// No description provided for @householdNameExample.
  ///
  /// In en, this message translates to:
  /// **'The Johnson household'**
  String get householdNameExample;

  /// No description provided for @inviteCodeExample.
  ///
  /// In en, this message translates to:
  /// **'ABC12345'**
  String get inviteCodeExample;

  /// No description provided for @joinDisplayNameExample.
  ///
  /// In en, this message translates to:
  /// **'Household member'**
  String get joinDisplayNameExample;

  /// No description provided for @mealPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly meal plan'**
  String get mealPlanTitle;

  /// No description provided for @mealPlanNoHousehold.
  ///
  /// In en, this message translates to:
  /// **'You do not belong to a household yet.'**
  String get mealPlanNoHousehold;

  /// No description provided for @mealPlanLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the meal plan.'**
  String get mealPlanLoadFailed;

  /// No description provided for @mealPlanWeekRange.
  ///
  /// In en, this message translates to:
  /// **'Week {startDay}/{startMonth} – {endDay}/{endMonth}'**
  String mealPlanWeekRange(
      int startDay, int startMonth, int endDay, int endMonth);

  /// No description provided for @mealPlanDaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule for {day}/{month}'**
  String mealPlanDaySchedule(int day, int month);

  /// No description provided for @mealPlanDateShort.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String mealPlanDateShort(int day, int month);

  /// No description provided for @mealPlanWeekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mealPlanWeekdayMonday;

  /// No description provided for @mealPlanWeekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get mealPlanWeekdayTuesday;

  /// No description provided for @mealPlanWeekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get mealPlanWeekdayWednesday;

  /// No description provided for @mealPlanWeekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get mealPlanWeekdayThursday;

  /// No description provided for @mealPlanWeekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get mealPlanWeekdayFriday;

  /// No description provided for @mealPlanWeekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get mealPlanWeekdaySaturday;

  /// No description provided for @mealPlanWeekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get mealPlanWeekdaySunday;

  /// No description provided for @mealPlanBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealPlanBreakfast;

  /// No description provided for @mealPlanLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealPlanLunch;

  /// No description provided for @mealPlanDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealPlanDinner;

  /// No description provided for @mealPlanOpenVotes.
  ///
  /// In en, this message translates to:
  /// **'{count} open vote sessions'**
  String mealPlanOpenVotes(int count);

  /// No description provided for @mealPlanTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a dish'**
  String get mealPlanTapToAdd;

  /// No description provided for @mealPlanSelectingDish.
  ///
  /// In en, this message translates to:
  /// **'Choosing a dish'**
  String get mealPlanSelectingDish;

  /// No description provided for @mealPlanDishUnselected.
  ///
  /// In en, this message translates to:
  /// **'No dish selected'**
  String get mealPlanDishUnselected;

  /// No description provided for @mealPlanAddDish.
  ///
  /// In en, this message translates to:
  /// **'Add dish'**
  String get mealPlanAddDish;

  /// No description provided for @mealPlanAddDishFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to add the dish. Please try again.'**
  String get mealPlanAddDishFailed;

  /// No description provided for @mealPlanOpenSuggestionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open meal suggestions. Please try again.'**
  String get mealPlanOpenSuggestionsFailed;

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

  /// No description provided for @authForgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordLink;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send a verification code.'**
  String get authForgotPasswordHint;

  /// No description provided for @authSendResetOtp.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendResetOtp;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPasswordSubmit;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Please sign in.'**
  String get authResetSuccess;

  /// No description provided for @authOtpCooldown.
  ///
  /// In en, this message translates to:
  /// **'Please wait before requesting another code.'**
  String get authOtpCooldown;

  /// No description provided for @authTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authTooManyAttempts;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

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

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileTitle;

  /// No description provided for @profileEmailMissing.
  ///
  /// In en, this message translates to:
  /// **'Email not set'**
  String get profileEmailMissing;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileEditBlocked.
  ///
  /// In en, this message translates to:
  /// **'This feature is being completed. It will be available soon.'**
  String get profileEditBlocked;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileSavedToast;

  /// No description provided for @healthProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Health profile'**
  String get healthProfileTitle;

  /// No description provided for @healthProfileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not set up yet — fill in to get personalized suggestions.'**
  String get healthProfileEmpty;

  /// No description provided for @healthProfileTargetCalories.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie goal'**
  String get healthProfileTargetCalories;

  /// No description provided for @healthProfileDietType.
  ///
  /// In en, this message translates to:
  /// **'Diet type'**
  String get healthProfileDietType;

  /// No description provided for @healthProfileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get healthProfileHeight;

  /// No description provided for @healthProfileWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get healthProfileWeight;

  /// No description provided for @healthProfileAllergensSection.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get healthProfileAllergensSection;

  /// No description provided for @healthProfileAllergensEmpty.
  ///
  /// In en, this message translates to:
  /// **'No allergens selected.'**
  String get healthProfileAllergensEmpty;

  /// No description provided for @healthProfileAllergensEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit allergens'**
  String get healthProfileAllergensEdit;

  /// No description provided for @healthSave.
  ///
  /// In en, this message translates to:
  /// **'Save health profile'**
  String get healthSave;

  /// No description provided for @healthSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Health profile saved'**
  String get healthSavedToast;

  /// No description provided for @healthSavedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Health profile saved'**
  String get healthSavedDialogTitle;

  /// No description provided for @healthSavedDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Your health profile has been saved successfully.'**
  String get healthSavedDialogMessage;

  /// No description provided for @healthSavedDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get healthSavedDialogConfirm;

  /// No description provided for @cookingAbandonTitle.
  ///
  /// In en, this message translates to:
  /// **'Abandon cooking session?'**
  String get cookingAbandonTitle;

  /// No description provided for @cookingAbandonMessage.
  ///
  /// In en, this message translates to:
  /// **'Ingredients will not be deducted from inventory.'**
  String get cookingAbandonMessage;

  /// No description provided for @cookingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue cooking'**
  String get cookingContinue;

  /// No description provided for @cookingAbandonAction.
  ///
  /// In en, this message translates to:
  /// **'Abandon'**
  String get cookingAbandonAction;

  /// No description provided for @cookingLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the cooking session.'**
  String get cookingLoadFailed;

  /// No description provided for @cookingRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get cookingRetry;

  /// No description provided for @cookingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cookingBack;

  /// No description provided for @cookingAbandonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Abandon cooking session'**
  String get cookingAbandonTooltip;

  /// No description provided for @cookingStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step}'**
  String cookingStepLabel(int step);

  /// No description provided for @cookingStepUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Step instructions are unavailable.'**
  String get cookingStepUnavailable;

  /// No description provided for @cookingReturnToCurrentStep.
  ///
  /// In en, this message translates to:
  /// **'Return to current step'**
  String get cookingReturnToCurrentStep;

  /// No description provided for @cookingPreviousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get cookingPreviousStep;

  /// No description provided for @cookingComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get cookingComplete;

  /// No description provided for @cookingNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get cookingNextStep;

  /// No description provided for @cookingCompletedWithShortfall.
  ///
  /// In en, this message translates to:
  /// **'Completed — some ingredients were short'**
  String get cookingCompletedWithShortfall;

  /// No description provided for @cookingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed!'**
  String get cookingCompleted;

  /// No description provided for @cookingCompletedShortfallDetail.
  ///
  /// In en, this message translates to:
  /// **'Inventory was deducted until stock ran out (FIFO). Used ingredients are recorded by deducted quantity.'**
  String get cookingCompletedShortfallDetail;

  /// No description provided for @cookingDeductionResult.
  ///
  /// In en, this message translates to:
  /// **'Inventory deduction result:'**
  String get cookingDeductionResult;

  /// No description provided for @cookingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cookingDone;

  /// No description provided for @cookingAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Cooking session abandoned.'**
  String get cookingAbandoned;

  /// No description provided for @cookingAbandonedDetail.
  ///
  /// In en, this message translates to:
  /// **'Inventory was not changed.'**
  String get cookingAbandonedDetail;

  /// No description provided for @cookingHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get cookingHome;

  /// No description provided for @cookingNoIngredientsToDeduct.
  ///
  /// In en, this message translates to:
  /// **'There are no ingredients to deduct (empty recipe).'**
  String get cookingNoIngredientsToDeduct;

  /// No description provided for @cookingDeductionRequired.
  ///
  /// In en, this message translates to:
  /// **'Required: {quantity} {unit}'**
  String cookingDeductionRequired(Object quantity, Object unit);

  /// No description provided for @cookingDeducted.
  ///
  /// In en, this message translates to:
  /// **'Deducted: {quantity} {unit}'**
  String cookingDeducted(Object quantity, Object unit);

  /// No description provided for @cookingShortfall.
  ///
  /// In en, this message translates to:
  /// **'Shortfall: {quantity} {unit}'**
  String cookingShortfall(Object quantity, Object unit);

  /// No description provided for @cookingDeductionLots.
  ///
  /// In en, this message translates to:
  /// **'From {count} stock batches'**
  String cookingDeductionLots(int count);

  /// No description provided for @cookingInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Insufficient'**
  String get cookingInsufficient;

  /// No description provided for @cookingStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {viewedStep}/{totalSteps}'**
  String cookingStepProgress(int viewedStep, int totalSteps);

  /// No description provided for @cookingStepReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing (current: step {currentStep})'**
  String cookingStepReviewing(int currentStep);

  /// No description provided for @cookingSuggestedDuration.
  ///
  /// In en, this message translates to:
  /// **'Suggested duration: {minutes} minutes'**
  String cookingSuggestedDuration(int minutes);

  /// No description provided for @cookingPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get cookingPause;

  /// No description provided for @cookingResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get cookingResume;

  /// No description provided for @cookingReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get cookingReset;

  /// No description provided for @allergensTitle.
  ///
  /// In en, this message translates to:
  /// **'My allergens'**
  String get allergensTitle;

  /// No description provided for @allergensCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Allergen catalog unavailable.'**
  String get allergensCatalogEmpty;

  /// No description provided for @allergensSelectNone.
  ///
  /// In en, this message translates to:
  /// **'None known'**
  String get allergensSelectNone;

  /// No description provided for @allergensSave.
  ///
  /// In en, this message translates to:
  /// **'Save allergens'**
  String get allergensSave;

  /// No description provided for @allergensSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Allergens updated'**
  String get allergensSavedToast;

  /// No description provided for @dietTypeNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get dietTypeNone;

  /// No description provided for @dietTypeKeto.
  ///
  /// In en, this message translates to:
  /// **'Keto'**
  String get dietTypeKeto;

  /// No description provided for @dietTypeVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietTypeVegetarian;

  /// No description provided for @dietTypeVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietTypeVegan;

  /// No description provided for @dietTypePescatarian.
  ///
  /// In en, this message translates to:
  /// **'Pescatarian'**
  String get dietTypePescatarian;

  /// No description provided for @dietTypeGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten free'**
  String get dietTypeGlutenFree;

  /// No description provided for @dietTypeDiabetic.
  ///
  /// In en, this message translates to:
  /// **'Diabetic'**
  String get dietTypeDiabetic;

  /// No description provided for @familyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyTitle;

  /// No description provided for @familyRosterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No other members yet.'**
  String get familyRosterEmpty;

  /// No description provided for @familyCreateInvite.
  ///
  /// In en, this message translates to:
  /// **'Create invite'**
  String get familyCreateInvite;

  /// No description provided for @familyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from household'**
  String get familyRemove;

  /// No description provided for @familyRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this member from the household?'**
  String get familyRemoveConfirm;

  /// No description provided for @familyRemoveCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get familyRemoveCancel;

  /// No description provided for @familyYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get familyYou;

  /// No description provided for @familyInviteRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You already have 3 active invites.'**
  String get familyInviteRateLimited;

  /// No description provided for @memberDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberDetailTitle;

  /// No description provided for @memberDetailDietType.
  ///
  /// In en, this message translates to:
  /// **'Diet type'**
  String get memberDetailDietType;

  /// No description provided for @memberDetailAllergensSection.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get memberDetailAllergensSection;

  /// No description provided for @memberDetailAllergensEmpty.
  ///
  /// In en, this message translates to:
  /// **'No allergens registered.'**
  String get memberDetailAllergensEmpty;

  /// No description provided for @staleDataBanner.
  ///
  /// In en, this message translates to:
  /// **'Data may be out of date — showing the latest saved copy.'**
  String get staleDataBanner;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @profileLogoutAll.
  ///
  /// In en, this message translates to:
  /// **'Log out of all devices'**
  String get profileLogoutAll;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out of this device?'**
  String get profileLogoutConfirm;

  /// No description provided for @profileLogoutAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out of all devices? You will need to sign in again everywhere.'**
  String get profileLogoutAllConfirm;

  /// No description provided for @profileLogoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileLogoutCancel;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Food inventory'**
  String get inventoryTitle;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @syncIdempotencyKeyReused.
  ///
  /// In en, this message translates to:
  /// **'An add action was already sent with different content — please check the list again.'**
  String get syncIdempotencyKeyReused;

  /// No description provided for @inventorySyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync — showing saved data.'**
  String get inventorySyncFailed;

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name…'**
  String get inventorySearchHint;

  /// No description provided for @inventoryNoHousehold.
  ///
  /// In en, this message translates to:
  /// **'You are not in a household yet — create or join one first.'**
  String get inventoryNoHousehold;

  /// No description provided for @inventoryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching items found.'**
  String get inventoryNoResults;

  /// No description provided for @inventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet.'**
  String get inventoryEmpty;

  /// No description provided for @inventoryAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get inventoryAddItem;

  /// No description provided for @inventoryChooseUnit.
  ///
  /// In en, this message translates to:
  /// **'Choose unit'**
  String get inventoryChooseUnit;

  /// No description provided for @inventoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get inventoryDeleteTitle;

  /// No description provided for @inventoryDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason to record in inventory history.'**
  String get inventoryDeleteMessage;

  /// No description provided for @inventoryDeleteCooked.
  ///
  /// In en, this message translates to:
  /// **'Used up'**
  String get inventoryDeleteCooked;

  /// No description provided for @inventoryDeleteWaste.
  ///
  /// In en, this message translates to:
  /// **'Expired, spoiled, or discarded'**
  String get inventoryDeleteWaste;

  /// No description provided for @inventoryDeleteCorrected.
  ///
  /// In en, this message translates to:
  /// **'Deleted by mistake, correct data'**
  String get inventoryDeleteCorrected;

  /// No description provided for @inventoryEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get inventoryEditItem;

  /// No description provided for @inventoryItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name *'**
  String get inventoryItemName;

  /// No description provided for @inventoryItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tomato'**
  String get inventoryItemNameHint;

  /// No description provided for @inventoryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity *'**
  String get inventoryQuantity;

  /// No description provided for @inventoryUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get inventoryUnit;

  /// No description provided for @inventoryLowStockOptional.
  ///
  /// In en, this message translates to:
  /// **'Low-stock threshold (optional)'**
  String get inventoryLowStockOptional;

  /// No description provided for @inventoryExpiryOptional.
  ///
  /// In en, this message translates to:
  /// **'Expiry date (optional)'**
  String get inventoryExpiryOptional;

  /// No description provided for @inventoryChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date…'**
  String get inventoryChooseDate;

  /// No description provided for @inventoryNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get inventoryNoteOptional;

  /// No description provided for @inventoryAddToInventory.
  ///
  /// In en, this message translates to:
  /// **'Add to inventory'**
  String get inventoryAddToInventory;

  /// No description provided for @inventoryDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get inventoryDeleteItem;

  /// No description provided for @inventoryUnitRequired.
  ///
  /// In en, this message translates to:
  /// **'Please choose a unit'**
  String get inventoryUnitRequired;

  /// No description provided for @inventoryLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get inventoryLowStock;

  /// No description provided for @inventoryExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get inventoryExpiringSoon;

  /// No description provided for @inventoryPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get inventoryPendingSync;

  /// No description provided for @inventoryConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get inventoryConflict;

  /// No description provided for @inventoryConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'This data was changed by another member. Refreshing…'**
  String get inventoryConflictMessage;

  /// No description provided for @inventoryYours.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get inventoryYours;

  /// No description provided for @inventoryServer.
  ///
  /// In en, this message translates to:
  /// **'On server'**
  String get inventoryServer;

  /// No description provided for @inventoryUseServer.
  ///
  /// In en, this message translates to:
  /// **'Use server version'**
  String get inventoryUseServer;

  /// No description provided for @inventoryKeepMine.
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get inventoryKeepMine;

  /// No description provided for @inventoryName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventoryName;

  /// No description provided for @inventoryQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inventoryQuantityLabel;

  /// No description provided for @inventoryCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryCategory;

  /// No description provided for @inventoryExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get inventoryExpiry;

  /// No description provided for @inventoryVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get inventoryVersion;

  /// No description provided for @mealplanAddDish.
  ///
  /// In en, this message translates to:
  /// **'Add dish'**
  String get mealplanAddDish;

  /// No description provided for @mealplanConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get mealplanConfirmed;

  /// No description provided for @mealplanAddSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Add suggestion'**
  String get mealplanAddSuggestion;

  /// No description provided for @mealplanWaitingForVote.
  ///
  /// In en, this message translates to:
  /// **'Waiting for votes'**
  String get mealplanWaitingForVote;

  /// No description provided for @mealplanVoting.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get mealplanVoting;

  /// No description provided for @mealplanSelectedDish.
  ///
  /// In en, this message translates to:
  /// **'Selected dish'**
  String get mealplanSelectedDish;

  /// No description provided for @mealplanAiSuggestion.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion'**
  String get mealplanAiSuggestion;

  /// No description provided for @mealplanStartCooking.
  ///
  /// In en, this message translates to:
  /// **'Start cooking'**
  String get mealplanStartCooking;

  /// No description provided for @mealplanDeleteDishTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this dish?'**
  String get mealplanDeleteDishTitle;

  /// No description provided for @mealplanDeleteDishMessage.
  ///
  /// In en, this message translates to:
  /// **'If there is an active vote, it will be cancelled.'**
  String get mealplanDeleteDishMessage;

  /// No description provided for @mealplanDeleteDish.
  ///
  /// In en, this message translates to:
  /// **'Delete dish'**
  String get mealplanDeleteDish;

  /// No description provided for @mealplanNeedsMore.
  ///
  /// In en, this message translates to:
  /// **'Need to add:'**
  String get mealplanNeedsMore;

  /// No description provided for @mealplanMainIngredientPrefix.
  ///
  /// In en, this message translates to:
  /// **'[Main] '**
  String get mealplanMainIngredientPrefix;

  /// No description provided for @mealplanNoReason.
  ///
  /// In en, this message translates to:
  /// **'No reason provided'**
  String get mealplanNoReason;

  /// No description provided for @mealplanAiGenerated.
  ///
  /// In en, this message translates to:
  /// **'AI generated'**
  String get mealplanAiGenerated;

  /// No description provided for @mealplanContainsAllergens.
  ///
  /// In en, this message translates to:
  /// **'This dish contains: {tags}'**
  String mealplanContainsAllergens(Object tags);

  /// No description provided for @mealplanAllergenUnverified.
  ///
  /// In en, this message translates to:
  /// **'Allergens for this dish have not been verified'**
  String get mealplanAllergenUnverified;

  /// No description provided for @mealplanSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal suggestions'**
  String get mealplanSuggestionsTitle;

  /// No description provided for @mealplanSuggestionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The session exists, but suggestions could not be reloaded.'**
  String get mealplanSuggestionsUnavailable;

  /// No description provided for @mealplanSuggestionsExhausted.
  ///
  /// In en, this message translates to:
  /// **'You have viewed all suggestions. Wait for votes or try re-rolling.'**
  String get mealplanSuggestionsExhausted;

  /// No description provided for @mealplanAddShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get mealplanAddShoppingList;

  /// No description provided for @mealplanShoppingListUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Shopping lists will be available in a future release.'**
  String get mealplanShoppingListUnavailable;

  /// No description provided for @mealplanChooseDish.
  ///
  /// In en, this message translates to:
  /// **'Choose dish'**
  String get mealplanChooseDish;

  /// No description provided for @mealplanUnableToChoose.
  ///
  /// In en, this message translates to:
  /// **'Could not choose dish'**
  String get mealplanUnableToChoose;

  /// No description provided for @mealplanActionRolledBack.
  ///
  /// In en, this message translates to:
  /// **'The action was rolled back.'**
  String get mealplanActionRolledBack;

  /// No description provided for @mealplanVoteSession.
  ///
  /// In en, this message translates to:
  /// **'Vote session'**
  String get mealplanVoteSession;

  /// No description provided for @mealplanClosesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes at: {time}'**
  String mealplanClosesAt(Object time);

  /// No description provided for @mealplanVoteSuggestionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The session exists, but suggestions could not be reloaded. Tap Refresh or wait for another member to vote.'**
  String get mealplanVoteSuggestionsUnavailable;

  /// No description provided for @mealplanNoVotes.
  ///
  /// In en, this message translates to:
  /// **'No votes yet.'**
  String get mealplanNoVotes;

  /// No description provided for @mealplanVoted.
  ///
  /// In en, this message translates to:
  /// **'Voted'**
  String get mealplanVoted;

  /// No description provided for @mealplanVote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get mealplanVote;

  /// No description provided for @mealplanCloseVoting.
  ///
  /// In en, this message translates to:
  /// **'Close voting'**
  String get mealplanCloseVoting;

  /// No description provided for @recipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipesTitle;

  /// No description provided for @recipesAll.
  ///
  /// In en, this message translates to:
  /// **'All recipes'**
  String get recipesAll;

  /// No description provided for @recipesFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get recipesFavorites;

  /// No description provided for @recipesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search recipes…'**
  String get recipesSearch;

  /// No description provided for @recipesFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get recipesFilters;

  /// No description provided for @recipesFilterDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet type'**
  String get recipesFilterDiet;

  /// No description provided for @recipesFilterDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get recipesFilterDifficulty;

  /// No description provided for @recipesFilterPrepTime.
  ///
  /// In en, this message translates to:
  /// **'Preparation time'**
  String get recipesFilterPrepTime;

  /// No description provided for @recipesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching recipes found.'**
  String get recipesNoResults;

  /// No description provided for @recipesNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'You have not saved any favorite recipes yet.'**
  String get recipesNoFavorites;

  /// No description provided for @recipesLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get recipesLoadMore;

  /// No description provided for @recipesListChanged.
  ///
  /// In en, this message translates to:
  /// **'Your favorites list has changed.'**
  String get recipesListChanged;

  /// No description provided for @recipesReload.
  ///
  /// In en, this message translates to:
  /// **'Reload list'**
  String get recipesReload;

  /// No description provided for @recipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipeIngredients;

  /// No description provided for @recipeSteps.
  ///
  /// In en, this message translates to:
  /// **'Cooking steps'**
  String get recipeSteps;

  /// No description provided for @recipeNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition per serving'**
  String get recipeNutrition;

  /// No description provided for @recipePrepTime.
  ///
  /// In en, this message translates to:
  /// **'Prep: {minutes} min'**
  String recipePrepTime(int minutes);

  /// No description provided for @recipeCookTime.
  ///
  /// In en, this message translates to:
  /// **'Cook: {minutes} min'**
  String recipeCookTime(int minutes);

  /// No description provided for @recipeServes.
  ///
  /// In en, this message translates to:
  /// **'Serves {count}'**
  String recipeServes(int count);

  /// No description provided for @recipeDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get recipeDifficulty;

  /// No description provided for @recipeDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get recipeDifficultyEasy;

  /// No description provided for @recipeDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get recipeDifficultyMedium;

  /// No description provided for @recipeDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get recipeDifficultyHard;

  /// No description provided for @recipeStartCooking.
  ///
  /// In en, this message translates to:
  /// **'Start cooking'**
  String get recipeStartCooking;

  /// No description provided for @recipeNoSteps.
  ///
  /// In en, this message translates to:
  /// **'Cooking steps are not available for this recipe.'**
  String get recipeNoSteps;

  /// No description provided for @recipeYourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get recipeYourRating;

  /// No description provided for @recipeClearRating.
  ///
  /// In en, this message translates to:
  /// **'Clear rating'**
  String get recipeClearRating;

  /// No description provided for @recipeHouseholdFavorites.
  ///
  /// In en, this message translates to:
  /// **'Saved by {count} household members'**
  String recipeHouseholdFavorites(int count);

  /// No description provided for @inventoryHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory history'**
  String get inventoryHistoryTitle;

  /// No description provided for @inventoryHistoryOpen.
  ///
  /// In en, this message translates to:
  /// **'View change history'**
  String get inventoryHistoryOpen;

  /// No description provided for @inventoryHistoryCurrentQuantity.
  ///
  /// In en, this message translates to:
  /// **'Currently {quantity} {unit}'**
  String inventoryHistoryCurrentQuantity(Object quantity, Object unit);

  /// No description provided for @inventoryHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load inventory history.'**
  String get inventoryHistoryLoadFailed;

  /// No description provided for @inventoryHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No changes have been recorded for this item yet.'**
  String get inventoryHistoryEmpty;

  /// No description provided for @inventoryHistoryLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get inventoryHistoryLoadMore;

  /// No description provided for @inventoryHistoryRemaining.
  ///
  /// In en, this message translates to:
  /// **'Left {quantity}'**
  String inventoryHistoryRemaining(Object quantity);

  /// No description provided for @inventoryHistoryReasonBought.
  ///
  /// In en, this message translates to:
  /// **'Added to inventory'**
  String get inventoryHistoryReasonBought;

  /// No description provided for @inventoryHistoryReasonCooked.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get inventoryHistoryReasonCooked;

  /// No description provided for @inventoryHistoryReasonExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get inventoryHistoryReasonExpired;

  /// No description provided for @inventoryHistoryReasonWaste.
  ///
  /// In en, this message translates to:
  /// **'Discarded'**
  String get inventoryHistoryReasonWaste;

  /// No description provided for @inventoryHistoryReasonCorrected.
  ///
  /// In en, this message translates to:
  /// **'Data correction'**
  String get inventoryHistoryReasonCorrected;

  /// No description provided for @inventoryWasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Why was this food discarded?'**
  String get inventoryWasteTitle;

  /// No description provided for @inventoryWasteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one reason to help your household reduce waste.'**
  String get inventoryWasteSubtitle;

  /// No description provided for @inventoryWasteOverbought.
  ///
  /// In en, this message translates to:
  /// **'Bought too much'**
  String get inventoryWasteOverbought;

  /// No description provided for @inventoryWasteForgotten.
  ///
  /// In en, this message translates to:
  /// **'Forgotten until expired'**
  String get inventoryWasteForgotten;

  /// No description provided for @inventoryWasteSpoiledEarly.
  ///
  /// In en, this message translates to:
  /// **'Spoiled before expiry'**
  String get inventoryWasteSpoiledEarly;

  /// No description provided for @inventoryWasteUntagged.
  ///
  /// In en, this message translates to:
  /// **'Cause not recorded'**
  String get inventoryWasteUntagged;

  /// No description provided for @notificationInventoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Inventory updated'**
  String get notificationInventoryUpdated;

  /// No description provided for @notificationInventoryAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This item was already marked as used'**
  String get notificationInventoryAlreadyUsed;

  /// No description provided for @notificationInventoryAlreadyDiscarded.
  ///
  /// In en, this message translates to:
  /// **'This item was already discarded'**
  String get notificationInventoryAlreadyDiscarded;

  /// No description provided for @notificationInventoryAlreadyProcessed.
  ///
  /// In en, this message translates to:
  /// **'This item was already processed'**
  String get notificationInventoryAlreadyProcessed;

  /// No description provided for @notificationInventoryGone.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer in inventory'**
  String get notificationInventoryGone;

  /// No description provided for @notificationInventoryReadonly.
  ///
  /// In en, this message translates to:
  /// **'Your account has view-only access'**
  String get notificationInventoryReadonly;

  /// No description provided for @notificationNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection — try again'**
  String get notificationNoNetwork;

  /// No description provided for @notificationActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The notification action could not be completed'**
  String get notificationActionFailed;

  /// No description provided for @notificationActionCookToday.
  ///
  /// In en, this message translates to:
  /// **'Cook today'**
  String get notificationActionCookToday;

  /// No description provided for @notificationActionMarkUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get notificationActionMarkUsed;

  /// No description provided for @notificationActionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get notificationActionDiscard;

  /// No description provided for @inventoryOcrScanAction.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt or items'**
  String get inventoryOcrScanAction;

  /// No description provided for @inventoryOcrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan items into inventory'**
  String get inventoryOcrScanTitle;

  /// No description provided for @inventoryOcrModeItem.
  ///
  /// In en, this message translates to:
  /// **'Single item'**
  String get inventoryOcrModeItem;

  /// No description provided for @inventoryOcrModeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt / fridge'**
  String get inventoryOcrModeReceipt;

  /// No description provided for @inventoryOcrFrameHint.
  ///
  /// In en, this message translates to:
  /// **'Place the item or receipt clearly inside the frame'**
  String get inventoryOcrFrameHint;

  /// No description provided for @inventoryOcrItemHint.
  ///
  /// In en, this message translates to:
  /// **'Photograph one item clearly for the most accurate result'**
  String get inventoryOcrItemHint;

  /// No description provided for @inventoryOcrReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the full receipt or fridge contents visible and well lit'**
  String get inventoryOcrReceiptHint;

  /// No description provided for @inventoryOcrTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get inventoryOcrTakePhoto;

  /// No description provided for @inventoryOcrChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get inventoryOcrChooseGallery;

  /// No description provided for @inventoryOcrChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another image'**
  String get inventoryOcrChooseAnother;

  /// No description provided for @inventoryOcrAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image…'**
  String get inventoryOcrAnalyzing;

  /// No description provided for @inventoryOcrPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera or photo access has not been granted. Open Settings to allow access.'**
  String get inventoryOcrPermissionDenied;

  /// No description provided for @inventoryOcrImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The image is still over 2 MB after compression. Please choose another image.'**
  String get inventoryOcrImageTooLarge;

  /// No description provided for @inventoryOcrImageInvalid.
  ///
  /// In en, this message translates to:
  /// **'This image could not be read. Please choose a valid JPEG or PNG image.'**
  String get inventoryOcrImageInvalid;

  /// No description provided for @inventoryOcrAiTimeout.
  ///
  /// In en, this message translates to:
  /// **'The AI took too long to respond. Your image is still available to retry.'**
  String get inventoryOcrAiTimeout;

  /// No description provided for @inventoryOcrAiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The AI service is temporarily unavailable. Your image is still available to retry.'**
  String get inventoryOcrAiUnavailable;

  /// No description provided for @inventoryOcrAiRateLimit.
  ///
  /// In en, this message translates to:
  /// **'The AI service is busy. Please wait a moment and retry.'**
  String get inventoryOcrAiRateLimit;

  /// No description provided for @inventoryOcrContentFiltered.
  ///
  /// In en, this message translates to:
  /// **'This image cannot be analyzed. Please choose another image.'**
  String get inventoryOcrContentFiltered;

  /// No description provided for @inventoryOcrInvalidOutput.
  ///
  /// In en, this message translates to:
  /// **'The AI could not produce a usable result from this image. Please choose another image.'**
  String get inventoryOcrInvalidOutput;

  /// No description provided for @inventoryOcrScanInProgress.
  ///
  /// In en, this message translates to:
  /// **'The previous image is still being processed. Please wait a few seconds.'**
  String get inventoryOcrScanInProgress;

  /// No description provided for @inventoryOcrNoHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join or create a household before scanning inventory.'**
  String get inventoryOcrNoHousehold;

  /// No description provided for @inventoryOcrResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan results ({count})'**
  String inventoryOcrResultTitle(int count);

  /// No description provided for @inventoryOcrConfirmAll.
  ///
  /// In en, this message translates to:
  /// **'Confirm all'**
  String get inventoryOcrConfirmAll;

  /// No description provided for @inventoryOcrEmpty.
  ///
  /// In en, this message translates to:
  /// **'AI did not recognize any items in this image'**
  String get inventoryOcrEmpty;

  /// No description provided for @inventoryOcrRetake.
  ///
  /// In en, this message translates to:
  /// **'Take another photo'**
  String get inventoryOcrRetake;

  /// No description provided for @inventoryOcrNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get inventoryOcrNeedsReview;

  /// No description provided for @inventoryOcrDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already in inventory'**
  String get inventoryOcrDuplicate;

  /// No description provided for @inventoryOcrExpiryEstimate.
  ///
  /// In en, this message translates to:
  /// **'Expires {date} · AI estimate'**
  String inventoryOcrExpiryEstimate(Object date);

  /// No description provided for @inventoryOcrRawValue.
  ///
  /// In en, this message translates to:
  /// **'Detected from image: {quantity} {unit}'**
  String inventoryOcrRawValue(Object quantity, Object unit);

  /// No description provided for @inventoryOcrQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get inventoryOcrQuantityHint;

  /// No description provided for @inventoryOcrQuantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get inventoryOcrQuantityInvalid;

  /// No description provided for @inventoryOcrCompleteFields.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity and unit before saving'**
  String get inventoryOcrCompleteFields;

  /// No description provided for @inventoryOcrSaveItem.
  ///
  /// In en, this message translates to:
  /// **'Save this item'**
  String get inventoryOcrSaveItem;

  /// No description provided for @inventoryOcrSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get inventoryOcrSaved;

  /// No description provided for @inventoryOcrSavingProgress.
  ///
  /// In en, this message translates to:
  /// **'Saving {saved}/{total}…'**
  String inventoryOcrSavingProgress(int saved, int total);

  /// No description provided for @inventoryOcrPartialFailure.
  ///
  /// In en, this message translates to:
  /// **'{count} items could not be saved — retry or skip them below'**
  String inventoryOcrPartialFailure(int count);

  /// No description provided for @mealLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Log'**
  String get mealLogTitle;

  /// No description provided for @mealLogToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get mealLogToday;

  /// No description provided for @mealLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No meal logged today yet'**
  String get mealLogEmpty;

  /// No description provided for @mealLogLogMeal.
  ///
  /// In en, this message translates to:
  /// **'Log a meal'**
  String get mealLogLogMeal;

  /// No description provided for @mealLogSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get mealLogSaving;

  /// No description provided for @mealLogSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get mealLogSaveFailed;

  /// No description provided for @mealLogRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mealLogRetry;

  /// No description provided for @mealLogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mealLogDelete;

  /// No description provided for @mealLogNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get mealLogNeedsReview;

  /// No description provided for @mealLogNoEstimate.
  ///
  /// In en, this message translates to:
  /// **'No estimate'**
  String get mealLogNoEstimate;

  /// No description provided for @mealLogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get mealLogConfirm;

  /// No description provided for @mealLogConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get mealLogConfirmed;

  /// No description provided for @mealLogCalories.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String mealLogCalories(double calories);

  /// No description provided for @mealLogGoalRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} kcal left today'**
  String mealLogGoalRemaining(int remaining);

  /// No description provided for @mealLogSetCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Set calorie goal'**
  String get mealLogSetCalorieGoal;

  /// No description provided for @mealLogMealType.
  ///
  /// In en, this message translates to:
  /// **'Meal type'**
  String get mealLogMealType;

  /// No description provided for @mealLogBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealLogBreakfast;

  /// No description provided for @mealLogLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLogLunch;

  /// No description provided for @mealLogDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealLogDinner;

  /// No description provided for @mealLogSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealLogSnack;

  /// No description provided for @mealLogDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What did you eat? (optional)'**
  String get mealLogDescriptionHint;

  /// No description provided for @mealLogAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get mealLogAddPhoto;

  /// No description provided for @mealLogPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Photo is still too large after compression — choose another'**
  String get mealLogPhotoTooLarge;

  /// No description provided for @mealLogChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another photo'**
  String get mealLogChooseAnother;

  /// No description provided for @mealLogCameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera/library permission was denied. Enable it in settings to add a photo.'**
  String get mealLogCameraPermissionDenied;

  /// No description provided for @mealLogPhotoInvalid.
  ///
  /// In en, this message translates to:
  /// **'Could not read the photo. Choose a different one.'**
  String get mealLogPhotoInvalid;

  /// No description provided for @mealLogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm calories'**
  String get mealLogConfirmTitle;

  /// No description provided for @mealLogConfirmAsIs.
  ///
  /// In en, this message translates to:
  /// **'Accept as estimated'**
  String get mealLogConfirmAsIs;

  /// No description provided for @mealLogEnterCalories.
  ///
  /// In en, this message translates to:
  /// **'Enter calories'**
  String get mealLogEnterCalories;

  /// No description provided for @mealLogCaloriesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a value between 0 and 10000'**
  String get mealLogCaloriesInvalid;

  /// No description provided for @mealLogCaloriesRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter calories first'**
  String get mealLogCaloriesRequired;

  /// No description provided for @insightsTitleCalorie.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get insightsTitleCalorie;

  /// No description provided for @insightsTitleMacro.
  ///
  /// In en, this message translates to:
  /// **'Macro'**
  String get insightsTitleMacro;

  /// No description provided for @insightsTitleAdherence.
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get insightsTitleAdherence;

  /// No description provided for @insightsMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month {month}/{year}'**
  String insightsMonthLabel(Object month, Object year);

  /// No description provided for @insightsEmptyDiary.
  ///
  /// In en, this message translates to:
  /// **'No meals logged in this month yet'**
  String get insightsEmptyDiary;

  /// No description provided for @insightsEmptyAdherence.
  ///
  /// In en, this message translates to:
  /// **'The household has no adherence data yet'**
  String get insightsEmptyAdherence;

  /// No description provided for @insightsSetCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Set calorie goal'**
  String get insightsSetCalorieGoal;

  /// No description provided for @insightsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get insightsRetry;

  /// No description provided for @insightsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get insightsLast7Days;

  /// No description provided for @insightsAvgCalories.
  ///
  /// In en, this message translates to:
  /// **'Avg {calories} kcal/day'**
  String insightsAvgCalories(Object calories);

  /// No description provided for @insightsLoggedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} meals logged'**
  String insightsLoggedCount(Object count);

  /// No description provided for @insightsStreakText.
  ///
  /// In en, this message translates to:
  /// **'{current} weeks in a row · Best {best}'**
  String insightsStreakText(Object best, Object current);

  /// No description provided for @insightsNoWeekData.
  ///
  /// In en, this message translates to:
  /// **'No data for this week'**
  String get insightsNoWeekData;

  /// No description provided for @insightsAdherenceStart.
  ///
  /// In en, this message translates to:
  /// **'{percent}% — from {day}/{month}'**
  String insightsAdherenceStart(Object day, Object month, Object percent);

  /// No description provided for @insightsKcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String insightsKcalPerDay(Object calories);

  /// No description provided for @insightsHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Nutrition trends'**
  String get insightsHistoryTooltip;

  /// No description provided for @insightsCalorieTooltip.
  ///
  /// In en, this message translates to:
  /// **'{day}/{month} — {calories} kcal'**
  String insightsCalorieTooltip(Object calories, Object day, Object month);

  /// No description provided for @recapTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Recap'**
  String get recapTitle;

  /// No description provided for @recapNoHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join a household to view Weekly Recap'**
  String get recapNoHousehold;

  /// No description provided for @recapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recap yet for this week — the first recap will arrive on Monday morning of next week.'**
  String get recapEmpty;

  /// No description provided for @recapError.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get recapError;

  /// No description provided for @recapHeroFallback.
  ///
  /// In en, this message translates to:
  /// **'No personalized insight for you this week yet. Keep logging meals to get a more detailed insight next week!'**
  String get recapHeroFallback;

  /// No description provided for @recapStreak.
  ///
  /// In en, this message translates to:
  /// **'{current} weeks'**
  String recapStreak(Object current);

  /// No description provided for @recapStreakBest.
  ///
  /// In en, this message translates to:
  /// **'Best {best}'**
  String recapStreakBest(Object best);

  /// No description provided for @recapMealsLogged.
  ///
  /// In en, this message translates to:
  /// **'{count} meals logged'**
  String recapMealsLogged(Object count);

  /// No description provided for @recapAvgCalories.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal/day'**
  String recapAvgCalories(Object calories);

  /// No description provided for @recapAdherenceCaption.
  ///
  /// In en, this message translates to:
  /// **'Meal plan adherence — different from personal calorie compliance below'**
  String get recapAdherenceCaption;

  /// No description provided for @recapEmptyInsights.
  ///
  /// In en, this message translates to:
  /// **'No personalized insight yet for this week.'**
  String get recapEmptyInsights;

  /// No description provided for @recapNutrientGap.
  ///
  /// In en, this message translates to:
  /// **'Watch out: {nutrient}'**
  String recapNutrientGap(Object nutrient);

  /// No description provided for @recapShare.
  ///
  /// In en, this message translates to:
  /// **'My household\'s Weekly Recap on Smart Kitchen!'**
  String get recapShare;

  /// No description provided for @recapShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the image, please try again later'**
  String get recapShareFailed;

  /// No description provided for @recapShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share recap'**
  String get recapShareTooltip;

  /// No description provided for @recapStreakError.
  ///
  /// In en, this message translates to:
  /// **'Could not load streak'**
  String get recapStreakError;

  /// No description provided for @recapStreakRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry streak'**
  String get recapStreakRetry;

  /// No description provided for @planningSlotConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal times'**
  String get planningSlotConfigTitle;

  /// No description provided for @planningSlotConfigTooltip.
  ///
  /// In en, this message translates to:
  /// **'Configure meal times'**
  String get planningSlotConfigTooltip;

  /// No description provided for @planningSlotEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get planningSlotEveryDay;

  /// No description provided for @planningSlotByDay.
  ///
  /// In en, this message translates to:
  /// **'Extra meals for one day'**
  String get planningSlotByDay;

  /// No description provided for @planningSlotByDayHint.
  ///
  /// In en, this message translates to:
  /// **'Meals here are ADDED on top of \"Every day\", they don\'t replace it.'**
  String get planningSlotByDayHint;

  /// No description provided for @planningSlotDefaultBanner.
  ///
  /// In en, this message translates to:
  /// **'Your household uses the 3 default meals (07:00 / 12:00 / 18:00). Edit below to customise.'**
  String get planningSlotDefaultBanner;

  /// No description provided for @planningSlotNotRetroactive.
  ///
  /// In en, this message translates to:
  /// **'Changes only apply to meals created from now on — existing weekly plans are not affected.'**
  String get planningSlotNotRetroactive;

  /// No description provided for @planningSlotAdd.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get planningSlotAdd;

  /// No description provided for @planningSlotEmptyDay.
  ///
  /// In en, this message translates to:
  /// **'No extra meals for this day.'**
  String get planningSlotEmptyDay;

  /// No description provided for @planningSlotSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get planningSlotSave;

  /// No description provided for @planningSlotSaved.
  ///
  /// In en, this message translates to:
  /// **'Meal times saved'**
  String get planningSlotSaved;

  /// No description provided for @planningSlotSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save meal times.'**
  String get planningSlotSaveFailed;

  /// No description provided for @planningSlotErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one meal.'**
  String get planningSlotErrorEmpty;

  /// No description provided for @planningSlotErrorTooMany.
  ///
  /// In en, this message translates to:
  /// **'At most 10 meals per household.'**
  String get planningSlotErrorTooMany;

  /// No description provided for @planningSlotErrorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Two meals have the same type in one day group.'**
  String get planningSlotErrorDuplicate;

  /// No description provided for @planningSlotErrorBlankLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal name must not be empty.'**
  String get planningSlotErrorBlankLabel;

  /// No description provided for @planningSlotFormAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add meal'**
  String get planningSlotFormAddTitle;

  /// No description provided for @planningSlotFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit meal'**
  String get planningSlotFormEditTitle;

  /// No description provided for @planningSlotFormType.
  ///
  /// In en, this message translates to:
  /// **'Meal type'**
  String get planningSlotFormType;

  /// No description provided for @planningSlotFormLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal name'**
  String get planningSlotFormLabel;

  /// No description provided for @planningSlotFormTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get planningSlotFormTime;

  /// No description provided for @planningSlotTypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get planningSlotTypeBreakfast;

  /// No description provided for @planningSlotTypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get planningSlotTypeLunch;

  /// No description provided for @planningSlotTypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get planningSlotTypeDinner;

  /// No description provided for @planningSlotTypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get planningSlotTypeSnack;

  /// No description provided for @planningSlotTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get planningSlotTypeCustom;

  /// No description provided for @planningSlotEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get planningSlotEdit;

  /// No description provided for @planningConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get planningConfirm;

  /// No description provided for @planningGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest diners'**
  String get planningGuestTitle;

  /// No description provided for @planningGuestTooltip.
  ///
  /// In en, this message translates to:
  /// **'Guest diners this week'**
  String get planningGuestTooltip;

  /// No description provided for @planningGuestScopeBanner.
  ///
  /// In en, this message translates to:
  /// **'Temporary guests — they apply to this week\'s meal plan only and are not saved to the family profile. For people who eat with you regularly, use Dependants in the family profile.'**
  String get planningGuestScopeBanner;

  /// No description provided for @planningGuestEmpty.
  ///
  /// In en, this message translates to:
  /// **'No guests for this week yet.'**
  String get planningGuestEmpty;

  /// No description provided for @planningGuestAdd.
  ///
  /// In en, this message translates to:
  /// **'Add guest'**
  String get planningGuestAdd;

  /// No description provided for @planningGuestUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed guest'**
  String get planningGuestUnnamed;

  /// No description provided for @planningGuestNoAllergen.
  ///
  /// In en, this message translates to:
  /// **'No allergies'**
  String get planningGuestNoAllergen;

  /// No description provided for @planningGuestNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Guest name (optional)'**
  String get planningGuestNameOptional;

  /// No description provided for @planningGuestAllergens.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get planningGuestAllergens;

  /// No description provided for @planningGuestCatalogFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the allergen list.'**
  String get planningGuestCatalogFailed;

  /// No description provided for @planningGuestEditAllergens.
  ///
  /// In en, this message translates to:
  /// **'Edit allergies'**
  String get planningGuestEditAllergens;

  /// No description provided for @planningGuestDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove guest'**
  String get planningGuestDelete;

  /// No description provided for @planningGuestDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this guest from this week\'s plan?'**
  String get planningGuestDeleteConfirm;

  /// No description provided for @planningGuestRemovedHint.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}. Dishes blocked earlier are NOT unblocked automatically — generate new suggestions if you want to try again.'**
  String planningGuestRemovedHint(String name);

  /// No description provided for @planningGuestUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated. AI suggestions for this week may have changed.'**
  String get planningGuestUpdated;

  /// No description provided for @planningGuestSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get planningGuestSave;

  /// No description provided for @planningCandidateTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified AI suggestions'**
  String get planningCandidateTitle;

  /// No description provided for @planningCandidateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Verified AI suggestions'**
  String get planningCandidateTooltip;

  /// No description provided for @planningCandidateExplainer.
  ///
  /// In en, this message translates to:
  /// **'Everything below is a RAW suggestion from AI. The system then filters by allergies (mandatory) and ranks by diet, expiring food and variety — only the dish marked ⭐ is the FINAL pick confirmed by the algorithm.'**
  String get planningCandidateExplainer;

  /// No description provided for @planningCandidateEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions for this dish yet.'**
  String get planningCandidateEmpty;

  /// No description provided for @planningCandidateEmptyWeek.
  ///
  /// In en, this message translates to:
  /// **'No AI suggestions this week yet. Open a dish and pick suggestions to generate them.'**
  String get planningCandidateEmptyWeek;

  /// No description provided for @planningCandidateGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate AI suggestions'**
  String get planningCandidateGenerate;

  /// No description provided for @planningCandidateGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate suggestions.'**
  String get planningCandidateGenerateFailed;

  /// No description provided for @planningCandidateAllBlocked.
  ///
  /// In en, this message translates to:
  /// **'All suggestions are blocked by allergies. Try removing some guests from the constraints, or pick a dish manually.'**
  String get planningCandidateAllBlocked;

  /// No description provided for @planningCandidateAiLabel.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion'**
  String get planningCandidateAiLabel;

  /// No description provided for @planningCandidateFinalPick.
  ///
  /// In en, this message translates to:
  /// **'Final pick — confirmed by the algorithm'**
  String get planningCandidateFinalPick;

  /// No description provided for @planningCandidatePassed.
  ///
  /// In en, this message translates to:
  /// **'Passed safety checks — not the top pick'**
  String get planningCandidatePassed;

  /// No description provided for @planningCandidateBlocked.
  ///
  /// In en, this message translates to:
  /// **'Excluded — {reason}'**
  String planningCandidateBlocked(String reason);

  /// No description provided for @planningCandidateUnverified.
  ///
  /// In en, this message translates to:
  /// **'Allergies NOT verified — this suggestion was never checked by the safety filter'**
  String get planningCandidateUnverified;

  /// No description provided for @planningCandidateBlockedUnknown.
  ///
  /// In en, this message translates to:
  /// **'unverified allergy'**
  String get planningCandidateBlockedUnknown;

  /// No description provided for @planningCandidateScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String planningCandidateScore(String score);

  /// No description provided for @planningCandidateBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Score breakdown'**
  String get planningCandidateBreakdown;

  /// No description provided for @planningCandidateWeight.
  ///
  /// In en, this message translates to:
  /// **'weight {weight}'**
  String planningCandidateWeight(String weight);

  /// No description provided for @planningCandidateNoBreakdown.
  ///
  /// In en, this message translates to:
  /// **'The engine returned no score breakdown.'**
  String get planningCandidateNoBreakdown;

  /// No description provided for @planningCandidateSession.
  ///
  /// In en, this message translates to:
  /// **'Suggestion session · {time}'**
  String planningCandidateSession(String time);

  /// No description provided for @planningFeatureInventoryCoverage.
  ///
  /// In en, this message translates to:
  /// **'Ingredients on hand'**
  String get planningFeatureInventoryCoverage;

  /// No description provided for @planningFeatureExpiryUrgency.
  ///
  /// In en, this message translates to:
  /// **'Expiring food'**
  String get planningFeatureExpiryUrgency;

  /// No description provided for @planningFeatureRepetitionPenalty.
  ///
  /// In en, this message translates to:
  /// **'Recent repetition'**
  String get planningFeatureRepetitionPenalty;

  /// No description provided for @planningFeatureNutritionFit.
  ///
  /// In en, this message translates to:
  /// **'Nutrition fit'**
  String get planningFeatureNutritionFit;

  /// No description provided for @planningFeatureDietMatch.
  ///
  /// In en, this message translates to:
  /// **'Diet match'**
  String get planningFeatureDietMatch;

  /// No description provided for @planningFeatureEffortFit.
  ///
  /// In en, this message translates to:
  /// **'Effort fit'**
  String get planningFeatureEffortFit;

  /// No description provided for @planningFeaturePreference.
  ///
  /// In en, this message translates to:
  /// **'Preference'**
  String get planningFeaturePreference;

  /// No description provided for @planningFeaturePrior.
  ///
  /// In en, this message translates to:
  /// **'Base priority'**
  String get planningFeaturePrior;

  /// No description provided for @planningFeatureNutrientBalance.
  ///
  /// In en, this message translates to:
  /// **'Nutrient balance'**
  String get planningFeatureNutrientBalance;

  /// No description provided for @planningFeatureRiskPenalty.
  ///
  /// In en, this message translates to:
  /// **'Nutrient risk'**
  String get planningFeatureRiskPenalty;

  /// No description provided for @planningFeatureConstraintMatch.
  ///
  /// In en, this message translates to:
  /// **'Constraint match'**
  String get planningFeatureConstraintMatch;

  /// No description provided for @planningFeatureGraphPath.
  ///
  /// In en, this message translates to:
  /// **'Knowledge-graph evidence'**
  String get planningFeatureGraphPath;

  /// No description provided for @planningRepetitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeated dishes'**
  String get planningRepetitionTitle;

  /// No description provided for @planningRepetitionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Repeated dishes'**
  String get planningRepetitionTooltip;

  /// No description provided for @planningRepetitionWindow.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String planningRepetitionWindow(int days);

  /// No description provided for @planningRepetitionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No dish repeated in the last {days} days 🎉'**
  String planningRepetitionEmpty(int days);

  /// No description provided for @planningRepetitionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String planningRepetitionCount(int count);

  /// No description provided for @tierFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tierFree;

  /// No description provided for @tierPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get tierPremium;

  /// No description provided for @tierUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get tierUnknown;

  /// No description provided for @tierPlanCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current plan: {tier}'**
  String tierPlanCurrent(String tier);

  /// No description provided for @tierSeatUsage.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit} view-only seats'**
  String tierSeatUsage(int used, int limit);

  /// No description provided for @tierChangePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade / Downgrade'**
  String get tierChangePlan;

  /// No description provided for @tierOwnerOnlyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Only the household owner can change the plan'**
  String get tierOwnerOnlyTooltip;

  /// No description provided for @tierViewerOnlyTooltip.
  ///
  /// In en, this message translates to:
  /// **'You are in view-only mode — only the household owner can change the plan'**
  String get tierViewerOnlyTooltip;

  /// No description provided for @tierRemoteViewerBanner.
  ///
  /// In en, this message translates to:
  /// **'You are in view-only mode (Remote Viewer) in this household — you cannot invite, remove or change roles of members. Contact the owner if you need different permissions.'**
  String get tierRemoteViewerBanner;

  /// No description provided for @tierRoleViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get tierRoleViewOnly;

  /// No description provided for @tierChangeRoleAction.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get tierChangeRoleAction;

  /// No description provided for @tierChangeRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change role — {name}'**
  String tierChangeRoleTitle(String name);

  /// No description provided for @tierChangeRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member — view, vote and edit the inventory as usual'**
  String get tierChangeRoleMember;

  /// No description provided for @tierChangeRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'View only (Remote Viewer) — no voting, no inventory edits, no member management'**
  String get tierChangeRoleViewer;

  /// No description provided for @tierChangeRoleSoftHint.
  ///
  /// In en, this message translates to:
  /// **'The {tier} plan already uses {used}/{limit} view-only seats. You can still try — if the limit is exceeded, you will be offered an upgrade.'**
  String tierChangeRoleSoftHint(String tier, int used, int limit);

  /// No description provided for @tierConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get tierConfirm;

  /// No description provided for @tierChangeRoleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role changed'**
  String get tierChangeRoleSuccess;

  /// No description provided for @tierUpsellTitle.
  ///
  /// In en, this message translates to:
  /// **'View-only seats are full'**
  String get tierUpsellTitle;

  /// No description provided for @tierUpsellBody.
  ///
  /// In en, this message translates to:
  /// **'Your current plan allows {limit} view-only seat(s). Upgrade to Premium for up to 5.'**
  String tierUpsellBody(int limit);

  /// No description provided for @tierUpsellBodyMaxed.
  ///
  /// In en, this message translates to:
  /// **'Your plan already uses all {limit} view-only seats. Change someone back to Member to free a seat.'**
  String tierUpsellBodyMaxed(int limit);

  /// No description provided for @tierUpgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get tierUpgradeToPremium;

  /// No description provided for @tierDowngradeToFree.
  ///
  /// In en, this message translates to:
  /// **'Downgrade to Free'**
  String get tierDowngradeToFree;

  /// No description provided for @tierClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tierClose;

  /// No description provided for @tierUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Household plan'**
  String get tierUpgradeTitle;

  /// No description provided for @tierDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is NOT a real purchase. It is a demo/QA switch to try the tier-gate flow. In a real release this will be replaced by an authenticated payment flow.'**
  String get tierDisclaimer;

  /// No description provided for @tierOwnerOnlyBlocked.
  ///
  /// In en, this message translates to:
  /// **'Only the household owner (OWNER) can change the household plan.'**
  String get tierOwnerOnlyBlocked;

  /// No description provided for @tierCompareFree.
  ///
  /// In en, this message translates to:
  /// **'Free — 1 view-only seat'**
  String get tierCompareFree;

  /// No description provided for @tierComparePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium — 5 view-only seats'**
  String get tierComparePremium;

  /// No description provided for @tierCompareSpend.
  ///
  /// In en, this message translates to:
  /// **'Spending by category + 8-week trend: Free ✗ / Premium ✓'**
  String get tierCompareSpend;

  /// No description provided for @tierDowngradeWarning.
  ///
  /// In en, this message translates to:
  /// **'The household has {used} view-only members, above the Free limit (1). Existing ones are NOT affected right away, but you cannot add new ones until you reduce the number or upgrade again.'**
  String tierDowngradeWarning(int used);

  /// No description provided for @tierRosterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the member list — the view-only seat warning for downgrading may be missing.'**
  String get tierRosterFailed;

  /// No description provided for @tierUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'Could not determine the current plan — please try reloading.'**
  String get tierUnknownBody;

  /// No description provided for @tierRetryLoad.
  ///
  /// In en, this message translates to:
  /// **'Try reloading'**
  String get tierRetryLoad;

  /// No description provided for @tierRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Still unknown — please sign in again.'**
  String get tierRetryFailed;

  /// No description provided for @tierConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to {tier}?'**
  String tierConfirmTitle(String tier);

  /// No description provided for @tierUpdated.
  ///
  /// In en, this message translates to:
  /// **'Household plan updated to {tier}'**
  String tierUpdated(String tier);

  /// No description provided for @tierMemberViewerInfo.
  ///
  /// In en, this message translates to:
  /// **'Role: View only (Remote Viewer) — no voting, no inventory edits, no member management.'**
  String get tierMemberViewerInfo;

  /// No description provided for @budgetLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading budget…'**
  String get budgetLoading;

  /// No description provided for @budgetLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the budget'**
  String get budgetLoadFailed;

  /// No description provided for @budgetNotSet.
  ///
  /// In en, this message translates to:
  /// **'No budget set for this household yet'**
  String get budgetNotSet;

  /// No description provided for @budgetCurrentWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly budget: {amount}'**
  String budgetCurrentWeekly(String amount);

  /// No description provided for @budgetCurrentMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget: {amount}'**
  String budgetCurrentMonthly(String amount);

  /// No description provided for @budgetSet.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get budgetSet;

  /// No description provided for @budgetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get budgetEdit;

  /// No description provided for @budgetOwnerOnlyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Only the household owner can set the budget'**
  String get budgetOwnerOnlyTooltip;

  /// No description provided for @budgetLoadingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Loading the current budget…'**
  String get budgetLoadingTooltip;

  /// No description provided for @budgetUpsell.
  ///
  /// In en, this message translates to:
  /// **'See spending by category & 8-week trend with Premium'**
  String get budgetUpsell;

  /// No description provided for @budgetSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Household budget'**
  String get budgetSheetTitle;

  /// No description provided for @budgetPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get budgetPeriodWeek;

  /// No description provided for @budgetPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get budgetPeriodMonth;

  /// No description provided for @budgetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get budgetAmountLabel;

  /// No description provided for @budgetAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0 and at most 999,999,999,999'**
  String get budgetAmountInvalid;

  /// No description provided for @budgetNotRetroactive.
  ///
  /// In en, this message translates to:
  /// **'The budget applies to UPCOMING weeks. Recaps of weeks already summarised keep the budget at that time.'**
  String get budgetNotRetroactive;

  /// No description provided for @budgetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get budgetSave;

  /// No description provided for @budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget updated'**
  String get budgetUpdated;

  /// No description provided for @recapWasteSpendTitle.
  ///
  /// In en, this message translates to:
  /// **'Waste & spending'**
  String get recapWasteSpendTitle;

  /// No description provided for @recapWeekRange.
  ///
  /// In en, this message translates to:
  /// **'Monday {start} – Sunday {end}'**
  String recapWeekRange(String start, String end);

  /// No description provided for @recapWasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Waste this week'**
  String get recapWasteTitle;

  /// No description provided for @recapWasteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item thrown away} other{{count} items thrown away}}'**
  String recapWasteCount(int count);

  /// No description provided for @recapWasteNone.
  ///
  /// In en, this message translates to:
  /// **'🎉 Your household threw nothing away this week. Keep it up!'**
  String get recapWasteNone;

  /// No description provided for @recapWasteOverbought.
  ///
  /// In en, this message translates to:
  /// **'Overbought'**
  String get recapWasteOverbought;

  /// No description provided for @recapWasteForgotten.
  ///
  /// In en, this message translates to:
  /// **'Forgotten in the fridge'**
  String get recapWasteForgotten;

  /// No description provided for @recapWasteSpoiledEarly.
  ///
  /// In en, this message translates to:
  /// **'Spoiled early'**
  String get recapWasteSpoiledEarly;

  /// No description provided for @recapWasteUntagged.
  ///
  /// In en, this message translates to:
  /// **'No reason given'**
  String get recapWasteUntagged;

  /// No description provided for @recapWasteOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get recapWasteOther;

  /// No description provided for @recapSpendTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending this week'**
  String get recapSpendTitle;

  /// No description provided for @recapSpendNone.
  ///
  /// In en, this message translates to:
  /// **'No item has a price entered this week'**
  String get recapSpendNone;

  /// No description provided for @recapSpendNoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the price when you tick an item done on the shopping list to see spending here.'**
  String get recapSpendNoneHint;

  /// No description provided for @recapSpendOfBudget.
  ///
  /// In en, this message translates to:
  /// **'{spent} / {budget}'**
  String recapSpendOfBudget(String spent, String budget);

  /// No description provided for @recapSpendPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the weekly budget'**
  String recapSpendPercent(int percent);

  /// No description provided for @recapSpendOver.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the weekly budget · Over by {amount}'**
  String recapSpendOver(int percent, String amount);

  /// No description provided for @recapSpendCoverage.
  ///
  /// In en, this message translates to:
  /// **'{priced}/{completed} items have a price'**
  String recapSpendCoverage(int priced, int completed);

  /// No description provided for @recapSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get recapSetBudget;

  /// No description provided for @recapNoBudgetMember.
  ///
  /// In en, this message translates to:
  /// **'The owner has not set a budget for this household'**
  String get recapNoBudgetMember;

  /// No description provided for @recapBudgetConvertedMonthly.
  ///
  /// In en, this message translates to:
  /// **'The monthly budget ({amount}) has been converted to a weekly amount.'**
  String recapBudgetConvertedMonthly(String amount);

  /// No description provided for @recapBudgetConvertedOther.
  ///
  /// In en, this message translates to:
  /// **'Your budget ({amount}) has been converted to a weekly amount.'**
  String recapBudgetConvertedOther(String amount);

  /// No description provided for @recapSpendByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get recapSpendByCategory;

  /// No description provided for @recapSpendTrend.
  ///
  /// In en, this message translates to:
  /// **'8-week trend'**
  String get recapSpendTrend;

  /// No description provided for @recapUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get recapUncategorized;

  /// No description provided for @recapSpendCategoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No priced spending this week yet'**
  String get recapSpendCategoryEmpty;

  /// No description provided for @recapSpendUpsell.
  ///
  /// In en, this message translates to:
  /// **'See spending by category and the 8-week trend with Premium'**
  String get recapSpendUpsell;

  /// No description provided for @recapUpgradePremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get recapUpgradePremium;

  /// No description provided for @recapSpendDetailNeutral.
  ///
  /// In en, this message translates to:
  /// **'No detailed data for this week yet.'**
  String get recapSpendDetailNeutral;

  /// No description provided for @shoppingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty'**
  String get shoppingEmptyTitle;

  /// No description provided for @shoppingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add groceries you need, or plan this week\'s menu to build the list automatically.'**
  String get shoppingEmptyBody;

  /// No description provided for @shoppingAddNeeded.
  ///
  /// In en, this message translates to:
  /// **'Add something to buy'**
  String get shoppingAddNeeded;

  /// No description provided for @shoppingPendingCount.
  ///
  /// In en, this message translates to:
  /// **'To buy ({count})'**
  String shoppingPendingCount(int count);

  /// No description provided for @shoppingCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'Bought ({count})'**
  String shoppingCompletedCount(int count);

  /// No description provided for @shoppingFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String shoppingFilterAll(int count);

  /// No description provided for @shoppingAllBought.
  ///
  /// In en, this message translates to:
  /// **'Great! Everything has been bought.'**
  String get shoppingAllBought;

  /// No description provided for @shoppingNoneBought.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been marked as bought yet.'**
  String get shoppingNoneBought;

  /// No description provided for @shoppingAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get shoppingAddItem;

  /// No description provided for @shoppingProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping progress'**
  String get shoppingProgressTitle;

  /// No description provided for @shoppingProgressDetail.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} items done ({percent}%)'**
  String shoppingProgressDetail(int completed, int total, int percent);

  /// No description provided for @shoppingPendingBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} to buy'**
  String shoppingPendingBadge(int count);

  /// No description provided for @shoppingWeeklyMenuBadge.
  ///
  /// In en, this message translates to:
  /// **'Weekly menu'**
  String get shoppingWeeklyMenuBadge;

  /// No description provided for @shoppingAddSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add item to buy'**
  String get shoppingAddSheetTitle;

  /// No description provided for @shoppingNameHint.
  ///
  /// In en, this message translates to:
  /// **'Food or ingredient name...'**
  String get shoppingNameHint;

  /// No description provided for @shoppingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get shoppingNameLabel;

  /// No description provided for @shoppingQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get shoppingQuantityLabel;

  /// No description provided for @shoppingUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get shoppingUnitLabel;

  /// No description provided for @shoppingCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get shoppingCategoryLabel;

  /// No description provided for @shoppingAddToList.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get shoppingAddToList;

  /// No description provided for @dependentListTitle.
  ///
  /// In en, this message translates to:
  /// **'Dependents'**
  String get dependentListTitle;

  /// No description provided for @dependentAddProfile.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get dependentAddProfile;

  /// No description provided for @dependentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the dependents list.'**
  String get dependentLoadFailed;

  /// No description provided for @dependentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No dependents yet'**
  String get dependentEmptyTitle;

  /// No description provided for @dependentEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a profile for a young child or a dependent relative so the app can automatically handle allergies and suitable diets.'**
  String get dependentEmptyBody;

  /// No description provided for @dependentAllergenInfo.
  ///
  /// In en, this message translates to:
  /// **'The app automatically excludes allergenic ingredients when suggesting menus for dependents.'**
  String get dependentAllergenInfo;

  /// No description provided for @dependentDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Little member'**
  String get dependentDefaultName;

  /// No description provided for @dependentAgeAndBirth.
  ///
  /// In en, this message translates to:
  /// **'{age, plural, =1{1 year old} other{{age} years old}} · Born {date}'**
  String dependentAgeAndBirth(int age, String date);

  /// No description provided for @dependentAllergenChip.
  ///
  /// In en, this message translates to:
  /// **'Allergy: {name}'**
  String dependentAllergenChip(String name);

  /// No description provided for @dependentNoAllergens.
  ///
  /// In en, this message translates to:
  /// **'No allergies'**
  String get dependentNoAllergens;

  /// No description provided for @dependentProfileNav.
  ///
  /// In en, this message translates to:
  /// **'Dependent profiles'**
  String get dependentProfileNav;

  /// No description provided for @dependentFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Add dependent'**
  String get dependentFormTitle;

  /// No description provided for @dependentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the dependent\'s name'**
  String get dependentNameRequired;

  /// No description provided for @dependentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while saving the profile'**
  String get dependentSaveFailed;

  /// No description provided for @dependentBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get dependentBasicInfo;

  /// No description provided for @dependentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name or nickname *'**
  String get dependentNameLabel;

  /// No description provided for @dependentNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Baby An, Grandpa...'**
  String get dependentNameHint;

  /// No description provided for @dependentDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dependentDateOfBirth;

  /// No description provided for @dependentDietSection.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get dependentDietSection;

  /// No description provided for @dependentDietHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a special diet if this member has specific nutrition needs.'**
  String get dependentDietHint;

  /// No description provided for @dependentDietNone.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get dependentDietNone;

  /// No description provided for @dependentDietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Lacto-ovo vegetarian'**
  String get dependentDietVegetarian;

  /// No description provided for @dependentDietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dependentDietVegan;

  /// No description provided for @dependentDietPescatarian.
  ///
  /// In en, this message translates to:
  /// **'Pescatarian'**
  String get dependentDietPescatarian;

  /// No description provided for @dependentAllergenSection.
  ///
  /// In en, this message translates to:
  /// **'Food allergies'**
  String get dependentAllergenSection;

  /// No description provided for @dependentAllergenHint.
  ///
  /// In en, this message translates to:
  /// **'Tick the foods this member is allergic to so the app can warn you.'**
  String get dependentAllergenHint;

  /// No description provided for @dependentSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get dependentSave;

  /// No description provided for @inventoryStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total items'**
  String get inventoryStatTotal;

  /// No description provided for @inventoryStatExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get inventoryStatExpiring;

  /// No description provided for @inventoryStatLowStock.
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get inventoryStatLowStock;

  /// No description provided for @inventoryValidationNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name must not be empty'**
  String get inventoryValidationNameEmpty;

  /// No description provided for @inventoryValidationQuantityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Quantity must not be empty'**
  String get inventoryValidationQuantityEmpty;

  /// No description provided for @inventoryValidationQuantityNotNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a number'**
  String get inventoryValidationQuantityNotNumber;

  /// No description provided for @inventoryValidationQuantityNotPositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than 0'**
  String get inventoryValidationQuantityNotPositive;

  /// No description provided for @inventoryValidationQuantityNegative.
  ///
  /// In en, this message translates to:
  /// **'Quantity must not be negative'**
  String get inventoryValidationQuantityNegative;

  /// No description provided for @inventoryValidationQuantityNotWhole.
  ///
  /// In en, this message translates to:
  /// **'For \"piece\" units, it must be a whole number'**
  String get inventoryValidationQuantityNotWhole;

  /// No description provided for @mealPlanStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get mealPlanStatusConfirmed;

  /// No description provided for @mealPlanStatusVoting.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get mealPlanStatusVoting;

  /// No description provided for @mealPlanStatusSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get mealPlanStatusSuggested;

  /// No description provided for @mealPlanStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get mealPlanStatusEmpty;

  /// No description provided for @familyRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get familyRoleMember;

  /// No description provided for @tierUpdatedClaimStale.
  ///
  /// In en, this message translates to:
  /// **'Household plan updated to {tier}. Sign in again if the screen still shows the old plan.'**
  String tierUpdatedClaimStale(String tier);

  /// No description provided for @planningPlanNotReady.
  ///
  /// In en, this message translates to:
  /// **'The weekly plan is not loaded yet — please try again.'**
  String get planningPlanNotReady;

  /// No description provided for @sessionExpiredError.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpiredError;

  /// No description provided for @shoppingPriceQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much did you pay?'**
  String get shoppingPriceQuestion;

  /// No description provided for @shoppingPriceOptional.
  ///
  /// In en, this message translates to:
  /// **'You can skip this'**
  String get shoppingPriceOptional;

  /// No description provided for @shoppingPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get shoppingPriceLabel;

  /// No description provided for @shoppingPriceZeroHint.
  ///
  /// In en, this message translates to:
  /// **'0 ₫ means free. If you don\'t know the price, tap Skip.'**
  String get shoppingPriceZeroHint;

  /// No description provided for @shoppingPriceSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get shoppingPriceSkip;

  /// No description provided for @shoppingPriceSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get shoppingPriceSave;

  /// No description provided for @shoppingPriceNotSaved.
  ///
  /// In en, this message translates to:
  /// **'This item was just updated by someone else — the price you entered was not saved. Untick and tick again to re-enter it.'**
  String get shoppingPriceNotSaved;
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
