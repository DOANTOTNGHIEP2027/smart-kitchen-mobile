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
  String get authForgotPasswordLink => 'Forgot password?';

  @override
  String get authForgotPasswordTitle => 'Reset your password';

  @override
  String get authForgotPasswordHint =>
      'Enter your email and we\'ll send a verification code.';

  @override
  String get authSendResetOtp => 'Send code';

  @override
  String get authResetPasswordTitle => 'Enter code';

  @override
  String get authResetPasswordSubmit => 'Reset password';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authResetSuccess => 'Password updated. Please sign in.';

  @override
  String get authOtpCooldown => 'Please wait before requesting another code.';

  @override
  String get authTooManyAttempts => 'Too many attempts. Try again later.';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

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
  String get healthSavedDialogTitle => 'Health profile saved';

  @override
  String get healthSavedDialogMessage =>
      'Your health profile has been saved successfully.';

  @override
  String get healthSavedDialogConfirm => 'Done';

  @override
  String get cookingAbandonTitle => 'Abandon cooking session?';

  @override
  String get cookingAbandonMessage =>
      'Ingredients will not be deducted from inventory.';

  @override
  String get cookingContinue => 'Continue cooking';

  @override
  String get cookingAbandonAction => 'Abandon';

  @override
  String get cookingLoadFailed => 'Unable to load the cooking session.';

  @override
  String get cookingRetry => 'Retry';

  @override
  String get cookingBack => 'Back';

  @override
  String get cookingAbandonTooltip => 'Abandon cooking session';

  @override
  String cookingStepLabel(int step) {
    return 'Step $step';
  }

  @override
  String get cookingStepUnavailable => 'Step instructions are unavailable.';

  @override
  String get cookingReturnToCurrentStep => 'Return to current step';

  @override
  String get cookingPreviousStep => 'Previous step';

  @override
  String get cookingComplete => 'Complete';

  @override
  String get cookingNextStep => 'Next step';

  @override
  String get cookingCompletedWithShortfall =>
      'Completed — some ingredients were short';

  @override
  String get cookingCompleted => 'Completed!';

  @override
  String get cookingCompletedShortfallDetail =>
      'Inventory was deducted until stock ran out (FIFO). Used ingredients are recorded by deducted quantity.';

  @override
  String get cookingDeductionResult => 'Inventory deduction result:';

  @override
  String get cookingDone => 'Done';

  @override
  String get cookingAbandoned => 'Cooking session abandoned.';

  @override
  String get cookingAbandonedDetail => 'Inventory was not changed.';

  @override
  String get cookingHome => 'Home';

  @override
  String get cookingNoIngredientsToDeduct =>
      'There are no ingredients to deduct (empty recipe).';

  @override
  String cookingDeductionRequired(Object quantity, Object unit) {
    return 'Required: $quantity $unit';
  }

  @override
  String cookingDeducted(Object quantity, Object unit) {
    return 'Deducted: $quantity $unit';
  }

  @override
  String cookingShortfall(Object quantity, Object unit) {
    return 'Shortfall: $quantity $unit';
  }

  @override
  String cookingDeductionLots(int count) {
    return 'From $count stock batches';
  }

  @override
  String get cookingInsufficient => 'Insufficient';

  @override
  String cookingStepProgress(int viewedStep, int totalSteps) {
    return 'Step $viewedStep/$totalSteps';
  }

  @override
  String cookingStepReviewing(int currentStep) {
    return 'Reviewing (current: step $currentStep)';
  }

  @override
  String cookingSuggestedDuration(int minutes) {
    return 'Suggested duration: $minutes minutes';
  }

  @override
  String get cookingPause => 'Pause';

  @override
  String get cookingResume => 'Resume';

  @override
  String get cookingReset => 'Reset';

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

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLogoutAll => 'Log out of all devices';

  @override
  String get profileLogoutConfirm => 'Log out of this device?';

  @override
  String get profileLogoutAllConfirm =>
      'Log out of all devices? You will need to sign in again everywhere.';

  @override
  String get profileLogoutCancel => 'Cancel';

  @override
  String get inventoryTitle => 'Food inventory';

  @override
  String get add => 'Add';

  @override
  String get retry => 'Retry';

  @override
  String get all => 'All';

  @override
  String get cancel => 'Cancel';

  @override
  String get choose => 'Choose';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get delete => 'Delete';

  @override
  String get refresh => 'Refresh';

  @override
  String get skip => 'Skip';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get inventorySyncFailed => 'Could not sync — showing saved data.';

  @override
  String get inventorySearchHint => 'Search by name…';

  @override
  String get inventoryNoHousehold =>
      'You are not in a household yet — create or join one first.';

  @override
  String get inventoryNoResults => 'No matching items found.';

  @override
  String get inventoryEmpty => 'No items yet.';

  @override
  String get inventoryAddItem => 'Add item';

  @override
  String get inventoryChooseUnit => 'Choose unit';

  @override
  String get inventoryDeleteTitle => 'Delete this item?';

  @override
  String get inventoryDeleteMessage =>
      'Choose a reason to record in inventory history.';

  @override
  String get inventoryDeleteCooked => 'Used up';

  @override
  String get inventoryDeleteWaste => 'Expired, spoiled, or discarded';

  @override
  String get inventoryDeleteCorrected => 'Deleted by mistake, correct data';

  @override
  String get inventoryEditItem => 'Edit item';

  @override
  String get inventoryItemName => 'Item name *';

  @override
  String get inventoryItemNameHint => 'e.g. Tomato';

  @override
  String get inventoryQuantity => 'Quantity *';

  @override
  String get inventoryUnit => 'Unit';

  @override
  String get inventoryLowStockOptional => 'Low-stock threshold (optional)';

  @override
  String get inventoryExpiryOptional => 'Expiry date (optional)';

  @override
  String get inventoryChooseDate => 'Choose date…';

  @override
  String get inventoryNoteOptional => 'Note (optional)';

  @override
  String get inventoryAddToInventory => 'Add to inventory';

  @override
  String get inventoryDeleteItem => 'Delete item';

  @override
  String get inventoryUnitRequired => 'Please choose a unit';

  @override
  String get inventoryLowStock => 'Low stock';

  @override
  String get inventoryExpiringSoon => 'Expiring soon';

  @override
  String get inventoryPendingSync => 'Pending sync';

  @override
  String get inventoryConflict => 'Conflict';

  @override
  String get inventoryConflictMessage =>
      'This data was changed by another member. Refreshing…';

  @override
  String get inventoryYours => 'Yours';

  @override
  String get inventoryServer => 'On server';

  @override
  String get inventoryUseServer => 'Use server version';

  @override
  String get inventoryKeepMine => 'Keep mine';

  @override
  String get inventoryName => 'Name';

  @override
  String get inventoryQuantityLabel => 'Quantity';

  @override
  String get inventoryCategory => 'Category';

  @override
  String get inventoryExpiry => 'Expiry';

  @override
  String get inventoryVersion => 'Version';

  @override
  String get mealplanAddDish => 'Add dish';

  @override
  String get mealplanConfirmed => 'Confirmed';

  @override
  String get mealplanAddSuggestion => 'Add suggestion';

  @override
  String get mealplanWaitingForVote => 'Waiting for votes';

  @override
  String get mealplanVoting => 'Voting';

  @override
  String get mealplanSelectedDish => 'Selected dish';

  @override
  String get mealplanAiSuggestion => 'AI suggestion';

  @override
  String get mealplanStartCooking => 'Start cooking';

  @override
  String get mealplanDeleteDishTitle => 'Delete this dish?';

  @override
  String get mealplanDeleteDishMessage =>
      'If there is an active vote, it will be cancelled.';

  @override
  String get mealplanDeleteDish => 'Delete dish';

  @override
  String get mealplanNeedsMore => 'Need to add:';

  @override
  String get mealplanMainIngredientPrefix => '[Main] ';

  @override
  String get mealplanNoReason => 'No reason provided';

  @override
  String get mealplanAiGenerated => 'AI generated';

  @override
  String mealplanContainsAllergens(Object tags) {
    return 'This dish contains: $tags';
  }

  @override
  String get mealplanAllergenUnverified =>
      'Allergens for this dish have not been verified';

  @override
  String get mealplanSuggestionsTitle => 'Meal suggestions';

  @override
  String get mealplanSuggestionsUnavailable =>
      'The session exists, but suggestions could not be reloaded.';

  @override
  String get mealplanSuggestionsExhausted =>
      'You have viewed all suggestions. Wait for votes or try re-rolling.';

  @override
  String get mealplanAddShoppingList => 'Add to shopping list';

  @override
  String get mealplanShoppingListUnavailable =>
      'Shopping lists will be available in a future release.';

  @override
  String get mealplanChooseDish => 'Choose dish';

  @override
  String get mealplanUnableToChoose => 'Could not choose dish';

  @override
  String get mealplanActionRolledBack => 'The action was rolled back.';

  @override
  String get mealplanVoteSession => 'Vote session';

  @override
  String mealplanClosesAt(Object time) {
    return 'Closes at: $time';
  }

  @override
  String get mealplanVoteSuggestionsUnavailable =>
      'The session exists, but suggestions could not be reloaded. Tap Refresh or wait for another member to vote.';

  @override
  String get mealplanNoVotes => 'No votes yet.';

  @override
  String get mealplanVoted => 'Voted';

  @override
  String get mealplanVote => 'Vote';

  @override
  String get mealplanCloseVoting => 'Close voting';
}
