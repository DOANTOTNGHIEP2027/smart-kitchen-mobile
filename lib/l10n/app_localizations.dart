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

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Hello, night owl'**
  String get homeGreetingNight;

  /// No description provided for @homeShoppingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your grocery shopping list'**
  String get homeShoppingSubtitle;

  /// No description provided for @homeMealLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track nutrition and calories'**
  String get homeMealLogSubtitle;

  /// No description provided for @inventoryCategoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get inventoryCategoryOptional;

  /// No description provided for @inventoryCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Spices, seafood, vegetables'**
  String get inventoryCategoryHint;

  /// No description provided for @inventoryCategoryVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get inventoryCategoryVegetables;

  /// No description provided for @inventoryCategorySeafood.
  ///
  /// In en, this message translates to:
  /// **'Seafood'**
  String get inventoryCategorySeafood;

  /// No description provided for @inventoryCategoryMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get inventoryCategoryMeat;

  /// No description provided for @inventoryCategorySpices.
  ///
  /// In en, this message translates to:
  /// **'Spices'**
  String get inventoryCategorySpices;

  /// No description provided for @inventoryCategoryFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get inventoryCategoryFruit;

  /// No description provided for @inventoryCategoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy and eggs'**
  String get inventoryCategoryDairy;

  /// No description provided for @inventoryCategoryDry.
  ///
  /// In en, this message translates to:
  /// **'Dry goods'**
  String get inventoryCategoryDry;

  /// No description provided for @inventoryCategoryDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get inventoryCategoryDrinks;

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

  /// No description provided for @homeUpcomingMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming meal'**
  String get homeUpcomingMealTitle;

  /// No description provided for @homeUpcomingToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeUpcomingToday;

  /// No description provided for @homeUpcomingTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeUpcomingTomorrow;

  /// No description provided for @homeUpcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming meal in your plan'**
  String get homeUpcomingEmpty;

  /// No description provided for @homeUpcomingOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan meals'**
  String get homeUpcomingOpenPlan;

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
  /// **'No allergen entries saved'**
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

  /// No description provided for @cookingShortfallTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough ingredients in stock'**
  String get cookingShortfallTitle;

  /// No description provided for @cookingShortfallMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been deducted from inventory yet. Restock and tap Complete again, or complete now — inventory will be deducted as far as it goes.'**
  String get cookingShortfallMessage;

  /// No description provided for @cookingShortfallLine.
  ///
  /// In en, this message translates to:
  /// **'Need {required} · Have {available} · Short {shortfall} {unit}'**
  String cookingShortfallLine(
      String required, String available, String shortfall, String unit);

  /// No description provided for @cookingShortfallNoDetail.
  ///
  /// In en, this message translates to:
  /// **'The list of missing ingredients is unavailable.'**
  String get cookingShortfallNoDetail;

  /// No description provided for @cookingShortfallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Complete anyway (deduct what is in stock)'**
  String get cookingShortfallConfirm;

  /// No description provided for @cookingShortfallBack.
  ///
  /// In en, this message translates to:
  /// **'Back to cooking'**
  String get cookingShortfallBack;

  /// No description provided for @cookingUnitGram.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get cookingUnitGram;

  /// No description provided for @cookingUnitMilliliter.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get cookingUnitMilliliter;

  /// No description provided for @cookingUnitPiece.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get cookingUnitPiece;

  /// No description provided for @cookingUnitUnit.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get cookingUnitUnit;

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

  /// No description provided for @cookingAssistTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking assistant'**
  String get cookingAssistTitle;

  /// No description provided for @cookingAssistHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about this step, substitutes, servings…'**
  String get cookingAssistHint;

  /// No description provided for @cookingAssistGreeting.
  ///
  /// In en, this message translates to:
  /// **'How can I help with this step?'**
  String get cookingAssistGreeting;

  /// No description provided for @cookingAssistSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get cookingAssistSend;

  /// No description provided for @cookingAssistSending.
  ///
  /// In en, this message translates to:
  /// **'answering…'**
  String get cookingAssistSending;

  /// No description provided for @cookingAssistSlow.
  ///
  /// In en, this message translates to:
  /// **'This question needs a little more time'**
  String get cookingAssistSlow;

  /// No description provided for @cookingAssistOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — the assistant needs a connection'**
  String get cookingAssistOffline;

  /// No description provided for @cookingAssistBusy.
  ///
  /// In en, this message translates to:
  /// **'The assistant is busy, try again later'**
  String get cookingAssistBusy;

  /// No description provided for @cookingAssistRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get cookingAssistRetry;

  /// No description provided for @cookingAssistFiltered.
  ///
  /// In en, this message translates to:
  /// **'Can\'t answer this question.'**
  String get cookingAssistFiltered;

  /// No description provided for @cookingAssistUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The assistant isn\'t available for this cooking session. You can keep cooking as usual.'**
  String get cookingAssistUnavailable;

  /// No description provided for @cookingAssistInStock.
  ///
  /// In en, this message translates to:
  /// **'In your pantry'**
  String get cookingAssistInStock;

  /// No description provided for @cookingAssistUnverified.
  ///
  /// In en, this message translates to:
  /// **'Suggestion not checked for allergens'**
  String get cookingAssistUnverified;

  /// No description provided for @cookingAssistBlocked.
  ///
  /// In en, this message translates to:
  /// **'Not suggested because of allergies'**
  String get cookingAssistBlocked;

  /// No description provided for @cookingAssistFoodSafety.
  ///
  /// In en, this message translates to:
  /// **'Check doneness and food safety yourself.'**
  String get cookingAssistFoodSafety;

  /// No description provided for @cookingAssistDegraded.
  ///
  /// In en, this message translates to:
  /// **'Short answer — the assistant is limited'**
  String get cookingAssistDegraded;

  /// No description provided for @cookingAssistStepChip.
  ///
  /// In en, this message translates to:
  /// **'Step {step}'**
  String cookingAssistStepChip(int step);

  /// No description provided for @cookingAssistProgressAllergen.
  ///
  /// In en, this message translates to:
  /// **'checking allergens…'**
  String get cookingAssistProgressAllergen;

  /// No description provided for @cookingAssistProgressSubstitute.
  ///
  /// In en, this message translates to:
  /// **'looking for substitutes…'**
  String get cookingAssistProgressSubstitute;

  /// No description provided for @cookingAssistProgressScale.
  ///
  /// In en, this message translates to:
  /// **'working out the servings…'**
  String get cookingAssistProgressScale;

  /// No description provided for @cookingAssistProgressStep.
  ///
  /// In en, this message translates to:
  /// **'reading the recipe…'**
  String get cookingAssistProgressStep;

  /// No description provided for @cookingAssistSuspected.
  ///
  /// In en, this message translates to:
  /// **'Left out {dish} — may contain {allergen}'**
  String cookingAssistSuspected(String dish, String allergen);

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchen assistant'**
  String get assistantTitle;

  /// No description provided for @assistantGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! Ask me what to cook, what to use up, or how to plan meals.'**
  String get assistantGreeting;

  /// No description provided for @assistantPlanningGreeting.
  ///
  /// In en, this message translates to:
  /// **'Let us plan this meal together.'**
  String get assistantPlanningGreeting;

  /// No description provided for @assistantSuggestTonight.
  ///
  /// In en, this message translates to:
  /// **'What should we cook tonight?'**
  String get assistantSuggestTonight;

  /// No description provided for @assistantSuggestExpiring.
  ///
  /// In en, this message translates to:
  /// **'What can I cook with food about to expire?'**
  String get assistantSuggestExpiring;

  /// No description provided for @assistantSuggestFamily.
  ///
  /// In en, this message translates to:
  /// **'A dish the whole family can eat?'**
  String get assistantSuggestFamily;

  /// No description provided for @assistantSuggestQuick.
  ///
  /// In en, this message translates to:
  /// **'A quick breakfast idea?'**
  String get assistantSuggestQuick;

  /// No description provided for @assistantSuggestPlanMeal.
  ///
  /// In en, this message translates to:
  /// **'Suggest dishes for this meal'**
  String get assistantSuggestPlanMeal;

  /// No description provided for @assistantRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You are asking a bit fast — try again in a minute.'**
  String get assistantRateLimited;

  /// No description provided for @assistantProgressSearch.
  ///
  /// In en, this message translates to:
  /// **'looking for dishes…'**
  String get assistantProgressSearch;

  /// No description provided for @assistantMissingIngredients.
  ///
  /// In en, this message translates to:
  /// **'Missing: {items}'**
  String assistantMissingIngredients(String items);

  /// No description provided for @assistantPlanDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String assistantPlanDay(int day);

  /// No description provided for @assistantFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Ask the kitchen assistant'**
  String get assistantFabTooltip;

  /// No description provided for @assistantAskSlot.
  ///
  /// In en, this message translates to:
  /// **'Ask the assistant'**
  String get assistantAskSlot;

  /// No description provided for @assistantHorizonTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan for how many days?'**
  String get assistantHorizonTitle;

  /// No description provided for @assistantHorizonOption.
  ///
  /// In en, this message translates to:
  /// **'{days} day(s)'**
  String assistantHorizonOption(int days);

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

  /// No description provided for @familyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from household'**
  String get familyRemove;

  /// No description provided for @familyRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the household?'**
  String familyRemoveConfirm(String name);

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
  /// **'No allergen entries saved'**
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
  /// **'Remove this dish from the meal?'**
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
  /// **'Could not load suggestions. Retry or choose a recipe.'**
  String get mealplanSuggestionsUnavailable;

  /// No description provided for @mealplanSuggestionsExhausted.
  ///
  /// In en, this message translates to:
  /// **'No suggestions to choose. Generate suggestions to continue.'**
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
  /// **'Selection was not saved. Refresh suggestions and retry.'**
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

  /// No description provided for @cookingPendingShoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Some ingredients are not bought yet'**
  String get cookingPendingShoppingTitle;

  /// No description provided for @cookingPendingShoppingMessage.
  ///
  /// In en, this message translates to:
  /// **'This dish still needs {count} item(s) from the shopping list:'**
  String cookingPendingShoppingMessage(int count);

  /// No description provided for @cookingPendingShoppingUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get cookingPendingShoppingUnassigned;

  /// No description provided for @cookingPendingShoppingGoShopping.
  ///
  /// In en, this message translates to:
  /// **'Go shopping & assign'**
  String get cookingPendingShoppingGoShopping;

  /// No description provided for @cookingPendingShoppingCookAnyway.
  ///
  /// In en, this message translates to:
  /// **'Cook anyway'**
  String get cookingPendingShoppingCookAnyway;

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

  /// No description provided for @notificationQuickActionProcessing.
  ///
  /// In en, this message translates to:
  /// **'Updating inventory…'**
  String get notificationQuickActionProcessing;

  /// No description provided for @notificationQuickActionSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired — tap to sign in'**
  String get notificationQuickActionSessionExpired;

  /// No description provided for @notificationQuickActionOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Tap to open the app'**
  String get notificationQuickActionOpenApp;

  /// No description provided for @notificationQuickActionRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete — try again'**
  String get notificationQuickActionRetry;

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
  /// **'The list shows allergy check results, scores and suggestion signals. ⭐ marks the algorithm\'s recommendation; repetition is an advisory signal.'**
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
  /// **'Suggestion signals'**
  String get planningCandidateBreakdown;

  /// No description provided for @planningCandidateWeight.
  ///
  /// In en, this message translates to:
  /// **'weight {weight}'**
  String planningCandidateWeight(String weight);

  /// No description provided for @planningCandidateNoBreakdown.
  ///
  /// In en, this message translates to:
  /// **'No suggestion signal data is available.'**
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
  /// **'Planned repetition signal'**
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
  /// **'Repeated dishes in the plan'**
  String get planningRepetitionTitle;

  /// No description provided for @planningRepetitionTooltip.
  ///
  /// In en, this message translates to:
  /// **'View planned dish repetition'**
  String get planningRepetitionTooltip;

  /// No description provided for @planningRepetitionWindow.
  ///
  /// In en, this message translates to:
  /// **'{days}-day lookback'**
  String planningRepetitionWindow(int days);

  /// No description provided for @planningRepetitionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assigned dish repeats from {days} days ago through today.'**
  String planningRepetitionEmpty(int days);

  /// No description provided for @planningRepetitionCount.
  ///
  /// In en, this message translates to:
  /// **'Assigned {count} times'**
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
  /// **'Item name *'**
  String get shoppingNameLabel;

  /// No description provided for @shoppingQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity *'**
  String get shoppingQuantityLabel;

  /// No description provided for @shoppingUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit *'**
  String get shoppingUnitLabel;

  /// No description provided for @shoppingCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get shoppingCategoryLabel;

  /// No description provided for @shoppingNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an item name'**
  String get shoppingNameRequired;

  /// No description provided for @shoppingQuantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be a number greater than 0'**
  String get shoppingQuantityInvalid;

  /// No description provided for @shoppingCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please choose a category'**
  String get shoppingCategoryRequired;

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
  /// **'No allergies recorded'**
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

  /// No description provided for @dependentSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get dependentSave;

  /// No description provided for @dependentCardCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 profile} other{{count} profiles}}'**
  String dependentCardCount(int count);

  /// No description provided for @dependentCardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profiles yet'**
  String get dependentCardEmpty;

  /// No description provided for @dependentCardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dependentCardViewAll;

  /// No description provided for @dependentCardView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get dependentCardView;

  /// No description provided for @dependentDobHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get dependentDobHint;

  /// No description provided for @dependentDobNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get dependentDobNotSet;

  /// No description provided for @dependentDobClear.
  ///
  /// In en, this message translates to:
  /// **'Clear date of birth'**
  String get dependentDobClear;

  /// No description provided for @dependentNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be 255 characters or fewer'**
  String get dependentNameTooLong;

  /// No description provided for @dependentCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Profile created'**
  String get dependentCreatedToast;

  /// No description provided for @dependentGuardianInactiveTag.
  ///
  /// In en, this message translates to:
  /// **'Needs a new guardian'**
  String get dependentGuardianInactiveTag;

  /// No description provided for @dependentGuardianInactiveBanner.
  ///
  /// In en, this message translates to:
  /// **'This profile\'s guardian has left the household or no longer has permission to manage it. The data is kept; the household owner needs to assign a new guardian before it can be edited.'**
  String get dependentGuardianInactiveBanner;

  /// No description provided for @dependentGuardianInactiveOwnerHint.
  ///
  /// In en, this message translates to:
  /// **'Until an active guardian is assigned, only the household owner can edit the health profile.'**
  String get dependentGuardianInactiveOwnerHint;

  /// No description provided for @dependentSummarySection.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get dependentSummarySection;

  /// No description provided for @dependentHealthRestricted.
  ///
  /// In en, this message translates to:
  /// **'Only the current guardian or the household owner can view the full health profile.'**
  String get dependentHealthRestricted;

  /// No description provided for @dependentGuardianSection.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get dependentGuardianSection;

  /// No description provided for @dependentGuardianYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String dependentGuardianYou(String name);

  /// No description provided for @dependentGuardianLeft.
  ///
  /// In en, this message translates to:
  /// **'Left the household'**
  String get dependentGuardianLeft;

  /// No description provided for @dependentGuardianNoManage.
  ///
  /// In en, this message translates to:
  /// **'No longer allowed to manage'**
  String get dependentGuardianNoManage;

  /// No description provided for @dependentChangeGuardian.
  ///
  /// In en, this message translates to:
  /// **'Change guardian'**
  String get dependentChangeGuardian;

  /// No description provided for @dependentChangeGuardianTitle.
  ///
  /// In en, this message translates to:
  /// **'Change guardian — {name}'**
  String dependentChangeGuardianTitle(String name);

  /// No description provided for @dependentChangeGuardianEmpty.
  ///
  /// In en, this message translates to:
  /// **'No member can be assigned as guardian.'**
  String get dependentChangeGuardianEmpty;

  /// No description provided for @dependentGuardianChangedToast.
  ///
  /// In en, this message translates to:
  /// **'Guardian changed'**
  String get dependentGuardianChangedToast;

  /// No description provided for @dependentDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get dependentDelete;

  /// No description provided for @dependentDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}\'s profile?'**
  String dependentDeleteConfirmTitle(String name);

  /// No description provided for @dependentDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All health and allergy data of this profile will be permanently deleted. This cannot be undone.'**
  String get dependentDeleteConfirmBody;

  /// No description provided for @dependentDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Profile deleted'**
  String get dependentDeletedToast;

  /// No description provided for @dependentNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get dependentNotFoundTitle;

  /// No description provided for @dependentNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted or belong to another household.'**
  String get dependentNotFoundBody;

  /// No description provided for @dependentBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get dependentBackToList;

  /// No description provided for @dependentNoAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get dependentNoAccessTitle;

  /// No description provided for @dependentNoAccessHealth.
  ///
  /// In en, this message translates to:
  /// **'Only the current guardian or the household owner can edit this health profile.'**
  String get dependentNoAccessHealth;

  /// No description provided for @dependentNoAccessAllergens.
  ///
  /// In en, this message translates to:
  /// **'Only the current guardian or the household owner can edit these allergies.'**
  String get dependentNoAccessAllergens;

  /// No description provided for @dependentHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Health — {name}'**
  String dependentHealthTitle(String name);

  /// No description provided for @dependentAllergensTitle.
  ///
  /// In en, this message translates to:
  /// **'Allergies — {name}'**
  String dependentAllergensTitle(String name);

  /// No description provided for @dependentErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get dependentErrorForbidden;

  /// No description provided for @dependentErrorNoHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join a household first.'**
  String get dependentErrorNoHousehold;

  /// No description provided for @dependentErrorInvalidGuardian.
  ///
  /// In en, this message translates to:
  /// **'This member can\'t be the guardian. Please choose someone else.'**
  String get dependentErrorInvalidGuardian;

  /// No description provided for @dependentGuardianCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get dependentGuardianCurrent;

  /// No description provided for @dependentBornOn.
  ///
  /// In en, this message translates to:
  /// **'Born {date}'**
  String dependentBornOn(String date);

  /// No description provided for @dependentHealthUnknownDiet.
  ///
  /// In en, this message translates to:
  /// **'This profile has a diet this app version doesn\'t support. Update the app to edit it.'**
  String get dependentHealthUnknownDiet;

  /// No description provided for @dependentMoreChip.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String dependentMoreChip(int count);

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

  /// No description provided for @shoppingPriceLostItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'This item was deleted on another device — the price you entered wasn\'t saved.'**
  String get shoppingPriceLostItemDeleted;

  /// No description provided for @shoppingPriceLostListClosed.
  ///
  /// In en, this message translates to:
  /// **'The list has moved to a new week — the price you entered wasn\'t saved.'**
  String get shoppingPriceLostListClosed;

  /// No description provided for @shoppingPriceNotSaved.
  ///
  /// In en, this message translates to:
  /// **'This item was just updated by someone else — the price you entered was not saved. Untick and tick again to re-enter it.'**
  String get shoppingPriceNotSaved;

  /// No description provided for @shoppingAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get shoppingAssign;

  /// No description provided for @shoppingAssignedMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get shoppingAssignedMe;

  /// No description provided for @shoppingAssigneeFormer.
  ///
  /// In en, this message translates to:
  /// **'Former member'**
  String get shoppingAssigneeFormer;

  /// No description provided for @shoppingAssignNeedsNetwork.
  ///
  /// In en, this message translates to:
  /// **'You need a connection to assign items'**
  String get shoppingAssignNeedsNetwork;

  /// No description provided for @shoppingAssigneeInvalid.
  ///
  /// In en, this message translates to:
  /// **'This person can no longer be assigned — the member list was reloaded.'**
  String get shoppingAssigneeInvalid;

  /// No description provided for @shoppingAssignToMe.
  ///
  /// In en, this message translates to:
  /// **'I\'ll take it'**
  String get shoppingAssignToMe;

  /// No description provided for @shoppingUnassign.
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get shoppingUnassign;

  /// No description provided for @shoppingMineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is assigned to you yet.'**
  String get shoppingMineEmpty;

  /// No description provided for @shoppingFilterMine.
  ///
  /// In en, this message translates to:
  /// **'Mine ({count})'**
  String shoppingFilterMine(int count);

  /// No description provided for @shoppingFilterMineNoCount.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get shoppingFilterMineNoCount;

  /// No description provided for @shoppingAssignSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing… you can assign once it\'s done'**
  String get shoppingAssignSyncing;

  /// No description provided for @shoppingAssigneeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get shoppingAssigneeUnknown;

  /// No description provided for @navShoppingAssignedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Shopping, {count} items assigned to you'**
  String navShoppingAssignedSemantics(int count);

  /// No description provided for @shoppingAddRejected.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add \"{name}\" — the server rejected it, so it was removed from the list. Please add it again.'**
  String shoppingAddRejected(String name);

  /// No description provided for @aiOfflineModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Using offline mode — results may be simpler than usual'**
  String get aiOfflineModeBanner;

  /// No description provided for @aiOfflineEstimate.
  ///
  /// In en, this message translates to:
  /// **'Offline estimate'**
  String get aiOfflineEstimate;

  /// No description provided for @aiOfflineEstimateConfidence.
  ///
  /// In en, this message translates to:
  /// **'Offline estimate · {percent}%'**
  String aiOfflineEstimateConfidence(int percent);

  /// No description provided for @shoppingManageCategoriesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get shoppingManageCategoriesTooltip;

  /// No description provided for @shoppingShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share list'**
  String get shoppingShareTooltip;

  /// No description provided for @shoppingCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping categories'**
  String get shoppingCategoriesTitle;

  /// No description provided for @shoppingCategoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Create categories to colour and order your shopping list your way.\nCategories are kept on this device only and are not synced to your family.'**
  String get shoppingCategoriesEmpty;

  /// No description provided for @shoppingCategoriesLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Kept on this device only — not synced to your family.'**
  String get shoppingCategoriesLocalNote;

  /// No description provided for @shoppingCategoryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get shoppingCategoryAdd;

  /// No description provided for @shoppingCategoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get shoppingCategoryEdit;

  /// No description provided for @shoppingCategoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get shoppingCategoryNameLabel;

  /// No description provided for @shoppingCategoryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get shoppingCategoryColorLabel;

  /// No description provided for @shoppingCategorySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get shoppingCategorySave;

  /// No description provided for @shoppingCategoryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get shoppingCategoryCancel;

  /// No description provided for @shoppingCategoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get shoppingCategoryDelete;

  /// No description provided for @shoppingCategoryErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category name can\'t be empty'**
  String get shoppingCategoryErrEmpty;

  /// No description provided for @shoppingCategoryErrTooLong.
  ///
  /// In en, this message translates to:
  /// **'Category name must be at most {max} characters'**
  String shoppingCategoryErrTooLong(int max);

  /// No description provided for @shoppingCategoryErrDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists'**
  String get shoppingCategoryErrDuplicate;

  /// No description provided for @shoppingCategoriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load categories'**
  String get shoppingCategoriesLoadFailed;

  /// No description provided for @shoppingCategoryErrSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save, please try again'**
  String get shoppingCategoryErrSaveFailed;

  /// No description provided for @shoppingCategoryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete category \"{name}\"? Items already in this category keep it — only the colour and order hint is lost.'**
  String shoppingCategoryDeleteConfirm(String name);

  /// No description provided for @shoppingShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share shopping list'**
  String get shoppingShareTitle;

  /// No description provided for @shoppingShareCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get shoppingShareCopyText;

  /// No description provided for @shoppingShareNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items to share yet'**
  String get shoppingShareNoItems;

  /// No description provided for @shoppingShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shoppingShareLink;

  /// No description provided for @shoppingShareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get shoppingShareComingSoon;

  /// No description provided for @shoppingShareCopied.
  ///
  /// In en, this message translates to:
  /// **'Shopping list copied to clipboard'**
  String get shoppingShareCopied;

  /// No description provided for @shoppingShareTextHeader.
  ///
  /// In en, this message translates to:
  /// **'🛒 Shopping list'**
  String get shoppingShareTextHeader;

  /// No description provided for @shoppingShareTextProgress.
  ///
  /// In en, this message translates to:
  /// **'Bought: {checked}/{total}'**
  String shoppingShareTextProgress(int checked, int total);

  /// No description provided for @shoppingShareTextUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get shoppingShareTextUncategorized;

  /// No description provided for @shoppingShareTextFooter.
  ///
  /// In en, this message translates to:
  /// **'Made with Smart Kitchen App'**
  String get shoppingShareTextFooter;

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal attendance'**
  String get attendanceTitle;

  /// No description provided for @attendanceYes.
  ///
  /// In en, this message translates to:
  /// **'Attending'**
  String get attendanceYes;

  /// No description provided for @attendanceNo.
  ///
  /// In en, this message translates to:
  /// **'Not attending'**
  String get attendanceNo;

  /// No description provided for @attendanceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get attendanceUnknown;

  /// No description provided for @attendanceClear.
  ///
  /// In en, this message translates to:
  /// **'Clear response'**
  String get attendanceClear;

  /// No description provided for @attendanceClosed.
  ///
  /// In en, this message translates to:
  /// **'This meal has passed or you only have view access, so attendance can\'t be changed.'**
  String get attendanceClosed;

  /// No description provided for @attendanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load attendance'**
  String get attendanceLoadFailed;

  /// No description provided for @attendanceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Response was not saved. Please retry.'**
  String get attendanceSaveFailed;

  /// No description provided for @attendanceMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get attendanceMember;

  /// No description provided for @attendanceSummary.
  ///
  /// In en, this message translates to:
  /// **'{yes} members attending · {unknown} unanswered'**
  String attendanceSummary(int yes, int unknown);

  /// No description provided for @mealPlanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm weekly menu'**
  String get mealPlanConfirm;

  /// No description provided for @mealPlanConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Weekly menu confirmed'**
  String get mealPlanConfirmed;

  /// No description provided for @mealPlanConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm. Choose at least one recipe and complete or remove empty dishes.'**
  String get mealPlanConfirmFailed;

  /// No description provided for @mealPlanGenerateSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Generate suggestions'**
  String get mealPlanGenerateSuggestions;

  /// No description provided for @mealPlanChooseRecipe.
  ///
  /// In en, this message translates to:
  /// **'Choose a recipe'**
  String get mealPlanChooseRecipe;

  /// No description provided for @mealComposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic meal menu'**
  String get mealComposeTitle;

  /// No description provided for @mealComposePeoplePolicy.
  ///
  /// In en, this message translates to:
  /// **'Members who have not replied are included. Ingredients can all be purchased.'**
  String get mealComposePeoplePolicy;

  /// No description provided for @mealComposePeopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} diners'**
  String mealComposePeopleCount(int count);

  /// No description provided for @mealComposeReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace this meal menu?'**
  String get mealComposeReplaceTitle;

  /// No description provided for @mealComposeReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'Existing dishes will only be replaced after a complete new menu is ready.'**
  String get mealComposeReplaceBody;

  /// No description provided for @mealComposeRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Re-suggest the whole meal'**
  String get mealComposeRegenerate;

  /// No description provided for @mealComposeGenerate.
  ///
  /// In en, this message translates to:
  /// **'Create meal menu'**
  String get mealComposeGenerate;

  /// No description provided for @mealComposeLoading.
  ///
  /// In en, this message translates to:
  /// **'Choosing a complete menu…'**
  String get mealComposeLoading;

  /// No description provided for @mealComposeRunning.
  ///
  /// In en, this message translates to:
  /// **'The request is still processing. Refresh to check; your existing menu is preserved.'**
  String get mealComposeRunning;

  /// No description provided for @mealComposeIncomplete.
  ///
  /// In en, this message translates to:
  /// **'No complete suitable menu was found. Your existing menu is preserved.'**
  String get mealComposeIncomplete;

  /// No description provided for @mealComposeStale.
  ///
  /// In en, this message translates to:
  /// **'The meal or diners changed. Refresh before trying again.'**
  String get mealComposeStale;

  /// No description provided for @mealComposeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Automatic menus are not enabled on this server yet.'**
  String get mealComposeDisabled;

  /// No description provided for @mealComposeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not finish. Refresh to recover the request before trying again.'**
  String get mealComposeFailed;

  /// No description provided for @mealComposeRefresh.
  ///
  /// In en, this message translates to:
  /// **'Check or refresh'**
  String get mealComposeRefresh;

  /// No description provided for @mealComposeShopping.
  ///
  /// In en, this message translates to:
  /// **'Ingredients to buy'**
  String get mealComposeShopping;

  /// No description provided for @mealComposeNutritionWarning.
  ///
  /// In en, this message translates to:
  /// **'Nutrition or calorie targets are estimated, incomplete, or outside the target range.'**
  String get mealComposeNutritionWarning;

  /// No description provided for @mealComposeDishServings.
  ///
  /// In en, this message translates to:
  /// **'{name} · {servings} recipe servings'**
  String mealComposeDishServings(String name, String servings);

  /// No description provided for @mealComposeCalories.
  ///
  /// In en, this message translates to:
  /// **'Estimated total: {calories} kcal'**
  String mealComposeCalories(int calories);

  /// No description provided for @mealComposeSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Your menu was saved. Refresh to finish syncing the meal plan.'**
  String get mealComposeSyncPending;

  /// No description provided for @mealplanOutcomeUnknown.
  ///
  /// In en, this message translates to:
  /// **'The result is not yet known. Read again to view saved data; it may still change if the earlier request finishes. Continuing uses only the data you have just read.'**
  String get mealplanOutcomeUnknown;

  /// No description provided for @mealplanReadAgain.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get mealplanReadAgain;

  /// No description provided for @mealplanContinueSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Continue from the data just read'**
  String get mealplanContinueSnapshot;

  /// No description provided for @mealplanSuggestionsChanged.
  ///
  /// In en, this message translates to:
  /// **'These suggestions have changed. Read the saved suggestions before choosing again.'**
  String get mealplanSuggestionsChanged;

  /// No description provided for @healthProfileDietUnset.
  ///
  /// In en, this message translates to:
  /// **'Diet not selected'**
  String get healthProfileDietUnset;

  /// No description provided for @healthProfileDietNone.
  ///
  /// In en, this message translates to:
  /// **'No special diet preference'**
  String get healthProfileDietNone;

  /// No description provided for @healthProfileDietHelp.
  ///
  /// In en, this message translates to:
  /// **'Diet rules depend on the meal planning mode. Declare allergies separately; a gluten-free diet does not declare a gluten allergy.'**
  String get healthProfileDietHelp;

  /// No description provided for @healthProfileHeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a height from 1 to 300 cm, or leave blank'**
  String get healthProfileHeightInvalid;

  /// No description provided for @healthProfileWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight from 1 to 500 kg, or leave blank'**
  String get healthProfileWeightInvalid;

  /// No description provided for @unitKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unitKcal;

  /// No description provided for @planningRepetitionWindowHint.
  ///
  /// In en, this message translates to:
  /// **'Counts assigned dishes in the plan, including both the start and end dates.'**
  String get planningRepetitionWindowHint;

  /// No description provided for @planningRepetitionRange.
  ///
  /// In en, this message translates to:
  /// **'From {start} to {end}'**
  String planningRepetitionRange(String start, String end);

  /// No description provided for @planningCandidateSignalsHint.
  ///
  /// In en, this message translates to:
  /// **'Bars show advisory signal levels.'**
  String get planningCandidateSignalsHint;

  /// No description provided for @planningRepetitionContextHint.
  ///
  /// In en, this message translates to:
  /// **'Repetition information reflects dishes assigned in the plan.'**
  String get planningRepetitionContextHint;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get commonShowPassword;

  /// No description provided for @commonHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get commonHidePassword;

  /// No description provided for @commonRequiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get commonRequiredField;

  /// No description provided for @showcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Widget showcase'**
  String get showcaseTitle;

  /// No description provided for @showcaseEntry.
  ///
  /// In en, this message translates to:
  /// **'Widget showcase (dev)'**
  String get showcaseEntry;

  /// No description provided for @showcaseToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle light/dark'**
  String get showcaseToggleTheme;

  /// No description provided for @showcaseSectionColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get showcaseSectionColors;

  /// No description provided for @showcaseSectionTypography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get showcaseSectionTypography;

  /// No description provided for @showcaseSectionButtons.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get showcaseSectionButtons;

  /// No description provided for @showcaseSectionCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get showcaseSectionCards;

  /// No description provided for @showcaseSectionInputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get showcaseSectionInputs;

  /// No description provided for @showcaseSectionStates.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get showcaseSectionStates;

  /// No description provided for @showcaseSectionOverlay.
  ///
  /// In en, this message translates to:
  /// **'Loading overlay'**
  String get showcaseSectionOverlay;

  /// No description provided for @showcaseSectionDialog.
  ///
  /// In en, this message translates to:
  /// **'Dialog'**
  String get showcaseSectionDialog;

  /// No description provided for @showcaseSampleLabel.
  ///
  /// In en, this message translates to:
  /// **'Food name'**
  String get showcaseSampleLabel;

  /// No description provided for @showcaseSampleText.
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox'**
  String get showcaseSampleText;

  /// No description provided for @showcaseHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Highlighted card'**
  String get showcaseHighlighted;

  /// No description provided for @showcaseCardNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal card'**
  String get showcaseCardNormal;

  /// No description provided for @showcaseCardTappable.
  ///
  /// In en, this message translates to:
  /// **'Tappable card'**
  String get showcaseCardTappable;

  /// No description provided for @showcaseCardElevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated card'**
  String get showcaseCardElevated;

  /// No description provided for @showcaseVariantPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get showcaseVariantPrimary;

  /// No description provided for @showcaseVariantSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get showcaseVariantSecondary;

  /// No description provided for @showcaseVariantOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get showcaseVariantOutline;

  /// No description provided for @showcaseVariantGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get showcaseVariantGoogle;

  /// No description provided for @showcaseVariantText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get showcaseVariantText;

  /// No description provided for @showcaseVariantDestructive.
  ///
  /// In en, this message translates to:
  /// **'Destructive'**
  String get showcaseVariantDestructive;

  /// No description provided for @showcaseStateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get showcaseStateLoading;

  /// No description provided for @showcaseStateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get showcaseStateDisabled;

  /// No description provided for @showcaseTapToLoad.
  ///
  /// In en, this message translates to:
  /// **'Tap to load for 2s'**
  String get showcaseTapToLoad;

  /// No description provided for @showcaseFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get showcaseFieldRequired;

  /// No description provided for @showcaseFieldServerError.
  ///
  /// In en, this message translates to:
  /// **'Field with server error'**
  String get showcaseFieldServerError;

  /// No description provided for @showcaseFieldServerErrorText.
  ///
  /// In en, this message translates to:
  /// **'This name already exists'**
  String get showcaseFieldServerErrorText;

  /// No description provided for @showcaseFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get showcaseFieldPassword;

  /// No description provided for @showcaseFieldDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled field'**
  String get showcaseFieldDisabled;

  /// No description provided for @showcaseEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get showcaseEmptyAction;

  /// No description provided for @showcaseShowOverlay.
  ///
  /// In en, this message translates to:
  /// **'Show overlay for 2s'**
  String get showcaseShowOverlay;

  /// No description provided for @showcaseOpenDialog.
  ///
  /// In en, this message translates to:
  /// **'Open confirm dialog'**
  String get showcaseOpenDialog;

  /// No description provided for @showcaseOpenDestructiveDialog.
  ///
  /// In en, this message translates to:
  /// **'Open destructive dialog'**
  String get showcaseOpenDestructiveDialog;

  /// No description provided for @showcaseDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get showcaseDialogTitle;

  /// No description provided for @showcaseDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get showcaseDialogMessage;

  /// No description provided for @showcaseDialogResult.
  ///
  /// In en, this message translates to:
  /// **'Result: {result}'**
  String showcaseDialogResult(String result);

  /// No description provided for @profileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get profileDefaultName;

  /// No description provided for @profileSessionMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile'**
  String get profileSessionMissingTitle;

  /// No description provided for @profileSessionMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session is no longer valid. Please sign in again.'**
  String get profileSessionMissingMessage;

  /// No description provided for @profileReLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get profileReLogin;

  /// No description provided for @profileWeeklyRecapNav.
  ///
  /// In en, this message translates to:
  /// **'Weekly recap'**
  String get profileWeeklyRecapNav;

  /// No description provided for @profileChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get profileChangeAvatar;

  /// No description provided for @profileAvatarPickAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another photo'**
  String get profileAvatarPickAnother;

  /// No description provided for @profileAvatarNewUnsaved.
  ///
  /// In en, this message translates to:
  /// **'New photo — not saved yet'**
  String get profileAvatarNewUnsaved;

  /// No description provided for @profileAvatarUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get profileAvatarUploading;

  /// No description provided for @profileAvatarGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get profileAvatarGallery;

  /// No description provided for @profileAvatarCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get profileAvatarCamera;

  /// No description provided for @profileAvatarPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera or photo library access is not granted. Enable it in Settings.'**
  String get profileAvatarPermissionDenied;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name can\'t be empty'**
  String get profileNameRequired;

  /// No description provided for @profileNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Full name can be at most 100 characters'**
  String get profileNameTooLong;

  /// No description provided for @profileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get profileSaving;

  /// No description provided for @profileSaveRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get profileSaveRetry;

  /// No description provided for @profileSaveErrorAfterUpload.
  ///
  /// In en, this message translates to:
  /// **'Your photo was uploaded but the profile wasn\'t saved. Check your connection and try again.'**
  String get profileSaveErrorAfterUpload;

  /// No description provided for @avatarErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid image. Please choose another JPG or PNG photo.'**
  String get avatarErrorInvalid;

  /// No description provided for @avatarErrorTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Please choose another one.'**
  String get avatarErrorTooLarge;

  /// No description provided for @healthProfileEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Health profile not set up'**
  String get healthProfileEmptyTitle;

  /// No description provided for @healthProfileEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a calorie goal, diet and allergies to get better meal suggestions.'**
  String get healthProfileEmptyMessage;

  /// No description provided for @healthProfileNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get healthProfileNotSetUp;

  /// No description provided for @healthProfileSetUpCta.
  ///
  /// In en, this message translates to:
  /// **'Set up health profile'**
  String get healthProfileSetUpCta;

  /// No description provided for @healthProfileEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get healthProfileEditAction;

  /// No description provided for @healthProfileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit health profile'**
  String get healthProfileEditTitle;

  /// No description provided for @healthProfileKcalValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal'**
  String healthProfileKcalValue(int value);

  /// No description provided for @healthProfileCaloriesNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get healthProfileCaloriesNotSet;

  /// No description provided for @healthProfileCaloriesNotSetToggle.
  ///
  /// In en, this message translates to:
  /// **'No calorie goal'**
  String get healthProfileCaloriesNotSetToggle;

  /// No description provided for @healthProfileCaloriesCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {value} kcal'**
  String healthProfileCaloriesCurrent(int value);

  /// No description provided for @healthProfileCaloriesOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Outside {min}–{max} — drag the slider to pick a new value.'**
  String healthProfileCaloriesOutOfRange(int min, int max);

  /// No description provided for @healthProfileNeedsNetwork.
  ///
  /// In en, this message translates to:
  /// **'An internet connection is needed to edit.'**
  String get healthProfileNeedsNetwork;

  /// No description provided for @healthProfileCaloriesServerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid calorie goal'**
  String get healthProfileCaloriesServerInvalid;

  /// No description provided for @allergenNeedsNetwork.
  ///
  /// In en, this message translates to:
  /// **'An internet connection is needed to edit allergies.'**
  String get allergenNeedsNetwork;

  /// No description provided for @allergensHealthLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your current allergies'**
  String get allergensHealthLoadFailedTitle;

  /// No description provided for @allergensHealthLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'To avoid overwriting saved allergies, the data must finish loading before editing.'**
  String get allergensHealthLoadFailedMessage;

  /// No description provided for @allergensSavedSection.
  ///
  /// In en, this message translates to:
  /// **'Saved allergies'**
  String get allergensSavedSection;

  /// No description provided for @allergensCatalogCount.
  ///
  /// In en, this message translates to:
  /// **'{count} common allergens'**
  String allergensCatalogCount(int count);

  /// No description provided for @allergensSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String allergensSelectedCount(int count);

  /// No description provided for @allergenSaveError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while saving. Please try again.'**
  String get allergenSaveError;

  /// No description provided for @familyRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer see the household\'s inventory, meal plans and shopping list.'**
  String familyRemoveConfirmBody(String name);

  /// No description provided for @familyRemoveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get familyRemoveConfirmAction;

  /// No description provided for @familyRemoveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed {name} from the household.'**
  String familyRemoveSuccess(String name);

  /// No description provided for @familyMemberYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String familyMemberYou(String name);

  /// No description provided for @familyGuestBadge.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get familyGuestBadge;

  /// No description provided for @familyJoinedAt.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String familyJoinedAt(String date);

  /// No description provided for @familyNeedsNetwork.
  ///
  /// In en, this message translates to:
  /// **'You need a connection to invite or remove members.'**
  String get familyNeedsNetwork;

  /// No description provided for @familyErrorNotOwner.
  ///
  /// In en, this message translates to:
  /// **'You no longer have permission to manage this household.'**
  String get familyErrorNotOwner;

  /// No description provided for @familyErrorInviteLimit.
  ///
  /// In en, this message translates to:
  /// **'There are already 3 active invites. Wait for an old invite to expire and try again.'**
  String get familyErrorInviteLimit;

  /// No description provided for @familyErrorCannotRemove.
  ///
  /// In en, this message translates to:
  /// **'This member can\'t be removed.'**
  String get familyErrorCannotRemove;

  /// No description provided for @familyInviteExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String familyInviteExpiresAt(String date);

  /// No description provided for @familyInviteCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get familyInviteCopyCode;

  /// No description provided for @familyInviteCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get familyInviteCopyLink;

  /// No description provided for @familyInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get familyInviteCopied;

  /// No description provided for @familyInviteShowLast.
  ///
  /// In en, this message translates to:
  /// **'Show the latest invite'**
  String get familyInviteShowLast;

  /// No description provided for @memberHealthForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to view this member\'s health profile.'**
  String get memberHealthForbidden;

  /// No description provided for @memberDetailPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Height, weight and calorie goal are private and not shown here.'**
  String get memberDetailPrivacyNote;

  /// No description provided for @memberDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'This member could not be found.'**
  String get memberDetailNotFound;

  /// No description provided for @memberDetailClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get memberDetailClose;

  /// No description provided for @nutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly nutrition'**
  String get nutritionTitle;

  /// No description provided for @nutritionWeekThisTitle.
  ///
  /// In en, this message translates to:
  /// **'This week\'s nutrition'**
  String get nutritionWeekThisTitle;

  /// No description provided for @nutritionComplianceExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get nutritionComplianceExcellent;

  /// No description provided for @nutritionComplianceGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get nutritionComplianceGood;

  /// No description provided for @nutritionComplianceNeedsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Needs improvement'**
  String get nutritionComplianceNeedsImprovement;

  /// No description provided for @nutritionCompliancePoor.
  ///
  /// In en, this message translates to:
  /// **'Not met'**
  String get nutritionCompliancePoor;

  /// No description provided for @nutritionComplianceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not rated yet'**
  String get nutritionComplianceUnknown;

  /// No description provided for @nutritionScoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'{score}/100'**
  String nutritionScoreOutOf(int score);

  /// No description provided for @nutritionScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan compliance score'**
  String get nutritionScoreLabel;

  /// No description provided for @nutritionAllergenNotChecked.
  ///
  /// In en, this message translates to:
  /// **'Allergens not checked — score is based on calories only'**
  String get nutritionAllergenNotChecked;

  /// No description provided for @nutritionSetTarget.
  ///
  /// In en, this message translates to:
  /// **'Set calorie target'**
  String get nutritionSetTarget;

  /// No description provided for @nutritionWeeklyTotal.
  ///
  /// In en, this message translates to:
  /// **'Weekly total'**
  String get nutritionWeeklyTotal;

  /// No description provided for @nutritionTargetForDays.
  ///
  /// In en, this message translates to:
  /// **'Target for {days} days with data: {kcal} kcal'**
  String nutritionTargetForDays(int days, String kcal);

  /// No description provided for @nutritionWeeklyDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} kcal vs target'**
  String nutritionWeeklyDelta(String delta);

  /// No description provided for @nutritionNoTarget.
  ///
  /// In en, this message translates to:
  /// **'No target set'**
  String get nutritionNoTarget;

  /// No description provided for @nutritionAvgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg {kcal} kcal/day ({days} days with data)'**
  String nutritionAvgPerDay(String kcal, int days);

  /// No description provided for @nutritionNoDataDays.
  ///
  /// In en, this message translates to:
  /// **'No day has nutrition data yet'**
  String get nutritionNoDataDays;

  /// No description provided for @nutritionMissingData.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 dish has no nutrition data} other{{count} dishes have no nutrition data}}'**
  String nutritionMissingData(int count);

  /// No description provided for @nutritionKcal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String nutritionKcal(String kcal);

  /// No description provided for @nutritionMacroLine.
  ///
  /// In en, this message translates to:
  /// **'P {p} g · C {c} g · F {f} g'**
  String nutritionMacroLine(String p, String c, String f);

  /// No description provided for @nutritionNoMealsDay.
  ///
  /// In en, this message translates to:
  /// **'No dishes'**
  String get nutritionNoMealsDay;

  /// No description provided for @nutritionProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutritionProtein;

  /// No description provided for @nutritionCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutritionCarbs;

  /// No description provided for @nutritionFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutritionFat;

  /// No description provided for @nutritionMacroPercent.
  ///
  /// In en, this message translates to:
  /// **'{name} {percent}%'**
  String nutritionMacroPercent(String name, String percent);

  /// No description provided for @nutritionNoMacroData.
  ///
  /// In en, this message translates to:
  /// **'No macro data yet'**
  String get nutritionNoMacroData;

  /// No description provided for @nutritionDayOver.
  ///
  /// In en, this message translates to:
  /// **'Over target'**
  String get nutritionDayOver;

  /// No description provided for @nutritionDayUnder.
  ///
  /// In en, this message translates to:
  /// **'Well under'**
  String get nutritionDayUnder;

  /// No description provided for @nutritionDayOnTarget.
  ///
  /// In en, this message translates to:
  /// **'On target'**
  String get nutritionDayOnTarget;

  /// No description provided for @nutritionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No dishes confirmed this week yet'**
  String get nutritionEmpty;

  /// No description provided for @nutritionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load nutrition data'**
  String get nutritionLoadFailed;

  /// No description provided for @nutritionViewMealPlan.
  ///
  /// In en, this message translates to:
  /// **'View weekly plan'**
  String get nutritionViewMealPlan;

  /// No description provided for @nutritionDishNoData.
  ///
  /// In en, this message translates to:
  /// **'no data'**
  String get nutritionDishNoData;

  /// No description provided for @nutritionDailyBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Daily breakdown'**
  String get nutritionDailyBreakdown;

  /// No description provided for @nutritionMealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get nutritionMealBreakfast;

  /// No description provided for @nutritionMealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get nutritionMealLunch;

  /// No description provided for @nutritionMealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get nutritionMealDinner;

  /// No description provided for @nutritionMealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get nutritionMealSnack;

  /// No description provided for @nutritionBarSemantics.
  ///
  /// In en, this message translates to:
  /// **'{day}: {kcal} kcal'**
  String nutritionBarSemantics(String day, String kcal);

  /// No description provided for @nutritionChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Calories per day: {days}'**
  String nutritionChartSemantics(String days);

  /// No description provided for @nutritionMealOther.
  ///
  /// In en, this message translates to:
  /// **'Other meal'**
  String get nutritionMealOther;

  /// No description provided for @nutritionDishLine.
  ///
  /// In en, this message translates to:
  /// **'{meal}: {dish} · {value}'**
  String nutritionDishLine(String meal, String dish, String value);

  /// No description provided for @receiptScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get receiptScanTitle;

  /// No description provided for @receiptScanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get receiptScanTooltip;

  /// No description provided for @receiptScanHint.
  ///
  /// In en, this message translates to:
  /// **'Capture the whole receipt clearly. Items matching your shopping list are pre-selected; extra purchases can go to inventory.'**
  String get receiptScanHint;

  /// No description provided for @receiptScanNoImage.
  ///
  /// In en, this message translates to:
  /// **'No image yet'**
  String get receiptScanNoImage;

  /// No description provided for @receiptScanning.
  ///
  /// In en, this message translates to:
  /// **'Reading the receipt…'**
  String get receiptScanning;

  /// No description provided for @receiptErrorAiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The receipt reader is busy or not ready. Retry with this same photo, or choose another one.'**
  String get receiptErrorAiUnavailable;

  /// No description provided for @receiptErrorInProgress.
  ///
  /// In en, this message translates to:
  /// **'This receipt is still being read — try again in a few seconds.'**
  String get receiptErrorInProgress;

  /// No description provided for @receiptErrorImageRejected.
  ///
  /// In en, this message translates to:
  /// **'This photo can\'t be processed. Retrying the same photo gives the same result — take another photo.'**
  String get receiptErrorImageRejected;

  /// No description provided for @receiptErrorNoHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re not in a household yet'**
  String get receiptErrorNoHouseholdTitle;

  /// No description provided for @receiptErrorNoHousehold.
  ///
  /// In en, this message translates to:
  /// **'Join a household before scanning receipts.'**
  String get receiptErrorNoHousehold;

  /// No description provided for @receiptClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get receiptClose;

  /// No description provided for @receiptResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan result'**
  String get receiptResultTitle;

  /// No description provided for @receiptRestart.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get receiptRestart;

  /// No description provided for @receiptRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get receiptRetake;

  /// No description provided for @receiptEmpty.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the receipt, please retake the photo'**
  String get receiptEmpty;

  /// No description provided for @receiptSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String receiptSummaryTotal(String amount);

  /// No description provided for @receiptSummaryCounts.
  ///
  /// In en, this message translates to:
  /// **'{matched} matched lines · {unmatched} not on the list'**
  String receiptSummaryCounts(int matched, int unmatched);

  /// No description provided for @receiptMatchedSection.
  ///
  /// In en, this message translates to:
  /// **'Matches your shopping list'**
  String get receiptMatchedSection;

  /// No description provided for @receiptMatchedCount.
  ///
  /// In en, this message translates to:
  /// **'{lines} lines · {items} items'**
  String receiptMatchedCount(int lines, int items);

  /// No description provided for @receiptUnmatchedSection.
  ///
  /// In en, this message translates to:
  /// **'Not on the list'**
  String get receiptUnmatchedSection;

  /// No description provided for @receiptUnmatchedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String receiptUnmatchedCount(int count);

  /// No description provided for @receiptOnReceipt.
  ///
  /// In en, this message translates to:
  /// **'On receipt: \"{raw}\"'**
  String receiptOnReceipt(String raw);

  /// No description provided for @receiptBadgeReview.
  ///
  /// In en, this message translates to:
  /// **'Double-check'**
  String get receiptBadgeReview;

  /// No description provided for @receiptCatalogHint.
  ///
  /// In en, this message translates to:
  /// **'Catalog guess {percent}%'**
  String receiptCatalogHint(int percent);

  /// No description provided for @receiptMarkedBought.
  ///
  /// In en, this message translates to:
  /// **'Marked as bought'**
  String get receiptMarkedBought;

  /// No description provided for @receiptNotUpdated.
  ///
  /// In en, this message translates to:
  /// **'Not updated'**
  String get receiptNotUpdated;

  /// No description provided for @receiptSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get receiptSkipped;

  /// No description provided for @receiptAddToInventory.
  ///
  /// In en, this message translates to:
  /// **'Add to inventory'**
  String get receiptAddToInventory;

  /// No description provided for @receiptAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get receiptAdding;

  /// No description provided for @receiptAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get receiptAdded;

  /// No description provided for @receiptCategoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get receiptCategoryOptional;

  /// No description provided for @receiptUnitHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a unit before adding'**
  String get receiptUnitHint;

  /// No description provided for @receiptCommit.
  ///
  /// In en, this message translates to:
  /// **'Update shopping list ({count})'**
  String receiptCommit(int count);

  /// No description provided for @receiptDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get receiptDone;

  /// No description provided for @receiptCommitFailedBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} items couldn\'t be updated — check the Shopping screen.'**
  String receiptCommitFailedBanner(int count);

  /// No description provided for @receiptDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get receiptDoneTitle;

  /// No description provided for @receiptDoneToast.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} items'**
  String receiptDoneToast(int count);

  /// No description provided for @authBadCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password'**
  String get authBadCredentials;

  /// No description provided for @authEmailExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get authEmailExists;

  /// No description provided for @authNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get authNameRequired;

  /// No description provided for @authNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Full name must be at most 100 characters'**
  String get authNameTooLong;

  /// No description provided for @householdFull.
  ///
  /// In en, this message translates to:
  /// **'This household already has 10 members'**
  String get householdFull;

  /// No description provided for @joinRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again in a few minutes'**
  String get joinRateLimited;

  /// No description provided for @inviteQrInvalid.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a Smart Kitchen invite'**
  String get inviteQrInvalid;

  /// No description provided for @joinGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get joinGoHome;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications in this session yet. Notifications received in the background only appear here after you open them.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsNavTitle;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Get reminders about expiring food, shopping lists and planned meals.'**
  String get notificationPermissionBody;

  /// No description provided for @notificationPermissionEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get notificationPermissionEnable;

  /// No description provided for @notificationPermissionLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notificationPermissionLater;

  /// No description provided for @notificationPermissionDeniedBanner.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off'**
  String get notificationPermissionDeniedBanner;

  /// No description provided for @notificationPermissionNotDeterminedBanner.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t turned on notifications'**
  String get notificationPermissionNotDeterminedBanner;

  /// No description provided for @notificationPermissionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Notifications aren\'t available on this device'**
  String get notificationPermissionUnsupported;

  /// No description provided for @notificationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get notificationOpenSettings;

  /// No description provided for @notificationRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t register for notifications yet — we\'ll try again'**
  String get notificationRegistrationFailed;

  /// No description provided for @notificationJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationJustNow;

  /// No description provided for @notificationMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String notificationMinutesAgo(int count);

  /// No description provided for @notificationHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String notificationHoursAgo(int count);

  /// No description provided for @notificationUntitled.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get notificationUntitled;

  /// No description provided for @notificationsUnreadBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread} other{{count} unread}}'**
  String notificationsUnreadBadge(int count);

  /// No description provided for @shoppingCheckoutCta.
  ///
  /// In en, this message translates to:
  /// **'Put away ({count})'**
  String shoppingCheckoutCta(int count);

  /// No description provided for @shoppingCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Put away in pantry'**
  String get shoppingCheckoutTitle;

  /// No description provided for @shoppingCheckoutHint.
  ///
  /// In en, this message translates to:
  /// **'Check the expiry dates, then confirm to add these items to the pantry.'**
  String get shoppingCheckoutHint;

  /// No description provided for @shoppingCheckoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add {count} to pantry'**
  String shoppingCheckoutConfirm(int count);

  /// No description provided for @shoppingCheckoutDone.
  ///
  /// In en, this message translates to:
  /// **'Added {count} items to the pantry'**
  String shoppingCheckoutDone(int count);

  /// No description provided for @shoppingCheckoutEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bought items waiting to be put away.'**
  String get shoppingCheckoutEmpty;

  /// No description provided for @shoppingCheckoutOffline.
  ///
  /// In en, this message translates to:
  /// **'You need a connection to put items away.'**
  String get shoppingCheckoutOffline;

  /// No description provided for @shoppingCheckoutReloaded.
  ///
  /// In en, this message translates to:
  /// **'The list changed and was reloaded. Please check and confirm again.'**
  String get shoppingCheckoutReloaded;

  /// No description provided for @shoppingCheckoutDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already in pantry · new batch'**
  String get shoppingCheckoutDuplicate;

  /// No description provided for @shoppingCheckoutInvalidRow.
  ///
  /// In en, this message translates to:
  /// **'Check the quantity / unit'**
  String get shoppingCheckoutInvalidRow;

  /// No description provided for @shoppingInInventoryBadge.
  ///
  /// In en, this message translates to:
  /// **'In pantry'**
  String get shoppingInInventoryBadge;

  /// No description provided for @shoppingInInventoryToggleBlocked.
  ///
  /// In en, this message translates to:
  /// **'This item is already in the pantry and can\'t be unchecked.'**
  String get shoppingInInventoryToggleBlocked;

  /// No description provided for @expiryChipAdd.
  ///
  /// In en, this message translates to:
  /// **'Add expiry date'**
  String get expiryChipAdd;

  /// No description provided for @expiryChipSuggested.
  ///
  /// In en, this message translates to:
  /// **'Exp. {date} · suggested'**
  String expiryChipSuggested(Object date);

  /// No description provided for @expiryChipSet.
  ///
  /// In en, this message translates to:
  /// **'Exp. {date}'**
  String expiryChipSet(Object date);

  /// No description provided for @errShopItemAlreadyInInventory.
  ///
  /// In en, this message translates to:
  /// **'This item has already been put in the pantry.'**
  String get errShopItemAlreadyInInventory;

  /// No description provided for @errShopItemNotBought.
  ///
  /// In en, this message translates to:
  /// **'Only bought items can be put in the pantry.'**
  String get errShopItemNotBought;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingNoon.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeGreetingNoon;

  /// No description provided for @familyMemberActions.
  ///
  /// In en, this message translates to:
  /// **'Member actions'**
  String get familyMemberActions;

  /// No description provided for @mealPlanDishSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to pick this dish?'**
  String get mealPlanDishSourceTitle;

  /// No description provided for @mealPlanDishSourceAi.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions'**
  String get mealPlanDishSourceAi;

  /// No description provided for @inventoryDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This item will be removed from the pantry.'**
  String get inventoryDeleteConfirmMessage;

  /// No description provided for @inventoryDeleteReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you removing this item?'**
  String get inventoryDeleteReasonTitle;

  /// No description provided for @allergenGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten'**
  String get allergenGluten;

  /// No description provided for @allergenCrustaceans.
  ///
  /// In en, this message translates to:
  /// **'Crustaceans'**
  String get allergenCrustaceans;

  /// No description provided for @allergenEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get allergenEggs;

  /// No description provided for @allergenFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get allergenFish;

  /// No description provided for @allergenPeanuts.
  ///
  /// In en, this message translates to:
  /// **'Peanuts'**
  String get allergenPeanuts;

  /// No description provided for @allergenSoybeans.
  ///
  /// In en, this message translates to:
  /// **'Soybeans'**
  String get allergenSoybeans;

  /// No description provided for @allergenMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get allergenMilk;

  /// No description provided for @allergenTreeNuts.
  ///
  /// In en, this message translates to:
  /// **'Tree nuts'**
  String get allergenTreeNuts;

  /// No description provided for @allergenCelery.
  ///
  /// In en, this message translates to:
  /// **'Celery'**
  String get allergenCelery;

  /// No description provided for @allergenMustard.
  ///
  /// In en, this message translates to:
  /// **'Mustard'**
  String get allergenMustard;

  /// No description provided for @allergenSesame.
  ///
  /// In en, this message translates to:
  /// **'Sesame'**
  String get allergenSesame;

  /// No description provided for @allergenSulphurDioxide.
  ///
  /// In en, this message translates to:
  /// **'Sulphur dioxide'**
  String get allergenSulphurDioxide;

  /// No description provided for @allergenLupin.
  ///
  /// In en, this message translates to:
  /// **'Lupin'**
  String get allergenLupin;

  /// No description provided for @allergenMolluscs.
  ///
  /// In en, this message translates to:
  /// **'Molluscs'**
  String get allergenMolluscs;

  /// No description provided for @dietTypeUnsetShort.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get dietTypeUnsetShort;

  /// No description provided for @dietTypeNoneShort.
  ///
  /// In en, this message translates to:
  /// **'No restriction'**
  String get dietTypeNoneShort;

  /// No description provided for @dietTypeUnsetDescription.
  ///
  /// In en, this message translates to:
  /// **'No diet chosen — meal plans apply no diet constraint.'**
  String get dietTypeUnsetDescription;

  /// No description provided for @dietTypeNoneDescription.
  ///
  /// In en, this message translates to:
  /// **'Regular eating, no food groups excluded.'**
  String get dietTypeNoneDescription;

  /// No description provided for @dietTypeKetoDescription.
  ///
  /// In en, this message translates to:
  /// **'Very low carb, high fat — limits rice, bread and sweets.'**
  String get dietTypeKetoDescription;

  /// No description provided for @dietTypeVegetarianDescription.
  ///
  /// In en, this message translates to:
  /// **'No meat or fish; eggs and dairy are fine.'**
  String get dietTypeVegetarianDescription;

  /// No description provided for @dietTypeVeganDescription.
  ///
  /// In en, this message translates to:
  /// **'Plant-based only: no meat, fish, eggs, dairy or other animal products.'**
  String get dietTypeVeganDescription;

  /// No description provided for @dietTypePescatarianDescription.
  ///
  /// In en, this message translates to:
  /// **'No meat, but fish and seafood are fine.'**
  String get dietTypePescatarianDescription;

  /// No description provided for @dietTypeGlutenFreeDescription.
  ///
  /// In en, this message translates to:
  /// **'Avoids wheat, barley and other gluten-containing foods.'**
  String get dietTypeGlutenFreeDescription;

  /// No description provided for @dietTypeDiabeticDescription.
  ///
  /// In en, this message translates to:
  /// **'Limits sugar and fast-absorbing carbs, favours low-sugar dishes.'**
  String get dietTypeDiabeticDescription;

  /// No description provided for @inventoryCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get inventoryCategoryLabel;

  /// No description provided for @inventoryCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please choose a category'**
  String get inventoryCategoryRequired;

  /// No description provided for @inventoryZeroQuantityTitle.
  ///
  /// In en, this message translates to:
  /// **'Used up this item?'**
  String get inventoryZeroQuantityTitle;

  /// No description provided for @inventoryZeroQuantityConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get inventoryZeroQuantityConfirm;

  /// No description provided for @attendanceUnsure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get attendanceUnsure;

  /// No description provided for @attendanceYou.
  ///
  /// In en, this message translates to:
  /// **'You: {status}'**
  String attendanceYou(String status);

  /// No description provided for @planningGuestSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'Guests for this meal'**
  String get planningGuestSlotTitle;

  /// No description provided for @planningGuestSlotScopeBanner.
  ///
  /// In en, this message translates to:
  /// **'Temporary guests — only for this meal, not saved to the family profile. For people who eat with you regularly (young children, live-in grandparents) use Dependents in the family profile.'**
  String get planningGuestSlotScopeBanner;

  /// No description provided for @planningGuestSlotEmpty.
  ///
  /// In en, this message translates to:
  /// **'No guests for this meal yet.'**
  String get planningGuestSlotEmpty;

  /// No description provided for @planningGuestSlotDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this guest from this meal?'**
  String get planningGuestSlotDeleteConfirm;

  /// No description provided for @planningGuestSlotUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated. AI suggestions for this meal may have changed.'**
  String get planningGuestSlotUpdated;

  /// No description provided for @planningGuestSlotCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No guests yet} =1{1 guest} other{{count} guests}}'**
  String planningGuestSlotCount(int count);

  /// No description provided for @healthProfileGender.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get healthProfileGender;

  /// No description provided for @healthProfileGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get healthProfileGenderMale;

  /// No description provided for @healthProfileGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get healthProfileGenderFemale;

  /// No description provided for @healthProfileBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get healthProfileBirthDate;

  /// No description provided for @healthProfileBirthDateChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose date of birth…'**
  String get healthProfileBirthDateChoose;

  /// No description provided for @healthProfileBirthDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Date of birth must be in the past'**
  String get healthProfileBirthDateInvalid;

  /// No description provided for @healthProfileActivityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity level'**
  String get healthProfileActivityLevel;

  /// No description provided for @activityLevelSedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activityLevelSedentary;

  /// No description provided for @activityLevelLight.
  ///
  /// In en, this message translates to:
  /// **'Light (1–3 days/week)'**
  String get activityLevelLight;

  /// No description provided for @activityLevelModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate (3–5 days/week)'**
  String get activityLevelModerate;

  /// No description provided for @activityLevelActive.
  ///
  /// In en, this message translates to:
  /// **'Active (6–7 days/week)'**
  String get activityLevelActive;

  /// No description provided for @activityLevelVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very active (physical work)'**
  String get activityLevelVeryActive;

  /// No description provided for @healthProfileCalorieSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {value} kcal'**
  String healthProfileCalorieSuggestion(int value);

  /// No description provided for @healthProfileCalorieApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get healthProfileCalorieApply;

  /// No description provided for @healthProfileCalorieSuggestionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter height, weight, sex, date of birth and activity level to get a suggestion'**
  String get healthProfileCalorieSuggestionHint;

  /// No description provided for @recipeCardServes.
  ///
  /// In en, this message translates to:
  /// **'{count} servings'**
  String recipeCardServes(int count);

  /// No description provided for @recipesFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get recipesFilterApply;

  /// No description provided for @recipesFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get recipesFilterReset;

  /// No description provided for @recipesFilterMaxMinutes.
  ///
  /// In en, this message translates to:
  /// **'≤ {minutes} min'**
  String recipesFilterMaxMinutes(int minutes);

  /// No description provided for @healthProfileCalorieSuggestionAdultOnly.
  ///
  /// In en, this message translates to:
  /// **'The suggestion formula applies to people aged 18 and over'**
  String get healthProfileCalorieSuggestionAdultOnly;

  /// No description provided for @healthProfileChoiceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid choice, please choose again'**
  String get healthProfileChoiceInvalid;

  /// No description provided for @mealDishRoleStaple.
  ///
  /// In en, this message translates to:
  /// **'Staple'**
  String get mealDishRoleStaple;

  /// No description provided for @mealDishRoleMain.
  ///
  /// In en, this message translates to:
  /// **'Main dish'**
  String get mealDishRoleMain;

  /// No description provided for @mealDishRoleVegetable.
  ///
  /// In en, this message translates to:
  /// **'Vegetable dish'**
  String get mealDishRoleVegetable;

  /// No description provided for @mealDishRoleSoup.
  ///
  /// In en, this message translates to:
  /// **'Soup'**
  String get mealDishRoleSoup;

  /// No description provided for @mealDishRoleCompleteMeal.
  ///
  /// In en, this message translates to:
  /// **'One-dish meal'**
  String get mealDishRoleCompleteMeal;

  /// No description provided for @mealDishRoleLightMeal.
  ///
  /// In en, this message translates to:
  /// **'Light meal'**
  String get mealDishRoleLightMeal;

  /// No description provided for @mealComposeServingsShort.
  ///
  /// In en, this message translates to:
  /// **'{servings} servings'**
  String mealComposeServingsShort(String servings);
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
