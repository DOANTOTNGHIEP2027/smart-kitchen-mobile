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
  String get healthProfileAllergensEmpty => 'No allergen entries saved';

  @override
  String get healthProfileAllergensEdit => 'Edit allergens';

  @override
  String get healthSave => 'Save health profile';

  @override
  String get healthSavedToast => 'Health profile saved';

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
  String get cookingShortfallTitle => 'Not enough ingredients in stock';

  @override
  String get cookingShortfallMessage =>
      'Nothing has been deducted from inventory yet. Restock and tap Complete again, or complete now — inventory will be deducted as far as it goes.';

  @override
  String cookingShortfallLine(
      String required, String available, String shortfall, String unit) {
    return 'Need $required · Have $available · Short $shortfall $unit';
  }

  @override
  String get cookingShortfallNoDetail =>
      'The list of missing ingredients is unavailable.';

  @override
  String get cookingShortfallConfirm =>
      'Complete anyway (deduct what is in stock)';

  @override
  String get cookingShortfallBack => 'Back to cooking';

  @override
  String get cookingUnitGram => 'g';

  @override
  String get cookingUnitMilliliter => 'ml';

  @override
  String get cookingUnitPiece => 'pcs';

  @override
  String get cookingUnitUnit => 'units';

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
  String get cookingAssistTitle => 'Cooking assistant';

  @override
  String get cookingAssistHint => 'Ask about this step, substitutes, servings…';

  @override
  String get cookingAssistGreeting => 'How can I help with this step?';

  @override
  String get cookingAssistSend => 'Send';

  @override
  String get cookingAssistSending => 'answering…';

  @override
  String get cookingAssistSlow => 'This question needs a little more time';

  @override
  String get cookingAssistOffline =>
      'You\'re offline — the assistant needs a connection';

  @override
  String get cookingAssistBusy => 'The assistant is busy, try again later';

  @override
  String get cookingAssistRetry => 'Try again';

  @override
  String get cookingAssistFiltered => 'Can\'t answer this question.';

  @override
  String get cookingAssistUnavailable =>
      'The assistant isn\'t available for this cooking session. You can keep cooking as usual.';

  @override
  String get cookingAssistInStock => 'In your pantry';

  @override
  String get cookingAssistUnverified => 'Suggestion not checked for allergens';

  @override
  String get cookingAssistGuestsUnknown =>
      'Guests\' allergies are not taken into account';

  @override
  String get cookingAssistBlocked => 'Not suggested because of allergies';

  @override
  String get cookingAssistFoodSafety =>
      'Check doneness and food safety yourself.';

  @override
  String get cookingAssistDegraded => 'Short answer — the assistant is limited';

  @override
  String cookingAssistStepChip(int step) {
    return 'Step $step';
  }

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
  String get familyRemove => 'Remove from household';

  @override
  String familyRemoveConfirm(String name) {
    return 'Remove $name from the household?';
  }

  @override
  String get familyRemoveCancel => 'Cancel';

  @override
  String get familyYou => 'You';

  @override
  String get memberDetailTitle => 'Member';

  @override
  String get memberDetailDietType => 'Diet type';

  @override
  String get memberDetailAllergensSection => 'Allergens';

  @override
  String get memberDetailAllergensEmpty => 'No allergen entries saved';

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
  String get syncIdempotencyKeyReused =>
      'An add action was already sent with different content — please check the list again.';

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
  String get mealplanDeleteDishMessage => 'Remove this dish from the meal?';

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
      'Could not load suggestions. Retry or choose a recipe.';

  @override
  String get mealplanSuggestionsExhausted =>
      'No suggestions to choose. Generate suggestions to continue.';

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
  String get mealplanActionRolledBack =>
      'Selection was not saved. Refresh suggestions and retry.';

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

  @override
  String get recipesTitle => 'Recipes';

  @override
  String get recipesAll => 'All recipes';

  @override
  String get recipesFavorites => 'Favorites';

  @override
  String get recipesSearch => 'Search recipes…';

  @override
  String get recipesFilters => 'Filters';

  @override
  String get recipesFilterDiet => 'Diet type';

  @override
  String get recipesFilterDifficulty => 'Difficulty';

  @override
  String get recipesFilterPrepTime => 'Preparation time';

  @override
  String get recipesNoResults => 'No matching recipes found.';

  @override
  String get recipesNoFavorites =>
      'You have not saved any favorite recipes yet.';

  @override
  String get recipesLoadMore => 'Load more';

  @override
  String get recipesListChanged => 'Your favorites list has changed.';

  @override
  String get recipesReload => 'Reload list';

  @override
  String get recipeIngredients => 'Ingredients';

  @override
  String get recipeSteps => 'Cooking steps';

  @override
  String get recipeNutrition => 'Nutrition per serving';

  @override
  String recipePrepTime(int minutes) {
    return 'Prep: $minutes min';
  }

  @override
  String recipeCookTime(int minutes) {
    return 'Cook: $minutes min';
  }

  @override
  String recipeServes(int count) {
    return 'Serves $count';
  }

  @override
  String get recipeDifficulty => 'Difficulty';

  @override
  String get recipeDifficultyEasy => 'Easy';

  @override
  String get recipeDifficultyMedium => 'Medium';

  @override
  String get recipeDifficultyHard => 'Hard';

  @override
  String get recipeStartCooking => 'Start cooking';

  @override
  String get recipeNoSteps =>
      'Cooking steps are not available for this recipe.';

  @override
  String get recipeYourRating => 'Your rating';

  @override
  String get recipeClearRating => 'Clear rating';

  @override
  String recipeHouseholdFavorites(int count) {
    return 'Saved by $count household members';
  }

  @override
  String get inventoryHistoryTitle => 'Inventory history';

  @override
  String get inventoryHistoryOpen => 'View change history';

  @override
  String inventoryHistoryCurrentQuantity(Object quantity, Object unit) {
    return 'Currently $quantity $unit';
  }

  @override
  String get inventoryHistoryLoadFailed => 'Unable to load inventory history.';

  @override
  String get inventoryHistoryEmpty =>
      'No changes have been recorded for this item yet.';

  @override
  String get inventoryHistoryLoadMore => 'Load more';

  @override
  String inventoryHistoryRemaining(Object quantity) {
    return 'Left $quantity';
  }

  @override
  String get inventoryHistoryReasonBought => 'Added to inventory';

  @override
  String get inventoryHistoryReasonCooked => 'Used';

  @override
  String get inventoryHistoryReasonExpired => 'Expired';

  @override
  String get inventoryHistoryReasonWaste => 'Discarded';

  @override
  String get inventoryHistoryReasonCorrected => 'Data correction';

  @override
  String get inventoryWasteTitle => 'Why was this food discarded?';

  @override
  String get inventoryWasteSubtitle =>
      'Choose one reason to help your household reduce waste.';

  @override
  String get inventoryWasteOverbought => 'Bought too much';

  @override
  String get inventoryWasteForgotten => 'Forgotten until expired';

  @override
  String get inventoryWasteSpoiledEarly => 'Spoiled before expiry';

  @override
  String get inventoryWasteUntagged => 'Cause not recorded';

  @override
  String get notificationInventoryUpdated => 'Inventory updated';

  @override
  String get notificationInventoryAlreadyUsed =>
      'This item was already marked as used';

  @override
  String get notificationInventoryAlreadyDiscarded =>
      'This item was already discarded';

  @override
  String get notificationInventoryAlreadyProcessed =>
      'This item was already processed';

  @override
  String get notificationInventoryGone => 'This item is no longer in inventory';

  @override
  String get notificationInventoryReadonly =>
      'Your account has view-only access';

  @override
  String get notificationNoNetwork => 'No connection — try again';

  @override
  String get notificationActionFailed =>
      'The notification action could not be completed';

  @override
  String get notificationActionCookToday => 'Cook today';

  @override
  String get notificationActionMarkUsed => 'Used';

  @override
  String get notificationActionDiscard => 'Discard';

  @override
  String get notificationQuickActionProcessing => 'Updating inventory…';

  @override
  String get notificationQuickActionSessionExpired =>
      'Your session has expired — tap to sign in';

  @override
  String get notificationQuickActionOpenApp => 'Tap to open the app';

  @override
  String get notificationQuickActionRetry => 'Couldn\'t complete — try again';

  @override
  String get inventoryOcrScanAction => 'Scan receipt or items';

  @override
  String get inventoryOcrScanTitle => 'Scan items into inventory';

  @override
  String get inventoryOcrModeItem => 'Single item';

  @override
  String get inventoryOcrModeReceipt => 'Receipt / fridge';

  @override
  String get inventoryOcrFrameHint =>
      'Place the item or receipt clearly inside the frame';

  @override
  String get inventoryOcrItemHint =>
      'Photograph one item clearly for the most accurate result';

  @override
  String get inventoryOcrReceiptHint =>
      'Keep the full receipt or fridge contents visible and well lit';

  @override
  String get inventoryOcrTakePhoto => 'Take photo';

  @override
  String get inventoryOcrChooseGallery => 'Choose from gallery';

  @override
  String get inventoryOcrChooseAnother => 'Choose another image';

  @override
  String get inventoryOcrAnalyzing => 'Analyzing image…';

  @override
  String get inventoryOcrPermissionDenied =>
      'Camera or photo access has not been granted. Open Settings to allow access.';

  @override
  String get inventoryOcrImageTooLarge =>
      'The image is still over 2 MB after compression. Please choose another image.';

  @override
  String get inventoryOcrImageInvalid =>
      'This image could not be read. Please choose a valid JPEG or PNG image.';

  @override
  String get inventoryOcrAiTimeout =>
      'The AI took too long to respond. Your image is still available to retry.';

  @override
  String get inventoryOcrAiUnavailable =>
      'The AI service is temporarily unavailable. Your image is still available to retry.';

  @override
  String get inventoryOcrAiRateLimit =>
      'The AI service is busy. Please wait a moment and retry.';

  @override
  String get inventoryOcrContentFiltered =>
      'This image cannot be analyzed. Please choose another image.';

  @override
  String get inventoryOcrInvalidOutput =>
      'The AI could not produce a usable result from this image. Please choose another image.';

  @override
  String get inventoryOcrScanInProgress =>
      'The previous image is still being processed. Please wait a few seconds.';

  @override
  String get inventoryOcrNoHousehold =>
      'Join or create a household before scanning inventory.';

  @override
  String inventoryOcrResultTitle(int count) {
    return 'Scan results ($count)';
  }

  @override
  String get inventoryOcrConfirmAll => 'Confirm all';

  @override
  String get inventoryOcrEmpty =>
      'AI did not recognize any items in this image';

  @override
  String get inventoryOcrRetake => 'Take another photo';

  @override
  String get inventoryOcrNeedsReview => 'Needs review';

  @override
  String get inventoryOcrDuplicate => 'Already in inventory';

  @override
  String inventoryOcrExpiryEstimate(Object date) {
    return 'Expires $date · AI estimate';
  }

  @override
  String inventoryOcrRawValue(Object quantity, Object unit) {
    return 'Detected from image: $quantity $unit';
  }

  @override
  String get inventoryOcrQuantityHint => 'Enter quantity';

  @override
  String get inventoryOcrQuantityInvalid => 'Enter a valid quantity';

  @override
  String get inventoryOcrCompleteFields =>
      'Enter a valid quantity and unit before saving';

  @override
  String get inventoryOcrSaveItem => 'Save this item';

  @override
  String get inventoryOcrSaved => 'Saved';

  @override
  String inventoryOcrSavingProgress(int saved, int total) {
    return 'Saving $saved/$total…';
  }

  @override
  String inventoryOcrPartialFailure(int count) {
    return '$count items could not be saved — retry or skip them below';
  }

  @override
  String get mealLogTitle => 'Meal Log';

  @override
  String get mealLogToday => 'Today';

  @override
  String get mealLogEmpty => 'No meal logged today yet';

  @override
  String get mealLogLogMeal => 'Log a meal';

  @override
  String get mealLogSaving => 'Saving…';

  @override
  String get mealLogSaveFailed => 'Failed to save';

  @override
  String get mealLogRetry => 'Retry';

  @override
  String get mealLogDelete => 'Delete';

  @override
  String get mealLogNeedsReview => 'Needs review';

  @override
  String get mealLogNoEstimate => 'No estimate';

  @override
  String get mealLogConfirm => 'Confirm';

  @override
  String get mealLogConfirmed => 'Confirmed';

  @override
  String mealLogCalories(double calories) {
    return '$calories kcal';
  }

  @override
  String mealLogGoalRemaining(int remaining) {
    return '$remaining kcal left today';
  }

  @override
  String get mealLogSetCalorieGoal => 'Set calorie goal';

  @override
  String get mealLogMealType => 'Meal type';

  @override
  String get mealLogBreakfast => 'Breakfast';

  @override
  String get mealLogLunch => 'Lunch';

  @override
  String get mealLogDinner => 'Dinner';

  @override
  String get mealLogSnack => 'Snack';

  @override
  String get mealLogDescriptionHint => 'What did you eat? (optional)';

  @override
  String get mealLogAddPhoto => 'Add photo';

  @override
  String get mealLogPhotoTooLarge =>
      'Photo is still too large after compression — choose another';

  @override
  String get mealLogChooseAnother => 'Choose another photo';

  @override
  String get mealLogCameraPermissionDenied =>
      'Camera/library permission was denied. Enable it in settings to add a photo.';

  @override
  String get mealLogPhotoInvalid =>
      'Could not read the photo. Choose a different one.';

  @override
  String get mealLogConfirmTitle => 'Confirm calories';

  @override
  String get mealLogConfirmAsIs => 'Accept as estimated';

  @override
  String get mealLogEnterCalories => 'Enter calories';

  @override
  String get mealLogCaloriesInvalid => 'Enter a value between 0 and 10000';

  @override
  String get mealLogCaloriesRequired => 'Enter calories first';

  @override
  String get insightsTitleCalorie => 'Calories';

  @override
  String get insightsTitleMacro => 'Macro';

  @override
  String get insightsTitleAdherence => 'Adherence';

  @override
  String insightsMonthLabel(Object month, Object year) {
    return 'Month $month/$year';
  }

  @override
  String get insightsEmptyDiary => 'No meals logged in this month yet';

  @override
  String get insightsEmptyAdherence =>
      'The household has no adherence data yet';

  @override
  String get insightsSetCalorieGoal => 'Set calorie goal';

  @override
  String get insightsRetry => 'Retry';

  @override
  String get insightsLast7Days => 'Last 7 days';

  @override
  String insightsAvgCalories(Object calories) {
    return 'Avg $calories kcal/day';
  }

  @override
  String insightsLoggedCount(Object count) {
    return '$count meals logged';
  }

  @override
  String insightsStreakText(Object best, Object current) {
    return '$current weeks in a row · Best $best';
  }

  @override
  String get insightsNoWeekData => 'No data for this week';

  @override
  String insightsAdherenceStart(Object day, Object month, Object percent) {
    return '$percent% — from $day/$month';
  }

  @override
  String insightsKcalPerDay(Object calories) {
    return '$calories kcal';
  }

  @override
  String get insightsHistoryTooltip => 'Nutrition trends';

  @override
  String insightsCalorieTooltip(Object calories, Object day, Object month) {
    return '$day/$month — $calories kcal';
  }

  @override
  String get recapTitle => 'Weekly Recap';

  @override
  String get recapNoHousehold => 'Join a household to view Weekly Recap';

  @override
  String get recapEmpty =>
      'No recap yet for this week — the first recap will arrive on Monday morning of next week.';

  @override
  String get recapError => 'Could not load data';

  @override
  String get recapHeroFallback =>
      'No personalized insight for you this week yet. Keep logging meals to get a more detailed insight next week!';

  @override
  String recapStreak(Object current) {
    return '$current weeks';
  }

  @override
  String recapStreakBest(Object best) {
    return 'Best $best';
  }

  @override
  String recapMealsLogged(Object count) {
    return '$count meals logged';
  }

  @override
  String recapAvgCalories(Object calories) {
    return '$calories kcal/day';
  }

  @override
  String get recapAdherenceCaption =>
      'Meal plan adherence — different from personal calorie compliance below';

  @override
  String get recapEmptyInsights => 'No personalized insight yet for this week.';

  @override
  String recapNutrientGap(Object nutrient) {
    return 'Watch out: $nutrient';
  }

  @override
  String get recapShare => 'My household\'s Weekly Recap on Smart Kitchen!';

  @override
  String get recapShareFailed =>
      'Could not share the image, please try again later';

  @override
  String get recapShareTooltip => 'Share recap';

  @override
  String get recapStreakError => 'Could not load streak';

  @override
  String get recapStreakRetry => 'Retry streak';

  @override
  String get planningSlotConfigTitle => 'Meal times';

  @override
  String get planningSlotConfigTooltip => 'Configure meal times';

  @override
  String get planningSlotEveryDay => 'Every day';

  @override
  String get planningSlotByDay => 'Extra meals for one day';

  @override
  String get planningSlotByDayHint =>
      'Meals here are ADDED on top of \"Every day\", they don\'t replace it.';

  @override
  String get planningSlotDefaultBanner =>
      'Your household uses the 3 default meals (07:00 / 12:00 / 18:00). Edit below to customise.';

  @override
  String get planningSlotNotRetroactive =>
      'Changes only apply to meals created from now on — existing weekly plans are not affected.';

  @override
  String get planningSlotAdd => 'Add meal';

  @override
  String get planningSlotEmptyDay => 'No extra meals for this day.';

  @override
  String get planningSlotSave => 'Save';

  @override
  String get planningSlotSaved => 'Meal times saved';

  @override
  String get planningSlotSaveFailed => 'Could not save meal times.';

  @override
  String get planningSlotErrorEmpty => 'Keep at least one meal.';

  @override
  String get planningSlotErrorTooMany => 'At most 10 meals per household.';

  @override
  String get planningSlotErrorDuplicate =>
      'Two meals have the same type in one day group.';

  @override
  String get planningSlotErrorBlankLabel => 'Meal name must not be empty.';

  @override
  String get planningSlotFormAddTitle => 'Add meal';

  @override
  String get planningSlotFormEditTitle => 'Edit meal';

  @override
  String get planningSlotFormType => 'Meal type';

  @override
  String get planningSlotFormLabel => 'Meal name';

  @override
  String get planningSlotFormTime => 'Time';

  @override
  String get planningSlotTypeBreakfast => 'Breakfast';

  @override
  String get planningSlotTypeLunch => 'Lunch';

  @override
  String get planningSlotTypeDinner => 'Dinner';

  @override
  String get planningSlotTypeSnack => 'Snack';

  @override
  String get planningSlotTypeCustom => 'Custom';

  @override
  String get planningSlotEdit => 'Edit';

  @override
  String get planningConfirm => 'Confirm';

  @override
  String get planningGuestTitle => 'Guest diners';

  @override
  String get planningGuestTooltip => 'Guest diners this week';

  @override
  String get planningGuestScopeBanner =>
      'Temporary guests — they apply to this week\'s meal plan only and are not saved to the family profile. For people who eat with you regularly, use Dependants in the family profile.';

  @override
  String get planningGuestEmpty => 'No guests for this week yet.';

  @override
  String get planningGuestAdd => 'Add guest';

  @override
  String get planningGuestUnnamed => 'Unnamed guest';

  @override
  String get planningGuestNoAllergen => 'No allergies';

  @override
  String get planningGuestNameOptional => 'Guest name (optional)';

  @override
  String get planningGuestAllergens => 'Allergies';

  @override
  String get planningGuestCatalogFailed => 'Could not load the allergen list.';

  @override
  String get planningGuestEditAllergens => 'Edit allergies';

  @override
  String get planningGuestDelete => 'Remove guest';

  @override
  String get planningGuestDeleteConfirm =>
      'Remove this guest from this week\'s plan?';

  @override
  String planningGuestRemovedHint(String name) {
    return 'Removed $name. Dishes blocked earlier are NOT unblocked automatically — generate new suggestions if you want to try again.';
  }

  @override
  String get planningGuestUpdated =>
      'Updated. AI suggestions for this week may have changed.';

  @override
  String get planningGuestSave => 'Save';

  @override
  String get planningCandidateTitle => 'Verified AI suggestions';

  @override
  String get planningCandidateTooltip => 'Verified AI suggestions';

  @override
  String get planningCandidateExplainer =>
      'The list shows allergy check results, scores and suggestion signals. ⭐ marks the algorithm\'s recommendation; repetition is an advisory signal.';

  @override
  String get planningCandidateEmpty => 'No suggestions for this dish yet.';

  @override
  String get planningCandidateEmptyWeek =>
      'No AI suggestions this week yet. Open a dish and pick suggestions to generate them.';

  @override
  String get planningCandidateGenerate => 'Generate AI suggestions';

  @override
  String get planningCandidateGenerateFailed =>
      'Could not generate suggestions.';

  @override
  String get planningCandidateAllBlocked =>
      'All suggestions are blocked by allergies. Try removing some guests from the constraints, or pick a dish manually.';

  @override
  String get planningCandidateAiLabel => 'AI suggestion';

  @override
  String get planningCandidateFinalPick =>
      'Final pick — confirmed by the algorithm';

  @override
  String get planningCandidatePassed =>
      'Passed safety checks — not the top pick';

  @override
  String planningCandidateBlocked(String reason) {
    return 'Excluded — $reason';
  }

  @override
  String get planningCandidateUnverified =>
      'Allergies NOT verified — this suggestion was never checked by the safety filter';

  @override
  String get planningCandidateBlockedUnknown => 'unverified allergy';

  @override
  String planningCandidateScore(String score) {
    return 'Score $score';
  }

  @override
  String get planningCandidateBreakdown => 'Suggestion signals';

  @override
  String planningCandidateWeight(String weight) {
    return 'weight $weight';
  }

  @override
  String get planningCandidateNoBreakdown =>
      'No suggestion signal data is available.';

  @override
  String planningCandidateSession(String time) {
    return 'Suggestion session · $time';
  }

  @override
  String get planningFeatureInventoryCoverage => 'Ingredients on hand';

  @override
  String get planningFeatureExpiryUrgency => 'Expiring food';

  @override
  String get planningFeatureRepetitionPenalty => 'Planned repetition signal';

  @override
  String get planningFeatureNutritionFit => 'Nutrition fit';

  @override
  String get planningFeatureDietMatch => 'Diet match';

  @override
  String get planningFeatureEffortFit => 'Effort fit';

  @override
  String get planningFeaturePreference => 'Preference';

  @override
  String get planningFeaturePrior => 'Base priority';

  @override
  String get planningFeatureNutrientBalance => 'Nutrient balance';

  @override
  String get planningFeatureRiskPenalty => 'Nutrient risk';

  @override
  String get planningFeatureConstraintMatch => 'Constraint match';

  @override
  String get planningFeatureGraphPath => 'Knowledge-graph evidence';

  @override
  String get planningRepetitionTitle => 'Repeated dishes in the plan';

  @override
  String get planningRepetitionTooltip => 'View planned dish repetition';

  @override
  String planningRepetitionWindow(int days) {
    return '$days-day lookback';
  }

  @override
  String planningRepetitionEmpty(int days) {
    return 'No assigned dish repeats from $days days ago through today.';
  }

  @override
  String planningRepetitionCount(int count) {
    return 'Assigned $count times';
  }

  @override
  String get tierFree => 'Free';

  @override
  String get tierPremium => 'Premium';

  @override
  String get tierUnknown => 'Unknown';

  @override
  String tierPlanCurrent(String tier) {
    return 'Current plan: $tier';
  }

  @override
  String tierSeatUsage(int used, int limit) {
    return '$used/$limit view-only seats';
  }

  @override
  String get tierChangePlan => 'Upgrade / Downgrade';

  @override
  String get tierOwnerOnlyTooltip =>
      'Only the household owner can change the plan';

  @override
  String get tierViewerOnlyTooltip =>
      'You are in view-only mode — only the household owner can change the plan';

  @override
  String get tierRemoteViewerBanner =>
      'You are in view-only mode (Remote Viewer) in this household — you cannot invite, remove or change roles of members. Contact the owner if you need different permissions.';

  @override
  String get tierRoleViewOnly => 'View only';

  @override
  String get tierChangeRoleAction => 'Change role';

  @override
  String tierChangeRoleTitle(String name) {
    return 'Change role — $name';
  }

  @override
  String get tierChangeRoleMember =>
      'Member — view, vote and edit the inventory as usual';

  @override
  String get tierChangeRoleViewer =>
      'View only (Remote Viewer) — no voting, no inventory edits, no member management';

  @override
  String tierChangeRoleSoftHint(String tier, int used, int limit) {
    return 'The $tier plan already uses $used/$limit view-only seats. You can still try — if the limit is exceeded, you will be offered an upgrade.';
  }

  @override
  String get tierConfirm => 'Confirm';

  @override
  String get tierChangeRoleSuccess => 'Role changed';

  @override
  String get tierUpsellTitle => 'View-only seats are full';

  @override
  String tierUpsellBody(int limit) {
    return 'Your current plan allows $limit view-only seat(s). Upgrade to Premium for up to 5.';
  }

  @override
  String tierUpsellBodyMaxed(int limit) {
    return 'Your plan already uses all $limit view-only seats. Change someone back to Member to free a seat.';
  }

  @override
  String get tierUpgradeToPremium => 'Upgrade to Premium';

  @override
  String get tierDowngradeToFree => 'Downgrade to Free';

  @override
  String get tierClose => 'Close';

  @override
  String get tierUpgradeTitle => 'Household plan';

  @override
  String get tierDisclaimer =>
      'This is NOT a real purchase. It is a demo/QA switch to try the tier-gate flow. In a real release this will be replaced by an authenticated payment flow.';

  @override
  String get tierOwnerOnlyBlocked =>
      'Only the household owner (OWNER) can change the household plan.';

  @override
  String get tierCompareFree => 'Free — 1 view-only seat';

  @override
  String get tierComparePremium => 'Premium — 5 view-only seats';

  @override
  String get tierCompareSpend =>
      'Spending by category + 8-week trend: Free ✗ / Premium ✓';

  @override
  String tierDowngradeWarning(int used) {
    return 'The household has $used view-only members, above the Free limit (1). Existing ones are NOT affected right away, but you cannot add new ones until you reduce the number or upgrade again.';
  }

  @override
  String get tierRosterFailed =>
      'Could not load the member list — the view-only seat warning for downgrading may be missing.';

  @override
  String get tierUnknownBody =>
      'Could not determine the current plan — please try reloading.';

  @override
  String get tierRetryLoad => 'Try reloading';

  @override
  String get tierRetryFailed => 'Still unknown — please sign in again.';

  @override
  String tierConfirmTitle(String tier) {
    return 'Switch to $tier?';
  }

  @override
  String tierUpdated(String tier) {
    return 'Household plan updated to $tier';
  }

  @override
  String get tierMemberViewerInfo =>
      'Role: View only (Remote Viewer) — no voting, no inventory edits, no member management.';

  @override
  String get budgetLoading => 'Loading budget…';

  @override
  String get budgetLoadFailed => 'Could not load the budget';

  @override
  String get budgetNotSet => 'No budget set for this household yet';

  @override
  String budgetCurrentWeekly(String amount) {
    return 'Weekly budget: $amount';
  }

  @override
  String budgetCurrentMonthly(String amount) {
    return 'Monthly budget: $amount';
  }

  @override
  String get budgetSet => 'Set budget';

  @override
  String get budgetEdit => 'Edit';

  @override
  String get budgetOwnerOnlyTooltip =>
      'Only the household owner can set the budget';

  @override
  String get budgetLoadingTooltip => 'Loading the current budget…';

  @override
  String get budgetUpsell =>
      'See spending by category & 8-week trend with Premium';

  @override
  String get budgetSheetTitle => 'Household budget';

  @override
  String get budgetPeriodWeek => 'Week';

  @override
  String get budgetPeriodMonth => 'Month';

  @override
  String get budgetAmountLabel => 'Amount';

  @override
  String get budgetAmountInvalid =>
      'Enter an amount greater than 0 and at most 999,999,999,999';

  @override
  String get budgetNotRetroactive =>
      'The budget applies to UPCOMING weeks. Recaps of weeks already summarised keep the budget at that time.';

  @override
  String get budgetSave => 'Save';

  @override
  String get budgetUpdated => 'Budget updated';

  @override
  String get recapWasteSpendTitle => 'Waste & spending';

  @override
  String recapWeekRange(String start, String end) {
    return 'Monday $start – Sunday $end';
  }

  @override
  String get recapWasteTitle => 'Waste this week';

  @override
  String recapWasteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items thrown away',
      one: '1 item thrown away',
    );
    return '$_temp0';
  }

  @override
  String get recapWasteNone =>
      '🎉 Your household threw nothing away this week. Keep it up!';

  @override
  String get recapWasteOverbought => 'Overbought';

  @override
  String get recapWasteForgotten => 'Forgotten in the fridge';

  @override
  String get recapWasteSpoiledEarly => 'Spoiled early';

  @override
  String get recapWasteUntagged => 'No reason given';

  @override
  String get recapWasteOther => 'Other';

  @override
  String get recapSpendTitle => 'Spending this week';

  @override
  String get recapSpendNone => 'No item has a price entered this week';

  @override
  String get recapSpendNoneHint =>
      'Enter the price when you tick an item done on the shopping list to see spending here.';

  @override
  String recapSpendOfBudget(String spent, String budget) {
    return '$spent / $budget';
  }

  @override
  String recapSpendPercent(int percent) {
    return '$percent% of the weekly budget';
  }

  @override
  String recapSpendOver(int percent, String amount) {
    return '$percent% of the weekly budget · Over by $amount';
  }

  @override
  String recapSpendCoverage(int priced, int completed) {
    return '$priced/$completed items have a price';
  }

  @override
  String get recapSetBudget => 'Set budget';

  @override
  String get recapNoBudgetMember =>
      'The owner has not set a budget for this household';

  @override
  String recapBudgetConvertedMonthly(String amount) {
    return 'The monthly budget ($amount) has been converted to a weekly amount.';
  }

  @override
  String recapBudgetConvertedOther(String amount) {
    return 'Your budget ($amount) has been converted to a weekly amount.';
  }

  @override
  String get recapSpendByCategory => 'Spending by category';

  @override
  String get recapSpendTrend => '8-week trend';

  @override
  String get recapUncategorized => 'Uncategorized';

  @override
  String get recapSpendCategoryEmpty => 'No priced spending this week yet';

  @override
  String get recapSpendUpsell =>
      'See spending by category and the 8-week trend with Premium';

  @override
  String get recapUpgradePremium => 'Upgrade to Premium';

  @override
  String get recapSpendDetailNeutral => 'No detailed data for this week yet.';

  @override
  String get shoppingEmptyTitle => 'Your shopping list is empty';

  @override
  String get shoppingEmptyBody =>
      'Add groceries you need, or plan this week\'s menu to build the list automatically.';

  @override
  String get shoppingAddNeeded => 'Add something to buy';

  @override
  String shoppingPendingCount(int count) {
    return 'To buy ($count)';
  }

  @override
  String shoppingCompletedCount(int count) {
    return 'Bought ($count)';
  }

  @override
  String shoppingFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String get shoppingAllBought => 'Great! Everything has been bought.';

  @override
  String get shoppingNoneBought => 'Nothing has been marked as bought yet.';

  @override
  String get shoppingAddItem => 'Add item';

  @override
  String get shoppingProgressTitle => 'Shopping progress';

  @override
  String shoppingProgressDetail(int completed, int total, int percent) {
    return '$completed / $total items done ($percent%)';
  }

  @override
  String shoppingPendingBadge(int count) {
    return '$count to buy';
  }

  @override
  String get shoppingWeeklyMenuBadge => 'Weekly menu';

  @override
  String get shoppingAddSheetTitle => 'Add item to buy';

  @override
  String get shoppingNameHint => 'Food or ingredient name...';

  @override
  String get shoppingNameLabel => 'Item name';

  @override
  String get shoppingQuantityLabel => 'Quantity';

  @override
  String get shoppingUnitLabel => 'Unit';

  @override
  String get shoppingCategoryLabel => 'Category';

  @override
  String get shoppingAddToList => 'Add to list';

  @override
  String get dependentListTitle => 'Dependents';

  @override
  String get dependentAddProfile => 'Add profile';

  @override
  String get dependentLoadFailed => 'Could not load the dependents list.';

  @override
  String get dependentEmptyTitle => 'No dependents yet';

  @override
  String get dependentEmptyBody =>
      'Add a profile for a young child or a dependent relative so the app can automatically handle allergies and suitable diets.';

  @override
  String get dependentAllergenInfo =>
      'The app automatically excludes allergenic ingredients when suggesting menus for dependents.';

  @override
  String dependentAgeAndBirth(int age, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age years old',
      one: '1 year old',
    );
    return '$_temp0 · Born $date';
  }

  @override
  String dependentAllergenChip(String name) {
    return 'Allergy: $name';
  }

  @override
  String get dependentNoAllergens => 'No allergies recorded';

  @override
  String get dependentProfileNav => 'Dependent profiles';

  @override
  String get dependentFormTitle => 'Add dependent';

  @override
  String get dependentNameRequired => 'Please enter the dependent\'s name';

  @override
  String get dependentSaveFailed =>
      'Something went wrong while saving the profile';

  @override
  String get dependentNameLabel => 'Full name or nickname *';

  @override
  String get dependentNameHint => 'E.g. Baby An, Grandpa...';

  @override
  String get dependentDateOfBirth => 'Date of birth';

  @override
  String get dependentSave => 'Save profile';

  @override
  String dependentCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles',
      one: '1 profile',
    );
    return '$_temp0';
  }

  @override
  String get dependentCardEmpty => 'No profiles yet';

  @override
  String get dependentCardViewAll => 'View all';

  @override
  String get dependentCardView => 'View';

  @override
  String get dependentDobHint => 'Optional';

  @override
  String get dependentDobNotSet => 'Not provided';

  @override
  String get dependentDobClear => 'Clear date of birth';

  @override
  String get dependentNameTooLong => 'Name must be 255 characters or fewer';

  @override
  String get dependentCreatedToast => 'Profile created';

  @override
  String get dependentGuardianInactiveTag => 'Needs a new guardian';

  @override
  String get dependentGuardianInactiveBanner =>
      'This profile\'s guardian has left the household or no longer has permission to manage it. The data is kept; the household owner needs to assign a new guardian before it can be edited.';

  @override
  String get dependentGuardianInactiveOwnerHint =>
      'Until an active guardian is assigned, only the household owner can edit the health profile.';

  @override
  String get dependentSummarySection => 'Summary';

  @override
  String get dependentHealthRestricted =>
      'Only the current guardian or the household owner can view the full health profile.';

  @override
  String get dependentGuardianSection => 'Guardian';

  @override
  String dependentGuardianYou(String name) {
    return '$name (you)';
  }

  @override
  String get dependentGuardianLeft => 'Left the household';

  @override
  String get dependentGuardianNoManage => 'No longer allowed to manage';

  @override
  String get dependentChangeGuardian => 'Change guardian';

  @override
  String dependentChangeGuardianTitle(String name) {
    return 'Change guardian — $name';
  }

  @override
  String get dependentChangeGuardianEmpty =>
      'No member can be assigned as guardian.';

  @override
  String get dependentGuardianChangedToast => 'Guardian changed';

  @override
  String get dependentDelete => 'Delete profile';

  @override
  String dependentDeleteConfirmTitle(String name) {
    return 'Delete $name\'s profile?';
  }

  @override
  String get dependentDeleteConfirmBody =>
      'All health and allergy data of this profile will be permanently deleted. This cannot be undone.';

  @override
  String get dependentDeletedToast => 'Profile deleted';

  @override
  String get dependentNotFoundTitle => 'Profile not found';

  @override
  String get dependentNotFoundBody =>
      'It may have been deleted or belong to another household.';

  @override
  String get dependentBackToList => 'Back to list';

  @override
  String get dependentNoAccessTitle => 'No access';

  @override
  String get dependentNoAccessHealth =>
      'Only the current guardian or the household owner can edit this health profile.';

  @override
  String get dependentNoAccessAllergens =>
      'Only the current guardian or the household owner can edit these allergies.';

  @override
  String dependentHealthTitle(String name) {
    return 'Health — $name';
  }

  @override
  String dependentAllergensTitle(String name) {
    return 'Allergies — $name';
  }

  @override
  String get dependentErrorForbidden =>
      'You don\'t have permission to do this.';

  @override
  String get dependentErrorNoHousehold => 'Join a household first.';

  @override
  String get dependentErrorInvalidGuardian =>
      'This member can\'t be the guardian. Please choose someone else.';

  @override
  String get dependentGuardianCurrent => 'Current';

  @override
  String dependentBornOn(String date) {
    return 'Born $date';
  }

  @override
  String get dependentHealthUnknownDiet =>
      'This profile has a diet this app version doesn\'t support. Update the app to edit it.';

  @override
  String dependentMoreChip(int count) {
    return '+$count';
  }

  @override
  String get inventoryStatTotal => 'Total items';

  @override
  String get inventoryStatExpiring => 'Expiring soon';

  @override
  String get inventoryStatLowStock => 'Running low';

  @override
  String get inventoryValidationNameEmpty => 'Name must not be empty';

  @override
  String get inventoryValidationQuantityEmpty => 'Quantity must not be empty';

  @override
  String get inventoryValidationQuantityNotNumber => 'Must be a number';

  @override
  String get inventoryValidationQuantityNotPositive =>
      'Quantity must be greater than 0';

  @override
  String get inventoryValidationQuantityNegative =>
      'Quantity must not be negative';

  @override
  String get inventoryValidationQuantityNotWhole =>
      'For \"piece\" units, it must be a whole number';

  @override
  String get mealPlanStatusConfirmed => 'Confirmed';

  @override
  String get mealPlanStatusVoting => 'Voting';

  @override
  String get mealPlanStatusSuggested => 'Suggested';

  @override
  String get mealPlanStatusEmpty => 'Not chosen';

  @override
  String get familyRoleMember => 'Member';

  @override
  String tierUpdatedClaimStale(String tier) {
    return 'Household plan updated to $tier. Sign in again if the screen still shows the old plan.';
  }

  @override
  String get planningPlanNotReady =>
      'The weekly plan is not loaded yet — please try again.';

  @override
  String get sessionExpiredError =>
      'Your session has expired. Please sign in again.';

  @override
  String get shoppingPriceQuestion => 'How much did you pay?';

  @override
  String get shoppingPriceOptional => 'You can skip this';

  @override
  String get shoppingPriceLabel => 'Price';

  @override
  String get shoppingPriceZeroHint =>
      '0 ₫ means free. If you don\'t know the price, tap Skip.';

  @override
  String get shoppingPriceSkip => 'Skip';

  @override
  String get shoppingPriceSave => 'Save';

  @override
  String get shoppingPriceLostItemDeleted =>
      'This item was deleted on another device — the price you entered wasn\'t saved.';

  @override
  String get shoppingPriceLostListClosed =>
      'The list has moved to a new week — the price you entered wasn\'t saved.';

  @override
  String get shoppingPriceNotSaved =>
      'This item was just updated by someone else — the price you entered was not saved. Untick and tick again to re-enter it.';

  @override
  String get shoppingAssign => 'Assign';

  @override
  String get shoppingAssignedMe => 'Me';

  @override
  String get shoppingAssigneeFormer => 'Former member';

  @override
  String get shoppingAssignNeedsNetwork =>
      'You need a connection to assign items';

  @override
  String get shoppingAssigneeInvalid =>
      'This person can no longer be assigned — the member list was reloaded.';

  @override
  String get shoppingAssignToMe => 'I\'ll take it';

  @override
  String get shoppingUnassign => 'Unassign';

  @override
  String get shoppingMineEmpty => 'Nothing is assigned to you yet.';

  @override
  String shoppingFilterMine(int count) {
    return 'Mine ($count)';
  }

  @override
  String get shoppingFilterMineNoCount => 'Mine';

  @override
  String get shoppingAssignSyncing => 'Syncing… you can assign once it\'s done';

  @override
  String get shoppingAssigneeUnknown => 'Assigned';

  @override
  String navShoppingAssignedSemantics(int count) {
    return 'Shopping, $count items assigned to you';
  }

  @override
  String shoppingAddRejected(String name) {
    return 'Couldn\'t add \"$name\" — the server rejected it, so it was removed from the list. Please add it again.';
  }

  @override
  String get aiOfflineModeBanner =>
      'Using offline mode — results may be simpler than usual';

  @override
  String get aiOfflineEstimate => 'Offline estimate';

  @override
  String aiOfflineEstimateConfidence(int percent) {
    return 'Offline estimate · $percent%';
  }

  @override
  String get shoppingManageCategoriesTooltip => 'Manage categories';

  @override
  String get shoppingShareTooltip => 'Share list';

  @override
  String get shoppingCategoriesTitle => 'Shopping categories';

  @override
  String get shoppingCategoriesEmpty =>
      'No categories yet. Create categories to colour and order your shopping list your way.\nCategories are kept on this device only and are not synced to your family.';

  @override
  String get shoppingCategoriesLocalNote =>
      'Kept on this device only — not synced to your family.';

  @override
  String get shoppingCategoryAdd => 'Add category';

  @override
  String get shoppingCategoryEdit => 'Edit category';

  @override
  String get shoppingCategoryNameLabel => 'Category name';

  @override
  String get shoppingCategoryColorLabel => 'Colour';

  @override
  String get shoppingCategorySave => 'Save';

  @override
  String get shoppingCategoryCancel => 'Cancel';

  @override
  String get shoppingCategoryDelete => 'Delete';

  @override
  String get shoppingCategoryErrEmpty => 'Category name can\'t be empty';

  @override
  String shoppingCategoryErrTooLong(int max) {
    return 'Category name must be at most $max characters';
  }

  @override
  String get shoppingCategoryErrDuplicate =>
      'A category with this name already exists';

  @override
  String get shoppingCategoriesLoadFailed => 'Couldn\'t load categories';

  @override
  String get shoppingCategoryErrSaveFailed =>
      'Couldn\'t save, please try again';

  @override
  String shoppingCategoryDeleteConfirm(String name) {
    return 'Delete category \"$name\"? Items already in this category keep it — only the colour and order hint is lost.';
  }

  @override
  String get shoppingShareTitle => 'Share shopping list';

  @override
  String get shoppingShareCopyText => 'Copy as text';

  @override
  String get shoppingShareNoItems => 'No items to share yet';

  @override
  String get shoppingShareLink => 'Share link';

  @override
  String get shoppingShareComingSoon => 'Coming soon';

  @override
  String get shoppingShareCopied => 'Shopping list copied to clipboard';

  @override
  String get shoppingShareTextHeader => '🛒 Shopping list';

  @override
  String shoppingShareTextProgress(int checked, int total) {
    return 'Bought: $checked/$total';
  }

  @override
  String get shoppingShareTextUncategorized => 'Uncategorized';

  @override
  String get shoppingShareTextFooter => 'Made with Smart Kitchen App';

  @override
  String get attendanceTitle => 'Meal attendance';

  @override
  String get attendanceYes => 'Attending';

  @override
  String get attendanceNo => 'Not attending';

  @override
  String get attendanceUnknown => 'Not answered';

  @override
  String get attendanceClear => 'Clear response';

  @override
  String get attendanceClosed => 'Attendance for this meal is read-only.';

  @override
  String get attendanceLoadFailed => 'Could not load attendance';

  @override
  String get attendanceSaveFailed => 'Response was not saved. Please retry.';

  @override
  String get attendanceMember => 'Member';

  @override
  String attendanceSummary(int yes, int unknown) {
    return '$yes members attending · $unknown unanswered';
  }

  @override
  String get mealPlanConfirm => 'Confirm weekly menu';

  @override
  String get mealPlanConfirmed => 'Weekly menu confirmed';

  @override
  String get mealPlanConfirmFailed =>
      'Could not confirm. Choose at least one recipe and complete or remove empty dishes.';

  @override
  String get mealPlanGenerateSuggestions => 'Generate suggestions';

  @override
  String get mealPlanChooseRecipe => 'Choose a recipe';

  @override
  String get mealComposeTitle => 'Automatic meal menu';

  @override
  String get mealComposePeoplePolicy =>
      'Members who have not replied are included. Ingredients can all be purchased.';

  @override
  String mealComposePeopleCount(int count) {
    return '$count diners';
  }

  @override
  String get mealComposeReplaceTitle => 'Replace this meal menu?';

  @override
  String get mealComposeReplaceBody =>
      'Existing dishes will only be replaced after a complete new menu is ready.';

  @override
  String get mealComposeRegenerate => 'Create another menu';

  @override
  String get mealComposeGenerate => 'Create meal menu';

  @override
  String get mealComposeLoading => 'Choosing a complete menu…';

  @override
  String get mealComposeRunning =>
      'The request is still processing. Refresh to check; your existing menu is preserved.';

  @override
  String get mealComposeIncomplete =>
      'No complete suitable menu was found. Your existing menu is preserved.';

  @override
  String get mealComposeStale =>
      'The meal or diners changed. Refresh before trying again.';

  @override
  String get mealComposeDisabled =>
      'Automatic menus are not enabled on this server yet.';

  @override
  String get mealComposeFailed =>
      'Could not finish. Refresh to recover the request before trying again.';

  @override
  String get mealComposeRefresh => 'Check or refresh';

  @override
  String get mealComposeShopping => 'Ingredients to buy';

  @override
  String get mealComposeNutritionWarning =>
      'Nutrition or calorie targets are estimated, incomplete, or outside the target range.';

  @override
  String mealComposeDishServings(String name, String servings) {
    return '$name · $servings recipe servings';
  }

  @override
  String mealComposeCalories(int calories) {
    return 'Estimated total: $calories kcal';
  }

  @override
  String get mealComposeSyncPending =>
      'Your menu was saved. Refresh to finish syncing the meal plan.';

  @override
  String get mealplanOutcomeUnknown =>
      'The result is not yet known. Read again to view saved data; it may still change if the earlier request finishes. Continuing uses only the data you have just read.';

  @override
  String get mealplanReadAgain => 'Read again';

  @override
  String get mealplanContinueSnapshot => 'Continue from the data just read';

  @override
  String get mealplanSuggestionsChanged =>
      'These suggestions have changed. Read the saved suggestions before choosing again.';

  @override
  String get healthProfileDietUnset => 'Diet not selected';

  @override
  String get healthProfileDietNone => 'No special diet preference';

  @override
  String get healthProfileDietHelp =>
      'Diet rules depend on the meal planning mode. Declare allergies separately; a gluten-free diet does not declare a gluten allergy.';

  @override
  String get healthProfileHeightInvalid =>
      'Enter a height from 1 to 300 cm, or leave blank';

  @override
  String get healthProfileWeightInvalid =>
      'Enter a weight from 1 to 500 kg, or leave blank';

  @override
  String get unitKcal => 'kcal';

  @override
  String get planningRepetitionWindowHint =>
      'Counts assigned dishes in the plan, including both the start and end dates.';

  @override
  String planningRepetitionRange(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String get planningCandidateSignalsHint =>
      'Bars show advisory signal levels.';

  @override
  String get planningRepetitionContextHint =>
      'Repetition information reflects dishes assigned in the plan.';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String get commonRequiredField => 'This field is required';

  @override
  String get showcaseTitle => 'Widget showcase';

  @override
  String get showcaseEntry => 'Widget showcase (dev)';

  @override
  String get showcaseToggleTheme => 'Toggle light/dark';

  @override
  String get showcaseSectionColors => 'Colors';

  @override
  String get showcaseSectionTypography => 'Typography';

  @override
  String get showcaseSectionButtons => 'Buttons';

  @override
  String get showcaseSectionCards => 'Cards';

  @override
  String get showcaseSectionInputs => 'Inputs';

  @override
  String get showcaseSectionStates => 'States';

  @override
  String get showcaseSectionOverlay => 'Loading overlay';

  @override
  String get showcaseSectionDialog => 'Dialog';

  @override
  String get showcaseSampleLabel => 'Food name';

  @override
  String get showcaseSampleText => 'The quick brown fox';

  @override
  String get showcaseHighlighted => 'Highlighted card';

  @override
  String get showcaseCardNormal => 'Normal card';

  @override
  String get showcaseCardTappable => 'Tappable card';

  @override
  String get showcaseCardElevated => 'Elevated card';

  @override
  String get showcaseVariantPrimary => 'Primary';

  @override
  String get showcaseVariantSecondary => 'Secondary';

  @override
  String get showcaseVariantOutline => 'Outline';

  @override
  String get showcaseVariantGoogle => 'Google';

  @override
  String get showcaseVariantText => 'Text';

  @override
  String get showcaseVariantDestructive => 'Destructive';

  @override
  String get showcaseStateLoading => 'Loading';

  @override
  String get showcaseStateDisabled => 'Disabled';

  @override
  String get showcaseTapToLoad => 'Tap to load for 2s';

  @override
  String get showcaseFieldRequired => 'Required field';

  @override
  String get showcaseFieldServerError => 'Field with server error';

  @override
  String get showcaseFieldServerErrorText => 'This name already exists';

  @override
  String get showcaseFieldPassword => 'Password';

  @override
  String get showcaseFieldDisabled => 'Disabled field';

  @override
  String get showcaseEmptyAction => 'Add item';

  @override
  String get showcaseShowOverlay => 'Show overlay for 2s';

  @override
  String get showcaseOpenDialog => 'Open confirm dialog';

  @override
  String get showcaseOpenDestructiveDialog => 'Open destructive dialog';

  @override
  String get showcaseDialogTitle => 'Delete this item?';

  @override
  String get showcaseDialogMessage => 'This action cannot be undone.';

  @override
  String showcaseDialogResult(String result) {
    return 'Result: $result';
  }

  @override
  String get profileDefaultName => 'Member';

  @override
  String get profileSessionMissingTitle => 'Couldn\'t load your profile';

  @override
  String get profileSessionMissingMessage =>
      'Your session is no longer valid. Please sign in again.';

  @override
  String get profileReLogin => 'Sign in again';

  @override
  String get profileWeeklyRecapNav => 'Weekly recap';

  @override
  String get profileChangeAvatar => 'Change profile photo';

  @override
  String get profileAvatarPickAnother => 'Choose another photo';

  @override
  String get profileAvatarNewUnsaved => 'New photo — not saved yet';

  @override
  String get profileAvatarUploading => 'Uploading photo…';

  @override
  String get profileAvatarGallery => 'Gallery';

  @override
  String get profileAvatarCamera => 'Camera';

  @override
  String get profileAvatarPermissionDenied =>
      'Camera or photo library access is not granted. Enable it in Settings.';

  @override
  String get profileNameRequired => 'Full name can\'t be empty';

  @override
  String get profileNameTooLong => 'Full name can be at most 100 characters';

  @override
  String get profileSaving => 'Saving…';

  @override
  String get profileSaveRetry => 'Try again';

  @override
  String get profileSaveErrorAfterUpload =>
      'Your photo was uploaded but the profile wasn\'t saved. Check your connection and try again.';

  @override
  String get avatarErrorInvalid =>
      'Invalid image. Please choose another JPG or PNG photo.';

  @override
  String get avatarErrorTooLarge =>
      'Image is too large. Please choose another one.';

  @override
  String get healthProfileEmptyTitle => 'Health profile not set up';

  @override
  String get healthProfileEmptyMessage =>
      'Add a calorie goal, diet and allergies to get better meal suggestions.';

  @override
  String get healthProfileNotSetUp => 'Not set up';

  @override
  String get healthProfileSetUpCta => 'Set up health profile';

  @override
  String get healthProfileEditAction => 'Edit';

  @override
  String get healthProfileEditTitle => 'Edit health profile';

  @override
  String healthProfileKcalValue(int value) {
    return '$value kcal';
  }

  @override
  String get healthProfileCaloriesNotSet => 'Not set';

  @override
  String get healthProfileCaloriesNotSetToggle => 'No calorie goal';

  @override
  String healthProfileCaloriesCurrent(int value) {
    return 'Current: $value kcal';
  }

  @override
  String healthProfileCaloriesOutOfRange(int min, int max) {
    return 'Outside $min–$max — drag the slider to pick a new value.';
  }

  @override
  String get healthProfileNeedsNetwork =>
      'An internet connection is needed to edit.';

  @override
  String get healthProfileCaloriesServerInvalid => 'Invalid calorie goal';

  @override
  String get allergenNeedsNetwork =>
      'An internet connection is needed to edit allergies.';

  @override
  String get allergensHealthLoadFailedTitle =>
      'Couldn\'t load your current allergies';

  @override
  String get allergensHealthLoadFailedMessage =>
      'To avoid overwriting saved allergies, the data must finish loading before editing.';

  @override
  String get allergensSavedSection => 'Saved allergies';

  @override
  String allergensCatalogCount(int count) {
    return '$count common allergens';
  }

  @override
  String allergensSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get allergenSaveError =>
      'Something went wrong while saving. Please try again.';

  @override
  String familyRemoveConfirmBody(String name) {
    return '$name will no longer see the household\'s inventory, meal plans and shopping list.';
  }

  @override
  String get familyRemoveConfirmAction => 'Remove';

  @override
  String familyRemoveSuccess(String name) {
    return 'Removed $name from the household.';
  }

  @override
  String familyMemberYou(String name) {
    return '$name (you)';
  }

  @override
  String get familyGuestBadge => 'Guest';

  @override
  String familyJoinedAt(String date) {
    return 'Joined $date';
  }

  @override
  String get familyNeedsNetwork =>
      'You need a connection to invite or remove members.';

  @override
  String get familyErrorNotOwner =>
      'You no longer have permission to manage this household.';

  @override
  String get familyErrorInviteLimit =>
      'There are already 3 active invites. Wait for an old invite to expire and try again.';

  @override
  String get familyErrorCannotRemove => 'This member can\'t be removed.';

  @override
  String familyInviteExpiresAt(String date) {
    return 'Expires: $date';
  }

  @override
  String get familyInviteCopyCode => 'Copy code';

  @override
  String get familyInviteCopyLink => 'Copy link';

  @override
  String get familyInviteCopied => 'Copied';

  @override
  String get familyInviteShowLast => 'Show the latest invite';

  @override
  String get memberHealthForbidden =>
      'You don\'t have permission to view this member\'s health profile.';

  @override
  String get memberDetailPrivacyNote =>
      'Height, weight and calorie goal are private and not shown here.';

  @override
  String get memberDetailNotFound => 'This member could not be found.';

  @override
  String get memberDetailClose => 'Close';

  @override
  String get nutritionTitle => 'Weekly nutrition';

  @override
  String get nutritionWeekThisTitle => 'This week\'s nutrition';

  @override
  String get nutritionComplianceExcellent => 'Excellent';

  @override
  String get nutritionComplianceGood => 'Good';

  @override
  String get nutritionComplianceNeedsImprovement => 'Needs improvement';

  @override
  String get nutritionCompliancePoor => 'Not met';

  @override
  String get nutritionComplianceUnknown => 'Not rated yet';

  @override
  String nutritionScoreOutOf(int score) {
    return '$score/100';
  }

  @override
  String get nutritionScoreLabel => 'Plan compliance score';

  @override
  String get nutritionAllergenNotChecked =>
      'Allergens not checked — score is based on calories only';

  @override
  String get nutritionSetTarget => 'Set calorie target';

  @override
  String get nutritionWeeklyTotal => 'Weekly total';

  @override
  String nutritionTargetForDays(int days, String kcal) {
    return 'Target for $days days with data: $kcal kcal';
  }

  @override
  String nutritionWeeklyDelta(String delta) {
    return '$delta kcal vs target';
  }

  @override
  String get nutritionNoTarget => 'No target set';

  @override
  String nutritionAvgPerDay(String kcal, int days) {
    return 'Avg $kcal kcal/day ($days days with data)';
  }

  @override
  String get nutritionNoDataDays => 'No day has nutrition data yet';

  @override
  String nutritionMissingData(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dishes have no nutrition data',
      one: '1 dish has no nutrition data',
    );
    return '$_temp0';
  }

  @override
  String nutritionKcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String nutritionMacroLine(String p, String c, String f) {
    return 'P $p g · C $c g · F $f g';
  }

  @override
  String get nutritionNoMealsDay => 'No dishes';

  @override
  String get nutritionProtein => 'Protein';

  @override
  String get nutritionCarbs => 'Carbs';

  @override
  String get nutritionFat => 'Fat';

  @override
  String nutritionMacroPercent(String name, String percent) {
    return '$name $percent%';
  }

  @override
  String get nutritionNoMacroData => 'No macro data yet';

  @override
  String get nutritionDayOver => 'Over target';

  @override
  String get nutritionDayUnder => 'Well under';

  @override
  String get nutritionDayOnTarget => 'On target';

  @override
  String get nutritionEmpty => 'No dishes confirmed this week yet';

  @override
  String get nutritionLoadFailed => 'Couldn\'t load nutrition data';

  @override
  String get nutritionViewMealPlan => 'View weekly plan';

  @override
  String get nutritionDishNoData => 'no data';

  @override
  String get nutritionDailyBreakdown => 'Daily breakdown';

  @override
  String get nutritionMealBreakfast => 'Breakfast';

  @override
  String get nutritionMealLunch => 'Lunch';

  @override
  String get nutritionMealDinner => 'Dinner';

  @override
  String get nutritionMealSnack => 'Snack';

  @override
  String nutritionBarSemantics(String day, String kcal) {
    return '$day: $kcal kcal';
  }

  @override
  String nutritionChartSemantics(String days) {
    return 'Calories per day: $days';
  }

  @override
  String get nutritionMealOther => 'Other meal';

  @override
  String nutritionDishLine(String meal, String dish, String value) {
    return '$meal: $dish · $value';
  }

  @override
  String get receiptScanTitle => 'Scan receipt';

  @override
  String get receiptScanTooltip => 'Scan receipt';

  @override
  String get receiptScanHint =>
      'Capture the whole receipt clearly. Items matching your shopping list are pre-selected; extra purchases can go to inventory.';

  @override
  String get receiptScanNoImage => 'No image yet';

  @override
  String get receiptScanning => 'Reading the receipt…';

  @override
  String get receiptErrorAiUnavailable =>
      'The receipt reader is busy or not ready. Retry with this same photo, or choose another one.';

  @override
  String get receiptErrorInProgress =>
      'This receipt is still being read — try again in a few seconds.';

  @override
  String get receiptErrorImageRejected =>
      'This photo can\'t be processed. Retrying the same photo gives the same result — take another photo.';

  @override
  String get receiptErrorNoHouseholdTitle => 'You\'re not in a household yet';

  @override
  String get receiptErrorNoHousehold =>
      'Join a household before scanning receipts.';

  @override
  String get receiptClose => 'Close';

  @override
  String get receiptResultTitle => 'Scan result';

  @override
  String get receiptRestart => 'Reset';

  @override
  String get receiptRetake => 'Retake';

  @override
  String get receiptEmpty =>
      'Couldn\'t read the receipt, please retake the photo';

  @override
  String receiptSummaryTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String receiptSummaryCounts(int matched, int unmatched) {
    return '$matched matched lines · $unmatched not on the list';
  }

  @override
  String get receiptMatchedSection => 'Matches your shopping list';

  @override
  String receiptMatchedCount(int lines, int items) {
    return '$lines lines · $items items';
  }

  @override
  String get receiptUnmatchedSection => 'Not on the list';

  @override
  String receiptUnmatchedCount(int count) {
    return '$count items';
  }

  @override
  String receiptOnReceipt(String raw) {
    return 'On receipt: \"$raw\"';
  }

  @override
  String get receiptBadgeReview => 'Double-check';

  @override
  String receiptCatalogHint(int percent) {
    return 'Catalog guess $percent%';
  }

  @override
  String get receiptMarkedBought => 'Marked as bought';

  @override
  String get receiptNotUpdated => 'Not updated';

  @override
  String get receiptSkipped => 'Skipped';

  @override
  String get receiptAddToInventory => 'Add to inventory';

  @override
  String get receiptAdding => 'Adding…';

  @override
  String get receiptAdded => 'Added';

  @override
  String get receiptCategoryOptional => 'Category (optional)';

  @override
  String get receiptUnitHint => 'Choose a unit before adding';

  @override
  String receiptCommit(int count) {
    return 'Update shopping list ($count)';
  }

  @override
  String get receiptDone => 'Done';

  @override
  String receiptCommitFailedBanner(int count) {
    return '$count items couldn\'t be updated — check the Shopping screen.';
  }

  @override
  String get receiptDoneTitle => 'Updated';

  @override
  String receiptDoneToast(int count) {
    return 'Updated $count items';
  }

  @override
  String get authBadCredentials => 'Wrong email or password';

  @override
  String get authEmailExists => 'This email is already registered';

  @override
  String get authNameRequired => 'Please enter your full name';

  @override
  String get authNameTooLong => 'Full name must be at most 100 characters';

  @override
  String get householdFull => 'This household already has 10 members';

  @override
  String get joinRateLimited =>
      'Too many attempts. Please try again in a few minutes';

  @override
  String get inviteQrInvalid => 'This QR code is not a Smart Kitchen invite';

  @override
  String get joinGoHome => 'Go to home';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty =>
      'No notifications in this session yet. Notifications received in the background only appear here after you open them.';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsNavTitle => 'Notifications';

  @override
  String get notificationPermissionTitle => 'Turn on notifications';

  @override
  String get notificationPermissionBody =>
      'Get reminders about expiring food, shopping lists and planned meals.';

  @override
  String get notificationPermissionEnable => 'Turn on notifications';

  @override
  String get notificationPermissionLater => 'Not now';

  @override
  String get notificationPermissionDeniedBanner =>
      'Notifications are turned off';

  @override
  String get notificationPermissionNotDeterminedBanner =>
      'You haven\'t turned on notifications';

  @override
  String get notificationPermissionUnsupported =>
      'Notifications aren\'t available on this device';

  @override
  String get notificationOpenSettings => 'Open Settings';

  @override
  String get notificationRegistrationFailed =>
      'Couldn\'t register for notifications yet — we\'ll try again';

  @override
  String get notificationJustNow => 'Just now';

  @override
  String notificationMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String notificationHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get notificationUntitled => 'New notification';

  @override
  String notificationsUnreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String shoppingCheckoutCta(int count) {
    return 'Put away ($count)';
  }

  @override
  String get shoppingCheckoutTitle => 'Put away in pantry';

  @override
  String get shoppingCheckoutHint =>
      'Check the expiry dates, then confirm to add these items to the pantry.';

  @override
  String shoppingCheckoutConfirm(int count) {
    return 'Add $count to pantry';
  }

  @override
  String shoppingCheckoutDone(int count) {
    return 'Added $count items to the pantry';
  }

  @override
  String get shoppingCheckoutEmpty => 'No bought items waiting to be put away.';

  @override
  String get shoppingCheckoutOffline =>
      'You need a connection to put items away.';

  @override
  String get shoppingCheckoutReloaded =>
      'The list changed and was reloaded. Please check and confirm again.';

  @override
  String get shoppingCheckoutDuplicate => 'Already in pantry · new batch';

  @override
  String get shoppingCheckoutInvalidRow => 'Check the quantity / unit';

  @override
  String get shoppingInInventoryBadge => 'In pantry';

  @override
  String get shoppingInInventoryToggleBlocked =>
      'This item is already in the pantry and can\'t be unchecked.';

  @override
  String get expiryChipAdd => 'Add expiry date';

  @override
  String expiryChipSuggested(Object date) {
    return 'Exp. $date · suggested';
  }

  @override
  String expiryChipSet(Object date) {
    return 'Exp. $date';
  }

  @override
  String get errShopItemAlreadyInInventory =>
      'This item has already been put in the pantry.';

  @override
  String get errShopItemNotBought =>
      'Only bought items can be put in the pantry.';
}
