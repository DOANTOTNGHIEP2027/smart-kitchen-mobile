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
