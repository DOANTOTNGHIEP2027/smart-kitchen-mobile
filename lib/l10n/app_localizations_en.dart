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
  String get homeGreeting => 'Good morning';

  @override
  String get homeQuickActions => 'What would you like to do today?';

  @override
  String get homeStartCooking => 'Start cooking';

  @override
  String get homeStartCookingSubtitle =>
      'Choose a dish in your plan to start cooking';

  @override
  String get homeInventoryTitle => 'Food inventory';

  @override
  String get homeInventorySubtitle =>
      'Keep track of ingredients in your kitchen';

  @override
  String get homeMealPlanTitle => 'Meal plan';

  @override
  String get homeMealPlanSubtitle =>
      'Plan and vote on meals with your household';

  @override
  String get homeRecommendedMeals => 'Recommended meals';

  @override
  String get homeRecipeAction => 'View cooking steps';

  @override
  String get homeRecipeDetailTitle => 'Recipe details';

  @override
  String get homeRecipeIngredients => 'Ingredients';

  @override
  String get homeRecipeGuide => 'Recipe source';

  @override
  String get homeRecipeCook => 'Cook this meal';

  @override
  String homeRecipeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String homeRecipeCalories(int calories) {
    return '$calories kcal';
  }

  @override
  String get authEmailExample => 'you@example.com';

  @override
  String get authFullNameExample => 'Alex Johnson';

  @override
  String get householdNameExample => 'The Johnson household';

  @override
  String get inviteCodeExample => 'ABC12345';

  @override
  String get joinDisplayNameExample => 'Household member';

  @override
  String get mealPlanTitle => 'Weekly meal plan';

  @override
  String get mealPlanNoHousehold => 'You do not belong to a household yet.';

  @override
  String get mealPlanLoadFailed => 'Unable to load the meal plan.';

  @override
  String mealPlanWeekRange(
      int startDay, int startMonth, int endDay, int endMonth) {
    return 'Week $startDay/$startMonth – $endDay/$endMonth';
  }

  @override
  String mealPlanDaySchedule(int day, int month) {
    return 'Schedule for $day/$month';
  }

  @override
  String mealPlanDateShort(int day, int month) {
    return '$month/$day';
  }

  @override
  String get mealPlanWeekdayMonday => 'Mon';

  @override
  String get mealPlanWeekdayTuesday => 'Tue';

  @override
  String get mealPlanWeekdayWednesday => 'Wed';

  @override
  String get mealPlanWeekdayThursday => 'Thu';

  @override
  String get mealPlanWeekdayFriday => 'Fri';

  @override
  String get mealPlanWeekdaySaturday => 'Sat';

  @override
  String get mealPlanWeekdaySunday => 'Sun';

  @override
  String get mealPlanBreakfast => 'Breakfast';

  @override
  String get mealPlanLunch => 'Lunch';

  @override
  String get mealPlanDinner => 'Dinner';

  @override
  String mealPlanOpenVotes(int count) {
    return '$count open vote sessions';
  }

  @override
  String get mealPlanTapToAdd => 'Tap to add a dish';

  @override
  String get mealPlanSelectingDish => 'Choosing a dish';

  @override
  String get mealPlanDishUnselected => 'No dish selected';

  @override
  String get mealPlanAddDish => 'Add dish';

  @override
  String get mealPlanAddDishFailed =>
      'Unable to add the dish. Please try again.';

  @override
  String get mealPlanOpenSuggestionsFailed =>
      'Unable to open meal suggestions. Please try again.';

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

  @override
  String get profileTitle => 'My profile';

  @override
  String get profileEmailMissing => 'Email not set';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileEditBlocked =>
      'This feature is being completed. It will be available soon.';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSavedToast => 'Profile updated';

  @override
  String get healthProfileTitle => 'Health profile';

  @override
  String get healthProfileEmpty =>
      'Not set up yet — fill in to get personalized suggestions.';

  @override
  String get healthProfileTargetCalories => 'Daily calorie goal';

  @override
  String get healthProfileDietType => 'Diet type';

  @override
  String get healthProfileHeight => 'Height (cm)';

  @override
  String get healthProfileWeight => 'Weight (kg)';

  @override
  String get healthProfileAllergensSection => 'Allergens';

  @override
  String get healthProfileAllergensEmpty => 'No allergens selected.';

  @override
  String get healthProfileAllergensEdit => 'Edit allergens';

  @override
  String get healthSave => 'Save health profile';

  @override
  String get healthSavedToast => 'Health profile saved';

  @override
  String get allergensTitle => 'My allergens';

  @override
  String get allergensCatalogEmpty => 'Allergen catalog unavailable.';

  @override
  String get allergensSelectNone => 'None known';

  @override
  String get allergensSave => 'Save allergens';

  @override
  String get allergensSavedToast => 'Allergens updated';

  @override
  String get dietTypeNone => 'None';

  @override
  String get dietTypeKeto => 'Keto';

  @override
  String get dietTypeVegetarian => 'Vegetarian';

  @override
  String get dietTypeVegan => 'Vegan';

  @override
  String get dietTypePescatarian => 'Pescatarian';

  @override
  String get dietTypeGlutenFree => 'Gluten free';

  @override
  String get dietTypeDiabetic => 'Diabetic';

  @override
  String get familyTitle => 'Family';

  @override
  String get familyRosterEmpty => 'No other members yet.';

  @override
  String get familyCreateInvite => 'Create invite';

  @override
  String get familyRemove => 'Remove from household';

  @override
  String get familyRemoveConfirm => 'Remove this member from the household?';

  @override
  String get familyRemoveCancel => 'Cancel';

  @override
  String get familyYou => 'You';

  @override
  String get familyInviteRateLimited => 'You already have 3 active invites.';

  @override
  String get memberDetailTitle => 'Member';

  @override
  String get memberDetailDietType => 'Diet type';

  @override
  String get memberDetailAllergensSection => 'Allergens';

  @override
  String get memberDetailAllergensEmpty => 'No allergens registered.';

  @override
  String get staleDataBanner =>
      'Data may be out of date — showing the latest saved copy.';
}
