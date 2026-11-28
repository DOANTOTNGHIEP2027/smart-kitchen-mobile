// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Smart Kitchen';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get stateEmptyDefault => 'Chưa có dữ liệu';

  @override
  String get stateErrorDefault => 'Đã có lỗi xảy ra';

  @override
  String get comingSoon => 'Sắp ra mắt';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navInventory => 'Kho';

  @override
  String get navPlanning => 'Thực đơn';

  @override
  String get navShopping => 'Đi chợ';

  @override
  String get navProfile => 'Cá nhân';

  @override
  String get homeGreeting => 'Chào buổi sáng';

  @override
  String get homeGreetingAfternoon => 'Chào buổi chiều';

  @override
  String get homeGreetingEvening => 'Chào buổi tối';

  @override
  String get homeGreetingNight => 'Chào bạn đêm khuya';

  @override
  String get homeShoppingSubtitle => 'Danh sách đồ cần mua sắm';

  @override
  String get homeMealLogSubtitle => 'Theo dõi dinh dưỡng & calo';

  @override
  String get inventoryCategoryOptional => 'Phân loại (tuỳ chọn)';

  @override
  String get inventoryCategoryHint => 'VD: Gia vị, hải sản, rau củ';

  @override
  String get inventoryCategoryVegetables => 'Rau củ';

  @override
  String get inventoryCategorySeafood => 'Hải sản';

  @override
  String get inventoryCategoryMeat => 'Thịt';

  @override
  String get inventoryCategorySpices => 'Gia vị';

  @override
  String get inventoryCategoryFruit => 'Trái cây';

  @override
  String get inventoryCategoryDairy => 'Sữa và trứng';

  @override
  String get inventoryCategoryDry => 'Đồ khô';

  @override
  String get inventoryCategoryDrinks => 'Đồ uống';

  @override
  String get homeQuickActions => 'Hôm nay bạn muốn làm gì?';

  @override
  String get homeStartCooking => 'Bắt đầu buổi nấu';

  @override
  String get homeStartCookingSubtitle =>
      'Chọn món trong thực đơn để bắt đầu nấu';

  @override
  String get homeInventoryTitle => 'Kho thực phẩm';

  @override
  String get homeInventorySubtitle => 'Theo dõi nguyên liệu trong bếp';

  @override
  String get homeMealPlanTitle => 'Kế hoạch bữa ăn';

  @override
  String get homeMealPlanSubtitle => 'Sắp lịch và vote món cùng gia đình';

  @override
  String get homeRecommendedMeals => 'Món ăn phù hợp';

  @override
  String get homeRecipeAction => 'Xem cách nấu';

  @override
  String get homeRecipeDetailTitle => 'Chi tiết món ăn';

  @override
  String get homeRecipeIngredients => 'Nguyên liệu';

  @override
  String get homeRecipeGuide => 'Nguồn công thức tham khảo';

  @override
  String get homeRecipeCook => 'Nấu món này';

  @override
  String get homeUpcomingMealTitle => 'Bữa sắp tới';

  @override
  String get homeUpcomingToday => 'Hôm nay';

  @override
  String get homeUpcomingTomorrow => 'Ngày mai';

  @override
  String get homeUpcomingEmpty => 'Chưa có bữa nào sắp tới trong thực đơn';

  @override
  String get homeUpcomingOpenPlan => 'Lên thực đơn';

  @override
  String homeRecipeMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String homeRecipeCalories(int calories) {
    return '$calories kcal';
  }

  @override
  String get authEmailExample => 'ban@example.com';

  @override
  String get authFullNameExample => 'Nguyễn Văn A';

  @override
  String get householdNameExample => 'Nhà Nguyễn';

  @override
  String get inviteCodeExample => 'ABC12345';

  @override
  String get joinDisplayNameExample => 'Thành viên';

  @override
  String get mealPlanTitle => 'Kế hoạch tuần';

  @override
  String get mealPlanNoHousehold => 'Bạn chưa thuộc Nhà nào.';

  @override
  String get mealPlanLoadFailed => 'Không tải được kế hoạch.';

  @override
  String mealPlanWeekRange(
      int startDay, int startMonth, int endDay, int endMonth) {
    return 'Tuần $startDay/$startMonth – $endDay/$endMonth';
  }

  @override
  String mealPlanDaySchedule(int day, int month) {
    return 'Lịch ngày $day/$month';
  }

  @override
  String mealPlanDateShort(int day, int month) {
    return '$day/$month';
  }

  @override
  String get mealPlanWeekdayMonday => 'T2';

  @override
  String get mealPlanWeekdayTuesday => 'T3';

  @override
  String get mealPlanWeekdayWednesday => 'T4';

  @override
  String get mealPlanWeekdayThursday => 'T5';

  @override
  String get mealPlanWeekdayFriday => 'T6';

  @override
  String get mealPlanWeekdaySaturday => 'T7';

  @override
  String get mealPlanWeekdaySunday => 'CN';

  @override
  String get mealPlanBreakfast => 'Sáng';

  @override
  String get mealPlanLunch => 'Trưa';

  @override
  String get mealPlanDinner => 'Tối';

  @override
  String mealPlanOpenVotes(int count) {
    return '$count phiên vote đang mở';
  }

  @override
  String get mealPlanPastDayLocked => 'Ngày đã qua, không thể chỉnh sửa';

  @override
  String get mealPlanMissingTitle => 'Thiếu nguyên liệu';

  @override
  String get mealPlanMissingMessage =>
      'Kho chưa đủ nguyên liệu cho món này. Thêm vào danh sách đi chợ?';

  @override
  String mealPlanMissingAdded(int count) {
    return 'Đã thêm $count món vào danh sách đi chợ';
  }

  @override
  String get mealPlanDuplicateRecipe => 'Món này đã có trong bữa';

  @override
  String get mealPlanTapToAdd => 'Chạm để thêm món';

  @override
  String get mealPlanSelectingDish => 'Đang chọn món';

  @override
  String get mealPlanDishUnselected => 'Chưa chọn món';

  @override
  String get mealPlanAddDish => 'Thêm món';

  @override
  String get mealPlanAddDishFailed => 'Không thể thêm món. Vui lòng thử lại.';

  @override
  String get mealPlanOpenSuggestionsFailed =>
      'Không thể mở gợi ý món. Vui lòng thử lại.';

  @override
  String get devLoginTitle => 'Đăng nhập';

  @override
  String get devLoginSubtitle =>
      'Luồng đăng nhập thật (Google / OTP / quét QR) sẽ có ở fe-onboarding.';

  @override
  String get devLoginCta => 'Vào thử với tài khoản demo';

  @override
  String get devLoginBanner => 'Bản demo app shell — chưa gọi backend';

  @override
  String get authLandingSubtitle => 'Đăng nhập để cùng quản lý căn bếp của bạn';

  @override
  String get googleSignIn => 'Tiếp tục với Google';

  @override
  String get emailSignIn => 'Đăng nhập bằng email';

  @override
  String get emailRegister => 'Tạo tài khoản';

  @override
  String get scanJoinQr => 'Quét mã QR của Nhà';

  @override
  String get googleAccountLinked => 'Tài khoản Google đã được liên kết';

  @override
  String get loginTitle => 'Chào mừng trở lại';

  @override
  String get loginSubtitle => 'Đăng nhập để tiếp tục';

  @override
  String get authRateLimited => 'Quá nhiều lần thử. Thử lại sau';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get noAccountRegister => 'Chưa có tài khoản? Đăng ký';

  @override
  String get registerTitle => 'Tạo tài khoản';

  @override
  String get registerSubtitle => 'Bắt đầu nấu ăn cùng nhau';

  @override
  String get fullName => 'Họ và tên';

  @override
  String get passwordHint => 'Ít nhất 8 ký tự';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get haveAccountLogin => 'Đã có tài khoản? Đăng nhập';

  @override
  String get otpTitle => 'Xác minh email';

  @override
  String get otpSentTo => 'Mã đã được gửi đến';

  @override
  String get otpCode => 'Mã xác minh';

  @override
  String get otpExpires => 'Mã hết hạn sau';

  @override
  String get verified => 'Đã xác minh';

  @override
  String get verify => 'Xác minh';

  @override
  String get resendOtp => 'Gửi lại mã';

  @override
  String get authForgotPasswordLink => 'Quên mật khẩu?';

  @override
  String get authForgotPasswordTitle => 'Đặt lại mật khẩu';

  @override
  String get authForgotPasswordHint =>
      'Nhập email, chúng tôi sẽ gửi mã xác thực.';

  @override
  String get authSendResetOtp => 'Gửi mã';

  @override
  String get authResetPasswordTitle => 'Nhập mã xác thực';

  @override
  String get authResetPasswordSubmit => 'Đặt lại mật khẩu';

  @override
  String get authNewPassword => 'Mật khẩu mới';

  @override
  String get authConfirmPassword => 'Xác nhận mật khẩu';

  @override
  String get authPasswordMismatch => 'Mật khẩu xác nhận không khớp';

  @override
  String get authResetSuccess => 'Đổi mật khẩu thành công. Vui lòng đăng nhập.';

  @override
  String get authOtpCooldown => 'Vui lòng chờ trước khi gửi lại mã.';

  @override
  String get authTooManyAttempts => 'Quá nhiều lần thử. Vui lòng thử lại sau.';

  @override
  String get authEmailInvalid => 'Email không hợp lệ';

  @override
  String get upgradeProfileTitle => 'Hoàn tất hồ sơ';

  @override
  String get upgradeProfileSubtitle =>
      'Thêm email và mật khẩu để duy trì tài khoản';

  @override
  String get fullNameOptional => 'Họ và tên (không bắt buộc)';

  @override
  String get continueToOtp => 'Tiếp tục';

  @override
  String get householdSetupTitle => 'Thiết lập Nhà của bạn';

  @override
  String get householdSetupSubtitle => 'Tạo Nhà mới hoặc tham gia bằng lời mời';

  @override
  String get createHousehold => 'Tạo Nhà';

  @override
  String get joinHousehold => 'Tham gia Nhà';

  @override
  String get householdNameRequired => 'Nhập tên Nhà';

  @override
  String get householdNameTooLong => 'Tên Nhà quá dài';

  @override
  String get householdCreated => 'Đã tạo Nhà';

  @override
  String get inviteQrSemantics => 'Mã QR mời tham gia Nhà';

  @override
  String get inviteMembers => 'Mời thành viên';

  @override
  String get later => 'Để sau';

  @override
  String get createHouseholdSubtitle => 'Đặt tên cho Nhà của bạn';

  @override
  String get householdName => 'Tên Nhà';

  @override
  String get joinHouseholdSubtitle => 'Quét lời mời hoặc nhập mã mời';

  @override
  String get alreadyInHousehold => 'Bạn đã thuộc một Nhà';

  @override
  String get cameraPermissionDenied => 'Cần quyền camera để quét mã QR';

  @override
  String get openSettings => 'Mở cài đặt';

  @override
  String get enterCodeManually => 'Nhập mã thủ công';

  @override
  String get cameraUnavailable => 'Không mở được camera trên thiết bị này';

  @override
  String get inviteCode => 'Mã mời';

  @override
  String get previewInvite => 'Xem trước lời mời';

  @override
  String get scanAgain => 'Quét lại';

  @override
  String get householdOwner => 'Chủ Nhà';

  @override
  String get memberCount => 'Thành viên';

  @override
  String get inviteExpires => 'Lời mời hết hạn';

  @override
  String get displayNameOptional => 'Tên hiển thị (không bắt buộc)';

  @override
  String get confirmJoin => 'Tham gia Nhà';

  @override
  String get networkError => 'Kiểm tra kết nối và thử lại';

  @override
  String get googleUnavailable =>
      'Google Sign-In chưa được cấu hình cho ứng dụng';

  @override
  String get googleEmailRequired => 'Cần có email Google';

  @override
  String get googleTokenInvalid => 'Không thể xác minh Google Sign-In';

  @override
  String get otpInvalid => 'Nhập mã gồm 6 chữ số';

  @override
  String get otpResendLimit => 'Đã yêu cầu mã quá nhiều. Hãy thử lại sau';

  @override
  String get inviteInvalid => 'Lời mời không hợp lệ hoặc đã hết hạn';

  @override
  String get inviteRace => 'Lời mời này không còn khả dụng';

  @override
  String get genericRetryError => 'Đã có lỗi xảy ra. Vui lòng thử lại';

  @override
  String get guestProfileBanner =>
      'Hoàn tất hồ sơ để duy trì quyền truy cập Nhà của bạn';

  @override
  String get completeProfile => 'Hoàn tất hồ sơ';

  @override
  String get profileTitle => 'Hồ sơ của tôi';

  @override
  String get profileEmailMissing => 'Chưa đặt email';

  @override
  String get profileEdit => 'Chỉnh sửa hồ sơ';

  @override
  String get profileEditTitle => 'Chỉnh sửa hồ sơ';

  @override
  String get profileSave => 'Lưu';

  @override
  String get profileSavedToast => 'Đã cập nhật hồ sơ';

  @override
  String get healthProfileTitle => 'Hồ sơ sức khoẻ';

  @override
  String get healthProfileEmpty =>
      'Chưa thiết lập — điền để nhận gợi ý cá nhân hoá.';

  @override
  String get healthProfileTargetCalories => 'Mục tiêu calo/ngày';

  @override
  String get healthProfileDietType => 'Chế độ ăn';

  @override
  String get healthProfileHeight => 'Chiều cao (cm)';

  @override
  String get healthProfileWeight => 'Cân nặng (kg)';

  @override
  String get healthProfileAllergensSection => 'Dị ứng';

  @override
  String get healthProfileAllergensEmpty => 'Chưa có mục dị ứng được lưu';

  @override
  String get healthProfileAllergensEdit => 'Sửa dị ứng';

  @override
  String get healthSave => 'Lưu hồ sơ sức khoẻ';

  @override
  String get healthSavedToast => 'Đã lưu hồ sơ sức khoẻ';

  @override
  String get cookingAbandonTitle => 'Huỷ buổi nấu ăn?';

  @override
  String get cookingAbandonMessage => 'Nguyên liệu sẽ không bị trừ khỏi kho.';

  @override
  String get cookingContinue => 'Tiếp tục nấu';

  @override
  String get cookingAbandonAction => 'Huỷ bỏ';

  @override
  String get cookingLoadFailed => 'Không tải được phiên nấu ăn.';

  @override
  String get cookingRetry => 'Thử lại';

  @override
  String get cookingBack => 'Quay lại';

  @override
  String get cookingAbandonTooltip => 'Huỷ buổi nấu';

  @override
  String cookingStepLabel(int step) {
    return 'Bước $step';
  }

  @override
  String get cookingStepUnavailable => 'Nội dung bước không khả dụng.';

  @override
  String get cookingReturnToCurrentStep => 'Quay lại bước đang nấu';

  @override
  String get cookingPreviousStep => 'Bước trước';

  @override
  String get cookingComplete => 'Hoàn thành';

  @override
  String get cookingNextStep => 'Bước tiếp theo';

  @override
  String get cookingCompletedWithShortfall =>
      'Đã hoàn thành — còn thiếu nguyên liệu';

  @override
  String get cookingCompleted => 'Đã hoàn thành!';

  @override
  String get cookingCompletedShortfallDetail =>
      'Kho đã được trừ đến khi hết hàng (FIFO). Nguyên liệu đã dùng được ghi nhận theo số lượng đã trừ.';

  @override
  String get cookingDeductionResult => 'Kết quả trừ kho:';

  @override
  String get cookingDone => 'Xong';

  @override
  String get cookingAbandoned => 'Đã bỏ dở buổi nấu.';

  @override
  String get cookingAbandonedDetail => 'Kho không bị thay đổi gì.';

  @override
  String get cookingHome => 'Về trang chủ';

  @override
  String get cookingNoIngredientsToDeduct =>
      'Không có nguyên liệu nào để trừ (công thức rỗng).';

  @override
  String cookingDeductionRequired(Object quantity, Object unit) {
    return 'Cần: $quantity $unit';
  }

  @override
  String cookingDeducted(Object quantity, Object unit) {
    return 'Đã trừ: $quantity $unit';
  }

  @override
  String cookingShortfall(Object quantity, Object unit) {
    return 'Thiếu: $quantity $unit';
  }

  @override
  String cookingDeductionLots(int count) {
    return 'Từ $count lô hàng';
  }

  @override
  String get cookingInsufficient => 'Không đủ';

  @override
  String get cookingShortfallTitle => 'Kho không đủ nguyên liệu';

  @override
  String get cookingShortfallMessage =>
      'Chưa trừ gì khỏi kho. Bạn có thể bổ sung kho rồi bấm Hoàn thành lại, hoặc hoàn tất ngay — kho sẽ trừ tới đâu hay tới đó.';

  @override
  String cookingShortfallLine(
      String required, String available, String shortfall, String unit) {
    return 'Cần $required · Có $available · Thiếu $shortfall $unit';
  }

  @override
  String get cookingShortfallNoDetail =>
      'Không lấy được danh sách nguyên liệu thiếu.';

  @override
  String get cookingShortfallConfirm => 'Hoàn tất dù thiếu (trừ phần đang có)';

  @override
  String get cookingShortfallBack => 'Quay lại nấu';

  @override
  String get cookingUnitGram => 'g';

  @override
  String get cookingUnitMilliliter => 'ml';

  @override
  String get cookingUnitPiece => 'quả';

  @override
  String get cookingUnitUnit => 'cái';

  @override
  String cookingStepProgress(int viewedStep, int totalSteps) {
    return 'Bước $viewedStep/$totalSteps';
  }

  @override
  String cookingStepReviewing(int currentStep) {
    return 'Đang xem lại (hiện tại: bước $currentStep)';
  }

  @override
  String cookingSuggestedDuration(int minutes) {
    return 'Thời lượng gợi ý: $minutes phút';
  }

  @override
  String get cookingPause => 'Tạm dừng';

  @override
  String get cookingResume => 'Tiếp tục';

  @override
  String get cookingReset => 'Đặt lại';

  @override
  String get cookingAssistTitle => 'Trợ lý nấu ăn';

  @override
  String get cookingAssistHint =>
      'Hỏi về bước này, thay nguyên liệu, đổi khẩu phần…';

  @override
  String get cookingAssistGreeting => 'Mình có thể giúp gì cho bước này?';

  @override
  String get cookingAssistSend => 'Gửi';

  @override
  String get cookingAssistSending => 'đang trả lời…';

  @override
  String get cookingAssistSlow => 'Câu hỏi này cần thêm chút thời gian';

  @override
  String get cookingAssistOffline => 'Bạn đang offline — trợ lý cần mạng';

  @override
  String get cookingAssistBusy => 'Trợ lý đang bận, thử lại sau';

  @override
  String get cookingAssistRetry => 'Thử lại';

  @override
  String get cookingAssistFiltered => 'Không trả lời được câu này.';

  @override
  String get cookingAssistUnavailable =>
      'Trợ lý không dùng được cho buổi nấu này. Bạn vẫn nấu tiếp bình thường.';

  @override
  String get cookingAssistInStock => 'Có trong kho';

  @override
  String get cookingAssistUnverified => 'Gợi ý chưa kiểm chứng dị ứng';

  @override
  String get cookingAssistBlocked => 'Không gợi ý vì dị ứng';

  @override
  String get cookingAssistFoodSafety =>
      'Hãy tự kiểm tra độ chín và an toàn thực phẩm.';

  @override
  String get cookingAssistDegraded => 'Trả lời rút gọn — trợ lý đang hạn chế';

  @override
  String cookingAssistStepChip(int step) {
    return 'Bước $step';
  }

  @override
  String get cookingAssistProgressAllergen => 'đang kiểm dị ứng…';

  @override
  String get cookingAssistProgressSubstitute =>
      'đang tìm nguyên liệu thay thế…';

  @override
  String get cookingAssistProgressScale => 'đang tính khẩu phần…';

  @override
  String get cookingAssistProgressStep => 'đang đọc công thức…';

  @override
  String cookingAssistSuspected(String dish, String allergen) {
    return 'Đã tạm loại $dish vì nghi có $allergen';
  }

  @override
  String get assistantTitle => 'Trợ lý bếp';

  @override
  String get assistantGreeting =>
      'Chào bạn! Hỏi mình nấu gì, dùng đồ gì cho hết, hay lên thực đơn nhé.';

  @override
  String get assistantPlanningGreeting => 'Cùng lên món cho bữa này nhé.';

  @override
  String get assistantSuggestTonight => 'Tối nay nấu gì?';

  @override
  String get assistantSuggestExpiring => 'Đồ sắp hết hạn nấu được gì?';

  @override
  String get assistantSuggestFamily => 'Món nào hợp cả nhà?';

  @override
  String get assistantSuggestQuick => 'Gợi ý bữa sáng nhanh?';

  @override
  String get assistantSuggestPlanMeal => 'Gợi ý món cho bữa này';

  @override
  String get assistantRateLimited =>
      'Bạn hỏi hơi nhanh, thử lại sau ít phút nhé.';

  @override
  String get assistantProgressSearch => 'đang tìm món…';

  @override
  String assistantMissingIngredients(String items) {
    return 'Còn thiếu: $items';
  }

  @override
  String assistantPlanDay(int day) {
    return 'Ngày $day';
  }

  @override
  String get assistantFabTooltip => 'Hỏi trợ lý bếp';

  @override
  String get assistantAskSlot => 'Hỏi trợ lý';

  @override
  String get assistantHorizonTitle => 'Lên thực đơn cho mấy ngày?';

  @override
  String assistantHorizonOption(int days) {
    return '$days ngày';
  }

  @override
  String get assistantActionConfirm => 'Thêm vào thực đơn';

  @override
  String get assistantActionCancel => 'Bỏ qua';

  @override
  String get assistantActionDone => 'Đã thêm vào thực đơn';

  @override
  String get assistantActionConfirmShopping => 'Thêm vào danh sách đi chợ';

  @override
  String get assistantActionDoneShopping => 'Đã thêm vào danh sách đi chợ';

  @override
  String assistantActionFailed(String code) {
    return 'Chưa thêm được ($code)';
  }

  @override
  String get assistantActionExpired => 'Đề xuất đã hết hạn';

  @override
  String get assistantActionRejected => 'Đã bỏ qua';

  @override
  String get allergensTitle => 'Dị ứng của tôi';

  @override
  String get allergensCatalogEmpty => 'Danh mục dị ứng không khả dụng.';

  @override
  String get allergensSelectNone => 'Không có dị ứng';

  @override
  String get allergensSave => 'Lưu dị ứng';

  @override
  String get allergensSavedToast => 'Đã cập nhật dị ứng';

  @override
  String get dietTypeNone => 'Không';

  @override
  String get dietTypeKeto => 'Keto';

  @override
  String get dietTypeVegetarian => 'Ăn chay';

  @override
  String get dietTypeVegan => 'Vegan';

  @override
  String get dietTypePescatarian => 'Pescatarian';

  @override
  String get dietTypeGlutenFree => 'Không gluten';

  @override
  String get dietTypeDiabetic => 'Tiểu đường';

  @override
  String get familyTitle => 'Gia đình';

  @override
  String get familyRosterEmpty => 'Chưa có thành viên khác.';

  @override
  String get familyRemove => 'Xoá khỏi gia đình';

  @override
  String familyRemoveConfirm(String name) {
    return 'Xóa $name khỏi gia đình?';
  }

  @override
  String get familyRemoveCancel => 'Huỷ';

  @override
  String get familyYou => 'Bạn';

  @override
  String get memberDetailTitle => 'Thành viên';

  @override
  String get memberDetailDietType => 'Chế độ ăn';

  @override
  String get memberDetailAllergensSection => 'Dị ứng';

  @override
  String get memberDetailAllergensEmpty => 'Chưa có mục dị ứng được lưu';

  @override
  String get staleDataBanner =>
      'Dữ liệu có thể chưa cập nhật — đang hiển thị bản lưu gần nhất.';

  @override
  String get profileLogout => 'Đăng xuất';

  @override
  String get profileLogoutAll => 'Đăng xuất khỏi mọi thiết bị';

  @override
  String get profileLogoutConfirm => 'Đăng xuất khỏi thiết bị này?';

  @override
  String get profileLogoutAllConfirm =>
      'Đăng xuất khỏi mọi thiết bị? Bạn sẽ phải đăng nhập lại ở tất cả nơi.';

  @override
  String get profileLogoutCancel => 'Huỷ';

  @override
  String get inventoryTitle => 'Kho thực phẩm';

  @override
  String get add => 'Thêm';

  @override
  String get retry => 'Thử lại';

  @override
  String get all => 'Tất cả';

  @override
  String get cancel => 'Huỷ';

  @override
  String get choose => 'Chọn';

  @override
  String get dismiss => 'Bỏ';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get delete => 'Xoá';

  @override
  String get refresh => 'Làm mới';

  @override
  String get skip => 'Bỏ qua';

  @override
  String get unavailable => 'Chưa khả dụng';

  @override
  String get syncIdempotencyKeyReused =>
      'Thao tác thêm này đã được gửi với nội dung khác — vui lòng kiểm tra lại danh sách.';

  @override
  String get inventorySyncFailed =>
      'Không đồng bộ được — hiển thị dữ liệu đã lưu.';

  @override
  String get inventorySearchHint => 'Tìm theo tên…';

  @override
  String get inventoryNoHousehold =>
      'Bạn chưa thuộc Nhà nào — hãy tạo hoặc tham gia Nhà trước.';

  @override
  String get inventoryNoResults => 'Không tìm thấy mặt hàng phù hợp.';

  @override
  String get inventoryEmpty => 'Chưa có mặt hàng nào.';

  @override
  String get inventoryAddItem => 'Thêm mặt hàng';

  @override
  String get inventoryChooseUnit => 'Chọn đơn vị';

  @override
  String get inventoryDeleteTitle => 'Xoá mặt hàng này?';

  @override
  String get inventoryDeleteMessage => 'Chọn lý do xoá để ghi vào lịch sử kho.';

  @override
  String get inventoryDeleteCooked => 'Đã dùng hết';

  @override
  String get inventoryDeleteWaste => 'Hết hạn, hỏng, bỏ đi';

  @override
  String get inventoryEditItem => 'Sửa mặt hàng';

  @override
  String get inventoryItemName => 'Tên mặt hàng *';

  @override
  String get inventoryItemNameHint => 'vd. Cà chua';

  @override
  String get inventoryQuantity => 'Số lượng *';

  @override
  String get inventoryUnit => 'Đơn vị';

  @override
  String get inventoryLowStockOptional => 'Ngưỡng sắp hết (tuỳ chọn)';

  @override
  String get inventoryExpiryOptional => 'Hạn sử dụng (tuỳ chọn)';

  @override
  String get inventoryChooseDate => 'Chọn ngày…';

  @override
  String get inventoryNoteOptional => 'Ghi chú (tuỳ chọn)';

  @override
  String get inventoryAddToInventory => 'Thêm vào kho';

  @override
  String get inventoryDeleteItem => 'Xoá mặt hàng';

  @override
  String get inventoryUnitRequired => 'Vui lòng chọn đơn vị';

  @override
  String get inventoryLowStock => 'Sắp hết';

  @override
  String get inventoryExpiringSoon => 'HSD sắp tới';

  @override
  String get inventoryPendingSync => 'Chưa đồng bộ';

  @override
  String get inventoryConflict => 'Xung đột';

  @override
  String get inventoryConflictMessage =>
      'Dữ liệu đã bị thay đổi bởi thành viên khác. Đang làm mới…';

  @override
  String get inventoryYours => 'Của bạn';

  @override
  String get inventoryServer => 'Trên server';

  @override
  String get inventoryUseServer => 'Dùng của server';

  @override
  String get inventoryKeepMine => 'Giữ của tôi';

  @override
  String get inventoryName => 'Tên';

  @override
  String get inventoryQuantityLabel => 'Số lượng';

  @override
  String get inventoryCategory => 'Nhóm';

  @override
  String get inventoryExpiry => 'HSD';

  @override
  String get inventoryVersion => 'Phiên bản';

  @override
  String get mealplanAddDish => 'Thêm món';

  @override
  String get mealplanConfirmed => 'Đã xác nhận';

  @override
  String get mealplanAddSuggestion => 'Thêm gợi ý';

  @override
  String get mealplanWaitingForVote => 'Chờ vote';

  @override
  String get mealplanVoting => 'Đang vote';

  @override
  String get mealplanSelectedDish => 'Món đã chọn';

  @override
  String get mealplanAiSuggestion => 'Gợi ý từ AI';

  @override
  String get mealplanStartCooking => 'Bắt đầu nấu';

  @override
  String get mealplanDeleteDishTitle => 'Xoá món này?';

  @override
  String get mealplanDeleteDishMessage => 'Xóa món này khỏi bữa ăn?';

  @override
  String get mealplanDeleteDish => 'Xoá món';

  @override
  String get mealplanNeedsMore => 'Cần thêm:';

  @override
  String get mealplanMainIngredientPrefix => '[Chính] ';

  @override
  String get mealplanNoReason => 'Không có lý do';

  @override
  String get mealplanAiGenerated => 'AI sinh';

  @override
  String mealplanContainsAllergens(Object tags) {
    return 'Món này chứa: $tags';
  }

  @override
  String get mealplanAllergenUnverified => 'Chưa kiểm chứng dị ứng cho món này';

  @override
  String get mealplanSuggestionsTitle => 'Gợi ý món ăn';

  @override
  String get mealplanSuggestionsUnavailable =>
      'Không tải được gợi ý món. Bạn có thể thử lại hoặc chọn từ công thức.';

  @override
  String get mealplanSuggestionsExhausted =>
      'Chưa có gợi ý để chọn. Bạn có thể tạo gợi ý mới.';

  @override
  String get mealplanAddShoppingList => 'Thêm vào danh sách mua sắm';

  @override
  String get mealplanShoppingListUnavailable =>
      'Danh sách mua sắm sẽ ra mắt trong bản sau.';

  @override
  String get mealplanChooseDish => 'Chọn món';

  @override
  String get mealplanUnableToChoose => 'Không chọn được';

  @override
  String get mealplanActionRolledBack =>
      'Chưa lưu được lựa chọn. Hãy tải lại gợi ý và thử lại.';

  @override
  String get mealplanVoteSession => 'Phiên vote';

  @override
  String mealplanClosesAt(Object time) {
    return 'Đóng lúc: $time';
  }

  @override
  String get mealplanVoteSuggestionsUnavailable =>
      'Phiên đã tồn tại nhưng chưa tải lại được danh sách gợi ý. Bấm Làm mới hoặc chờ thành viên khác vote.';

  @override
  String get mealplanNoVotes => 'Chưa ai vote.';

  @override
  String get mealplanVoted => 'Đã vote';

  @override
  String get mealplanVote => 'Vote';

  @override
  String get mealplanCloseVoting => 'Đóng vote';

  @override
  String get cookingPendingShoppingTitle => 'Vẫn còn thực phẩm chưa mua';

  @override
  String cookingPendingShoppingMessage(int count) {
    return 'Món này còn $count thực phẩm chưa mua trong danh sách đi chợ:';
  }

  @override
  String get cookingPendingShoppingUnassigned => 'Chưa ai nhận';

  @override
  String get cookingPendingShoppingGoShopping => 'Đi chợ & phân công';

  @override
  String get cookingPendingShoppingCookAnyway => 'Vẫn nấu';

  @override
  String get recipesTitle => 'Công thức';

  @override
  String get recipesAll => 'Tất cả';

  @override
  String get recipesFavorites => 'Yêu thích';

  @override
  String get recipesSearch => 'Tìm công thức…';

  @override
  String get recipesFilters => 'Bộ lọc';

  @override
  String get recipesFilterDiet => 'Chế độ ăn';

  @override
  String get recipesFilterDifficulty => 'Độ khó';

  @override
  String get recipesFilterPrepTime => 'Thời gian chuẩn bị';

  @override
  String get recipesNoResults => 'Không tìm thấy công thức phù hợp.';

  @override
  String get recipesNoFavorites => 'Bạn chưa lưu công thức yêu thích nào.';

  @override
  String get recipesLoadMore => 'Tải thêm';

  @override
  String get recipesListChanged => 'Danh sách yêu thích đã thay đổi.';

  @override
  String get recipesReload => 'Tải lại danh sách';

  @override
  String get recipeIngredients => 'Nguyên liệu';

  @override
  String get recipeSteps => 'Các bước nấu';

  @override
  String get recipeNutrition => 'Dinh dưỡng mỗi phần ăn';

  @override
  String recipePrepTime(int minutes) {
    return 'Chuẩn bị: $minutes phút';
  }

  @override
  String recipeCookTime(int minutes) {
    return 'Nấu: $minutes phút';
  }

  @override
  String recipeServes(int count) {
    return 'Khẩu phần: $count';
  }

  @override
  String get recipeDifficulty => 'Độ khó';

  @override
  String get recipeDifficultyEasy => 'Dễ';

  @override
  String get recipeDifficultyMedium => 'Trung bình';

  @override
  String get recipeDifficultyHard => 'Khó';

  @override
  String get recipeStartCooking => 'Bắt đầu nấu';

  @override
  String get recipeNoSteps => 'Công thức này chưa có các bước nấu.';

  @override
  String get recipeYourRating => 'Đánh giá của bạn';

  @override
  String get recipeClearRating => 'Xoá đánh giá';

  @override
  String recipeHouseholdFavorites(int count) {
    return '$count thành viên trong Nhà đã lưu';
  }

  @override
  String get inventoryHistoryTitle => 'Lịch sử kho';

  @override
  String get inventoryHistoryOpen => 'Xem lịch sử thay đổi';

  @override
  String inventoryHistoryCurrentQuantity(Object quantity, Object unit) {
    return 'Hiện còn $quantity $unit';
  }

  @override
  String get inventoryHistoryLoadFailed => 'Không tải được lịch sử kho.';

  @override
  String get inventoryHistoryEmpty =>
      'Mặt hàng này chưa có thay đổi nào được ghi lại.';

  @override
  String get inventoryHistoryLoadMore => 'Xem thêm';

  @override
  String inventoryHistoryRemaining(Object quantity) {
    return 'Còn $quantity';
  }

  @override
  String get inventoryHistoryReasonBought => 'Nhập vào kho';

  @override
  String get inventoryHistoryReasonCooked => 'Đã sử dụng';

  @override
  String get inventoryHistoryReasonExpired => 'Đã hết hạn';

  @override
  String get inventoryHistoryReasonWaste => 'Đã bỏ đi';

  @override
  String get inventoryHistoryReasonCorrected => 'Điều chỉnh số liệu';

  @override
  String get inventoryWasteTitle => 'Vì sao thực phẩm bị bỏ đi?';

  @override
  String get inventoryWasteSubtitle =>
      'Chọn một lý do để giúp gia đình giảm lãng phí.';

  @override
  String get inventoryWasteOverbought => 'Mua dư, dùng không hết';

  @override
  String get inventoryWasteForgotten => 'Quên trong tủ, đã quá hạn';

  @override
  String get inventoryWasteSpoiledEarly => 'Hỏng trước hạn';

  @override
  String get inventoryWasteUntagged => 'Chưa ghi nguyên nhân';

  @override
  String get notificationInventoryUpdated => 'Đã cập nhật kho';

  @override
  String get notificationInventoryAlreadyUsed =>
      'Món này đã được đánh dấu đã dùng';

  @override
  String get notificationInventoryAlreadyDiscarded => 'Món này đã được bỏ đi';

  @override
  String get notificationInventoryAlreadyProcessed => 'Món này đã được xử lý';

  @override
  String get notificationInventoryGone => 'Món này không còn trong kho';

  @override
  String get notificationInventoryReadonly =>
      'Tài khoản của bạn chỉ có quyền xem';

  @override
  String get notificationNoNetwork => 'Không có mạng — hãy thử lại';

  @override
  String get notificationActionFailed =>
      'Không thực hiện được thao tác từ thông báo';

  @override
  String get notificationActionCookToday => 'Nấu hôm nay';

  @override
  String get notificationActionMarkUsed => 'Đã dùng';

  @override
  String get notificationActionDiscard => 'Bỏ đi';

  @override
  String get notificationQuickActionProcessing => 'Đang cập nhật kho…';

  @override
  String get notificationQuickActionSessionExpired =>
      'Phiên đăng nhập đã hết — chạm để đăng nhập';

  @override
  String get notificationQuickActionOpenApp => 'Chạm để mở ứng dụng';

  @override
  String get notificationQuickActionRetry => 'Không thực hiện được — thử lại';

  @override
  String get inventoryOcrScanAction => 'Quét hoá đơn hoặc mặt hàng';

  @override
  String get inventoryOcrScanTitle => 'Quét ảnh thêm vào kho';

  @override
  String get inventoryOcrModeItem => 'Từng món';

  @override
  String get inventoryOcrModeReceipt => 'Hoá đơn / tủ lạnh';

  @override
  String get inventoryOcrFrameHint =>
      'Đưa mặt hàng hoặc hoá đơn rõ nét vào trong khung';

  @override
  String get inventoryOcrItemHint =>
      'Chụp rõ từng món để AI nhận diện chính xác nhất';

  @override
  String get inventoryOcrReceiptHint =>
      'Chụp trọn hoá đơn hoặc tủ lạnh ở nơi đủ sáng';

  @override
  String get inventoryOcrTakePhoto => 'Chụp ảnh';

  @override
  String get inventoryOcrChooseGallery => 'Chọn từ thư viện';

  @override
  String get inventoryOcrChooseAnother => 'Chọn ảnh khác';

  @override
  String get inventoryOcrAnalyzing => 'Đang phân tích ảnh…';

  @override
  String get inventoryOcrPermissionDenied =>
      'Chưa cấp quyền camera hoặc thư viện ảnh. Hãy mở Cài đặt để cấp quyền.';

  @override
  String get inventoryOcrImageTooLarge =>
      'Ảnh vẫn lớn hơn 2 MB sau khi nén. Vui lòng chọn ảnh khác.';

  @override
  String get inventoryOcrImageInvalid =>
      'Không đọc được ảnh này. Vui lòng chọn ảnh JPEG hoặc PNG hợp lệ.';

  @override
  String get inventoryOcrAiTimeout =>
      'AI phản hồi quá lâu. Ảnh của bạn vẫn được giữ để thử lại.';

  @override
  String get inventoryOcrAiUnavailable =>
      'Dịch vụ AI tạm thời chưa khả dụng. Ảnh của bạn vẫn được giữ để thử lại.';

  @override
  String get inventoryOcrAiRateLimit =>
      'Dịch vụ AI đang bận. Vui lòng chờ một chút rồi thử lại.';

  @override
  String get inventoryOcrContentFiltered =>
      'Ảnh này không phù hợp để phân tích. Vui lòng chọn ảnh khác.';

  @override
  String get inventoryOcrInvalidOutput =>
      'AI không tạo được kết quả phù hợp từ ảnh này. Vui lòng chọn ảnh khác.';

  @override
  String get inventoryOcrScanInProgress =>
      'Ảnh trước vẫn đang được xử lý — vui lòng đợi vài giây.';

  @override
  String get inventoryOcrNoHousehold =>
      'Hãy tạo hoặc tham gia Nhà trước khi quét mặt hàng.';

  @override
  String inventoryOcrResultTitle(int count) {
    return 'Kết quả quét ($count)';
  }

  @override
  String get inventoryOcrConfirmAll => 'Xác nhận tất cả';

  @override
  String get inventoryOcrEmpty =>
      'AI không nhận diện được mặt hàng nào trong ảnh này';

  @override
  String get inventoryOcrRetake => 'Chụp lại';

  @override
  String get inventoryOcrNeedsReview => 'Cần kiểm tra';

  @override
  String get inventoryOcrDuplicate => 'Đã có trong tồn kho';

  @override
  String inventoryOcrExpiryEstimate(Object date) {
    return 'HSD $date · AI ước lượng';
  }

  @override
  String inventoryOcrRawValue(Object quantity, Object unit) {
    return 'AI đọc từ ảnh: $quantity $unit';
  }

  @override
  String get inventoryOcrQuantityHint => 'Nhập số lượng';

  @override
  String get inventoryOcrQuantityInvalid => 'Nhập số lượng hợp lệ';

  @override
  String get inventoryOcrCompleteFields =>
      'Nhập đủ số lượng và đơn vị hợp lệ trước khi lưu';

  @override
  String get inventoryOcrSaveItem => 'Lưu mặt hàng này';

  @override
  String get inventoryOcrSaved => 'Đã lưu';

  @override
  String inventoryOcrSavingProgress(int saved, int total) {
    return 'Đang lưu $saved/$total…';
  }

  @override
  String inventoryOcrPartialFailure(int count) {
    return '$count mặt hàng chưa lưu được — thử lại hoặc bỏ qua bên dưới';
  }

  @override
  String get mealLogTitle => 'Nhật ký bữa ăn';

  @override
  String get mealLogToday => 'Hôm nay';

  @override
  String get mealLogEmpty => 'Chưa có nhật ký nào hôm nay';

  @override
  String get mealLogLogMeal => 'Ghi bữa ăn';

  @override
  String get mealLogSaving => 'Đang lưu…';

  @override
  String get mealLogSaveFailed => 'Lưu thất bại';

  @override
  String get mealLogRetry => 'Thử lại';

  @override
  String get mealLogDelete => 'Xoá';

  @override
  String get mealLogNeedsReview => 'Cần xác nhận';

  @override
  String get mealLogNoEstimate => 'Chưa có ước tính';

  @override
  String get mealLogConfirm => 'Xác nhận';

  @override
  String get mealLogConfirmed => 'Đã xác nhận';

  @override
  String mealLogCalories(double calories) {
    return '$calories kcal';
  }

  @override
  String mealLogGoalRemaining(int remaining) {
    return 'Còn lại $remaining kcal hôm nay';
  }

  @override
  String get mealLogSetCalorieGoal => 'Đặt mục tiêu calo';

  @override
  String get mealLogMealType => 'Loại bữa ăn';

  @override
  String get mealLogBreakfast => 'Bữa sáng';

  @override
  String get mealLogLunch => 'Bữa trưa';

  @override
  String get mealLogDinner => 'Bữa tối';

  @override
  String get mealLogSnack => 'Ăn vặt';

  @override
  String get mealLogDescriptionHint => 'Bạn đã ăn gì? (không bắt buộc)';

  @override
  String get mealLogAddPhoto => 'Thêm ảnh';

  @override
  String get mealLogPhotoTooLarge =>
      'Ảnh vẫn còn quá lớn sau khi nén — vui lòng chọn ảnh khác';

  @override
  String get mealLogChooseAnother => 'Chọn ảnh khác';

  @override
  String get mealLogCameraPermissionDenied =>
      'Quyền camera/thư viện bị từ chối. Hãy bật trong cài đặt để thêm ảnh.';

  @override
  String get mealLogPhotoInvalid => 'Không đọc được ảnh. Hãy chọn ảnh khác.';

  @override
  String get mealLogConfirmTitle => 'Xác nhận calo';

  @override
  String get mealLogConfirmAsIs => 'Chấp nhận như AI ước tính';

  @override
  String get mealLogEnterCalories => 'Nhập lượng calo';

  @override
  String get mealLogCaloriesInvalid => 'Nhập giá trị từ 0 đến 10000';

  @override
  String get mealLogCaloriesRequired => 'Vui lòng nhập calo trước';

  @override
  String get insightsTitleCalorie => 'Calo';

  @override
  String get insightsTitleMacro => 'Chất dinh dưỡng';

  @override
  String get insightsTitleAdherence => 'Mức Độ Tuân Thủ';

  @override
  String insightsMonthLabel(Object month, Object year) {
    return 'Tháng $month/$year';
  }

  @override
  String get insightsEmptyDiary =>
      'Chưa có bữa nào được ghi log trong tháng này';

  @override
  String get insightsEmptyAdherence => 'Household chưa có dữ liệu tuân thủ nào';

  @override
  String get insightsSetCalorieGoal => 'Đặt mục tiêu calo';

  @override
  String get insightsRetry => 'Thử lại';

  @override
  String get insightsLast7Days => '7 ngày gần nhất';

  @override
  String insightsAvgCalories(Object calories) {
    return 'Trung bình $calories kcal/ngày';
  }

  @override
  String insightsLoggedCount(Object count) {
    return '$count bữa đã ghi';
  }

  @override
  String insightsStreakText(Object best, Object current) {
    return '$current tuần liên tiếp · Kỷ lục $best';
  }

  @override
  String get insightsNoWeekData => 'Chưa có dữ liệu tuần';

  @override
  String insightsAdherenceStart(Object day, Object month, Object percent) {
    return '$percent% — từ $day/$month';
  }

  @override
  String insightsKcalPerDay(Object calories) {
    return '$calories kcal';
  }

  @override
  String get insightsHistoryTooltip => 'Tổng kết tháng';

  @override
  String insightsCalorieTooltip(Object calories, Object day, Object month) {
    return '$day/$month — $calories kcal';
  }

  @override
  String get recapTitle => 'Tổng kết tuần';

  @override
  String get recapNoHousehold =>
      'Tham gia một hộ gia đình để xem Tổng kết tuần';

  @override
  String get recapEmpty =>
      'Chưa có recap nào cho tuần này — recap đầu tiên sẽ có vào sáng Thứ Hai tuần sau.';

  @override
  String get recapError => 'Không tải được dữ liệu';

  @override
  String get recapHeroFallback =>
      'Chưa có insight cá nhân hoá cho bạn tuần này. Tiếp tục ghi log bữa ăn để tuần sau có insight chi tiết hơn!';

  @override
  String recapStreak(Object current) {
    return '$current tuần';
  }

  @override
  String recapStreakBest(Object best) {
    return 'Kỷ lục $best';
  }

  @override
  String recapMealsLogged(Object count) {
    return '$count bữa đã ghi';
  }

  @override
  String recapAvgCalories(Object calories) {
    return '$calories kcal/ngày';
  }

  @override
  String get recapAdherenceCaption =>
      'Bám sát kế hoạch bữa ăn — khác với % tuân thủ calo cá nhân bên dưới';

  @override
  String get recapEmptyInsights =>
      'Chưa có insight cá nhân hoá nào cho tuần này.';

  @override
  String recapNutrientGap(Object nutrient) {
    return 'Cần chú ý: $nutrient';
  }

  @override
  String get recapShare => 'Tổng kết tuần của nhà tôi trên Smart Kitchen!';

  @override
  String get recapShareFailed => 'Không thể chia sẻ ảnh, thử lại sau';

  @override
  String get recapShareTooltip => 'Chia sẻ recap';

  @override
  String get recapStreakError => 'Không tải được streak';

  @override
  String get recapStreakRetry => 'Thử lại streak';

  @override
  String get planningSlotConfigTitle => 'Khung giờ bữa ăn';

  @override
  String get planningSlotConfigTooltip => 'Cấu hình khung giờ bữa';

  @override
  String get planningSlotEveryDay => 'Mọi ngày';

  @override
  String get planningSlotByDay => 'Bữa riêng theo ngày';

  @override
  String get planningSlotByDayHint =>
      'Bữa ở đây được CỘNG THÊM vào nhóm \"Mọi ngày\", không thay thế.';

  @override
  String get planningSlotDefaultBanner =>
      'Gia đình đang dùng 3 bữa mặc định (07:00 / 12:00 / 18:00). Chỉnh bên dưới để tuỳ biến.';

  @override
  String get planningSlotNotRetroactive =>
      'Thay đổi chỉ áp dụng cho các bữa được tạo từ bây giờ — không ảnh hưởng lịch tuần đã có.';

  @override
  String get planningSlotAdd => 'Thêm bữa';

  @override
  String get planningSlotEmptyDay => 'Ngày này chưa có bữa riêng.';

  @override
  String get planningSlotSave => 'Lưu';

  @override
  String get planningSlotSaved => 'Đã lưu cấu hình bữa ăn';

  @override
  String get planningSlotSaveFailed => 'Không lưu được cấu hình bữa ăn.';

  @override
  String get planningSlotErrorEmpty => 'Cần giữ ít nhất 1 bữa.';

  @override
  String get planningSlotErrorTooMany => 'Tối đa 10 bữa cho mỗi gia đình.';

  @override
  String get planningSlotErrorDuplicate =>
      'Có 2 bữa trùng loại trong cùng nhóm ngày.';

  @override
  String get planningSlotErrorBlankLabel => 'Tên bữa không được để trống.';

  @override
  String get planningSlotFormAddTitle => 'Thêm bữa';

  @override
  String get planningSlotFormEditTitle => 'Sửa bữa';

  @override
  String get planningSlotFormType => 'Loại bữa';

  @override
  String get planningSlotFormLabel => 'Tên bữa';

  @override
  String get planningSlotFormTime => 'Giờ';

  @override
  String get planningSlotTypeBreakfast => 'Bữa sáng';

  @override
  String get planningSlotTypeLunch => 'Bữa trưa';

  @override
  String get planningSlotTypeDinner => 'Bữa tối';

  @override
  String get planningSlotTypeSnack => 'Bữa phụ';

  @override
  String get planningSlotTypeCustom => 'Tự đặt tên';

  @override
  String get planningSlotEdit => 'Sửa';

  @override
  String get planningConfirm => 'Xác nhận';

  @override
  String get planningGuestTitle => 'Khách ăn cùng';

  @override
  String get planningGuestTooltip => 'Khách ăn cùng tuần này';

  @override
  String get planningGuestScopeBanner =>
      'Khách ăn tạm thời — chỉ áp dụng cho kế hoạch tuần này, không lưu vào hồ sơ gia đình. Người ăn thường xuyên (con nhỏ, ông bà sống cùng) thì dùng mục Thành viên phụ thuộc trong hồ sơ gia đình.';

  @override
  String get planningGuestEmpty => 'Tuần này chưa có khách nào.';

  @override
  String get planningGuestAdd => 'Thêm khách';

  @override
  String get planningGuestUnnamed => 'Khách chưa đặt tên';

  @override
  String get planningGuestNoAllergen => 'Không dị ứng';

  @override
  String get planningGuestNameOptional => 'Tên khách (không bắt buộc)';

  @override
  String get planningGuestAllergens => 'Dị ứng';

  @override
  String get planningGuestCatalogFailed => 'Không tải được danh mục dị ứng.';

  @override
  String get planningGuestEditAllergens => 'Sửa dị ứng';

  @override
  String get planningGuestDelete => 'Xoá khách';

  @override
  String get planningGuestDeleteConfirm => 'Xoá khách này khỏi kế hoạch tuần?';

  @override
  String planningGuestRemovedHint(String name) {
    return 'Đã xoá $name. Các món đã bị chặn trước đó KHÔNG tự mở lại — hãy sinh gợi ý mới nếu muốn thử lại.';
  }

  @override
  String get planningGuestUpdated =>
      'Đã cập nhật. Gợi ý AI của tuần này có thể đã thay đổi.';

  @override
  String get planningGuestSave => 'Lưu';

  @override
  String get planningCandidateTitle => 'Gợi ý AI có kiểm chứng';

  @override
  String get planningCandidateTooltip => 'Gợi ý AI có kiểm chứng';

  @override
  String get planningCandidateExplainer =>
      'Danh sách hiển thị kết quả kiểm tra dị ứng, điểm và các tín hiệu gợi ý. Món có ⭐ được thuật toán đề xuất; tín hiệu lặp món mang tính tham khảo.';

  @override
  String get planningCandidateEmpty => 'Chưa có gợi ý nào cho món này.';

  @override
  String get planningCandidateEmptyWeek =>
      'Tuần này chưa có gợi ý AI nào. Mở một món và chọn gợi ý để AI sinh danh sách.';

  @override
  String get planningCandidateGenerate => 'Sinh gợi ý AI';

  @override
  String get planningCandidateGenerateFailed => 'Không sinh được gợi ý.';

  @override
  String get planningCandidateAllBlocked =>
      'Toàn bộ gợi ý bị chặn do dị ứng. Thử xoá bớt khách khỏi ràng buộc, hoặc chọn món thủ công.';

  @override
  String get planningCandidateAiLabel => 'Gợi ý AI';

  @override
  String get planningCandidateFinalPick =>
      'Lựa chọn cuối cùng — thuật toán xác nhận';

  @override
  String get planningCandidatePassed =>
      'Đã qua kiểm tra an toàn — chưa phải lựa chọn hàng đầu';

  @override
  String planningCandidateBlocked(String reason) {
    return 'Bị loại — $reason';
  }

  @override
  String get planningCandidateUnverified =>
      'CHƯA kiểm chứng dị ứng — gợi ý này chưa qua bộ lọc an toàn';

  @override
  String get planningCandidateBlockedUnknown => 'dị ứng chưa kiểm chứng';

  @override
  String planningCandidateScore(String score) {
    return 'Điểm $score';
  }

  @override
  String get planningCandidateBreakdown => 'Tín hiệu gợi ý';

  @override
  String planningCandidateWeight(String weight) {
    return 'trọng số $weight';
  }

  @override
  String get planningCandidateNoBreakdown => 'Chưa có dữ liệu tín hiệu gợi ý.';

  @override
  String planningCandidateSession(String time) {
    return 'Phiên gợi ý · $time';
  }

  @override
  String get planningFeatureInventoryCoverage => 'Nguyên liệu có sẵn';

  @override
  String get planningFeatureExpiryUrgency => 'Thực phẩm sắp hết hạn';

  @override
  String get planningFeatureRepetitionPenalty => 'Tín hiệu lặp trong kế hoạch';

  @override
  String get planningFeatureNutritionFit => 'Phù hợp dinh dưỡng';

  @override
  String get planningFeatureDietMatch => 'Hợp chế độ ăn';

  @override
  String get planningFeatureEffortFit => 'Phù hợp công sức';

  @override
  String get planningFeaturePreference => 'Sở thích';

  @override
  String get planningFeaturePrior => 'Mức ưu tiên gốc';

  @override
  String get planningFeatureNutrientBalance => 'Cân bằng dưỡng chất';

  @override
  String get planningFeatureRiskPenalty => 'Rủi ro dinh dưỡng';

  @override
  String get planningFeatureConstraintMatch => 'Khớp ràng buộc';

  @override
  String get planningFeatureGraphPath => 'Bằng chứng tri thức';

  @override
  String get planningRepetitionTitle => 'Món lặp trong kế hoạch';

  @override
  String get planningRepetitionTooltip => 'Xem món lặp trong kế hoạch';

  @override
  String planningRepetitionWindow(int days) {
    return 'Lùi $days ngày';
  }

  @override
  String planningRepetitionEmpty(int days) {
    return 'Không có món được gán lặp từ $days ngày trước đến hôm nay.';
  }

  @override
  String planningRepetitionCount(int count) {
    return 'Được gán $count lần';
  }

  @override
  String get tierFree => 'Free';

  @override
  String get tierPremium => 'Premium';

  @override
  String get tierUnknown => 'Không xác định';

  @override
  String tierPlanCurrent(String tier) {
    return 'Gói hiện tại: $tier';
  }

  @override
  String tierSeatUsage(int used, int limit) {
    return '$used/$limit ghế Chỉ xem';
  }

  @override
  String get tierChangePlan => 'Nâng cấp / Hạ cấp';

  @override
  String get tierOwnerOnlyTooltip => 'Chỉ chủ hộ (OWNER) mới có thể đổi gói';

  @override
  String get tierViewerOnlyTooltip =>
      'Bạn đang ở chế độ Chỉ xem — chỉ chủ hộ (OWNER) mới có thể đổi gói';

  @override
  String get tierRemoteViewerBanner =>
      'Bạn đang ở chế độ Chỉ xem (Remote Viewer) trong gia đình này — không thể mời/xoá/đổi vai trò thành viên. Liên hệ chủ hộ (OWNER) nếu cần thay đổi quyền.';

  @override
  String get tierRoleViewOnly => 'Chỉ xem';

  @override
  String get tierChangeRoleAction => 'Đổi vai trò';

  @override
  String tierChangeRoleTitle(String name) {
    return 'Đổi vai trò — $name';
  }

  @override
  String get tierChangeRoleMember =>
      'Thành viên (Member) — xem, vote, sửa kho bình thường';

  @override
  String get tierChangeRoleViewer =>
      'Chỉ xem (Remote Viewer) — không vote, không sửa kho, không quản lý thành viên';

  @override
  String tierChangeRoleSoftHint(String tier, int used, int limit) {
    return 'Gói $tier đã dùng $used/$limit ghế Chỉ xem. Bạn vẫn có thể thử — nếu vượt giới hạn, hệ thống sẽ báo và đề nghị nâng cấp.';
  }

  @override
  String get tierConfirm => 'Xác nhận';

  @override
  String get tierChangeRoleSuccess => 'Đã đổi vai trò';

  @override
  String get tierUpsellTitle => 'Đã hết ghế Chỉ xem';

  @override
  String tierUpsellBody(int limit) {
    return 'Gói hiện tại chỉ cho $limit ghế Chỉ xem. Nâng cấp lên Premium để có tối đa 5 ghế.';
  }

  @override
  String tierUpsellBodyMaxed(int limit) {
    return 'Gói hiện tại đã dùng hết $limit ghế Chỉ xem. Đổi một người về Thành viên để giải phóng ghế.';
  }

  @override
  String get tierUpgradeToPremium => 'Nâng cấp lên Premium';

  @override
  String get tierDowngradeToFree => 'Hạ cấp về Free';

  @override
  String get tierClose => 'Đóng';

  @override
  String get tierUpgradeTitle => 'Gói household';

  @override
  String get tierDisclaimer =>
      'Đây KHÔNG phải luồng mua hàng thật. Đây là công tắc demo/QA để bạn thử luồng tier-gate. Trong bản phát hành thật, thao tác này sẽ được thay bằng luồng thanh toán có xác thực.';

  @override
  String get tierOwnerOnlyBlocked =>
      'Chỉ chủ hộ (OWNER) mới có thể thay đổi gói household.';

  @override
  String get tierCompareFree => 'Free — 1 ghế Chỉ xem';

  @override
  String get tierComparePremium => 'Premium — 5 ghế Chỉ xem';

  @override
  String get tierCompareSpend =>
      'Chi tiêu theo nhóm + xu hướng 8 tuần: Free ✗ / Premium ✓';

  @override
  String tierDowngradeWarning(int used) {
    return 'Household hiện có $used thành viên Chỉ xem, vượt giới hạn gói Free (1). Các thành viên Chỉ xem hiện tại KHÔNG bị ảnh hưởng ngay, nhưng bạn sẽ không thể thêm mới cho tới khi giảm số lượng hoặc nâng cấp lại.';
  }

  @override
  String get tierRosterFailed =>
      'Không tải được danh sách thành viên — cảnh báo vượt ghế Chỉ xem khi hạ cấp có thể bị thiếu.';

  @override
  String get tierUnknownBody =>
      'Không xác định được gói hiện tại — vui lòng thử tải lại.';

  @override
  String get tierRetryLoad => 'Thử tải lại';

  @override
  String get tierRetryFailed =>
      'Vẫn chưa xác định được — vui lòng đăng nhập lại.';

  @override
  String tierConfirmTitle(String tier) {
    return 'Chuyển sang gói $tier?';
  }

  @override
  String tierUpdated(String tier) {
    return 'Đã cập nhật gói household thành $tier';
  }

  @override
  String get tierMemberViewerInfo =>
      'Vai trò: Chỉ xem (Remote Viewer) — không vote, không sửa kho, không quản lý thành viên.';

  @override
  String get budgetLoading => 'Đang tải ngân sách…';

  @override
  String get budgetLoadFailed => 'Không tải được ngân sách';

  @override
  String get budgetNotSet => 'Chưa đặt ngân sách cho nhà mình';

  @override
  String budgetCurrentWeekly(String amount) {
    return 'Ngân sách tuần: $amount';
  }

  @override
  String budgetCurrentMonthly(String amount) {
    return 'Ngân sách tháng: $amount';
  }

  @override
  String get budgetSet => 'Đặt ngân sách';

  @override
  String get budgetEdit => 'Sửa';

  @override
  String get budgetOwnerOnlyTooltip =>
      'Chỉ chủ hộ (OWNER) mới có thể đặt ngân sách';

  @override
  String get budgetLoadingTooltip => 'Đang tải ngân sách hiện tại…';

  @override
  String get budgetUpsell =>
      'Xem chi tiêu theo nhóm & xu hướng 8 tuần với Premium';

  @override
  String get budgetSheetTitle => 'Ngân sách gia đình';

  @override
  String get budgetPeriodWeek => 'Tuần';

  @override
  String get budgetPeriodMonth => 'Tháng';

  @override
  String get budgetAmountLabel => 'Số tiền';

  @override
  String get budgetAmountInvalid =>
      'Nhập số tiền lớn hơn 0 và tối đa 999.999.999.999';

  @override
  String get budgetNotRetroactive =>
      'Ngân sách áp dụng cho các tuần TỚI. Recap của những tuần đã tổng kết vẫn giữ ngân sách tại thời điểm tổng kết.';

  @override
  String get budgetSave => 'Lưu';

  @override
  String get budgetUpdated => 'Đã cập nhật ngân sách';

  @override
  String get recapWasteSpendTitle => 'Lãng phí & Chi tiêu';

  @override
  String recapWeekRange(String start, String end) {
    return 'Thứ Hai $start – Chủ Nhật $end';
  }

  @override
  String get recapWasteTitle => 'Lãng phí tuần này';

  @override
  String recapWasteCount(int count) {
    return '$count món bị bỏ đi';
  }

  @override
  String get recapWasteNone =>
      '🎉 Tuần này nhà bạn không bỏ đi món nào. Giữ nhịp này nhé!';

  @override
  String get recapWasteOverbought => 'Mua dư';

  @override
  String get recapWasteForgotten => 'Quên trong tủ';

  @override
  String get recapWasteSpoiledEarly => 'Hỏng trước hạn';

  @override
  String get recapWasteUntagged => 'Chưa gắn nguyên nhân';

  @override
  String get recapWasteOther => 'Khác';

  @override
  String get recapSpendTitle => 'Chi tiêu tuần này';

  @override
  String get recapSpendNone => 'Chưa có món nào được nhập giá trong tuần này';

  @override
  String get recapSpendNoneHint =>
      'Nhập giá khi tick hoàn thành món trong danh sách đi chợ để thấy chi tiêu ở đây.';

  @override
  String recapSpendOfBudget(String spent, String budget) {
    return '$spent / $budget';
  }

  @override
  String recapSpendPercent(int percent) {
    return '$percent% ngân sách tuần';
  }

  @override
  String recapSpendOver(int percent, String amount) {
    return '$percent% ngân sách tuần · Vượt $amount';
  }

  @override
  String recapSpendCoverage(int priced, int completed) {
    return '$priced/$completed món đã nhập giá';
  }

  @override
  String get recapSetBudget => 'Đặt ngân sách';

  @override
  String get recapNoBudgetMember => 'Chủ hộ chưa đặt ngân sách cho nhà mình';

  @override
  String recapBudgetConvertedMonthly(String amount) {
    return 'Ngân sách tháng ($amount) đã được quy đổi theo tuần.';
  }

  @override
  String recapBudgetConvertedOther(String amount) {
    return 'Ngân sách bạn đặt ($amount) đã được quy đổi theo tuần.';
  }

  @override
  String get recapSpendByCategory => 'Chi tiêu theo nhóm';

  @override
  String get recapSpendTrend => 'Xu hướng 8 tuần';

  @override
  String get recapUncategorized => 'Chưa phân nhóm';

  @override
  String get recapSpendCategoryEmpty =>
      'Chưa có khoản chi nào được nhập giá tuần này';

  @override
  String get recapSpendUpsell =>
      'Xem chi tiêu theo nhóm và xu hướng 8 tuần với gói Premium';

  @override
  String get recapUpgradePremium => 'Nâng cấp lên Premium';

  @override
  String get recapSpendDetailNeutral =>
      'Chưa có dữ liệu chi tiết cho tuần này.';

  @override
  String get shoppingEmptyTitle => 'Danh sách mua sắm trống';

  @override
  String get shoppingEmptyBody =>
      'Thêm thực phẩm cần mua hoặc lên thực đơn tuần để tự động lên danh sách.';

  @override
  String get shoppingAddNeeded => 'Thêm đồ cần mua';

  @override
  String shoppingPendingCount(int count) {
    return 'Cần mua ($count)';
  }

  @override
  String shoppingCompletedCount(int count) {
    return 'Đã mua ($count)';
  }

  @override
  String shoppingFilterAll(int count) {
    return 'Tất cả ($count)';
  }

  @override
  String get shoppingAllBought => 'Tuyệt vời! Đã mua hết tất cả các món.';

  @override
  String get shoppingNoneBought => 'Chưa có món nào được đánh dấu đã mua.';

  @override
  String get shoppingAddItem => 'Thêm món';

  @override
  String get shoppingProgressTitle => 'Tiến độ đi chợ';

  @override
  String shoppingProgressDetail(int completed, int total, int percent) {
    return '$completed / $total món đã hoàn thành ($percent%)';
  }

  @override
  String shoppingPendingBadge(int count) {
    return '$count cần mua';
  }

  @override
  String get shoppingWeeklyMenuBadge => 'Thực đơn tuần';

  @override
  String get shoppingItemActions => 'Tuỳ chọn món';

  @override
  String get shoppingEditItem => 'Sửa món';

  @override
  String get shoppingDeleteItem => 'Xoá món';

  @override
  String get shoppingEditSheetTitle => 'Sửa món cần mua';

  @override
  String get shoppingDeleteConfirmTitle => 'Xoá món khỏi danh sách?';

  @override
  String shoppingDeleteConfirmMessage(String name) {
    return '\"$name\" sẽ bị xoá khỏi danh sách đi chợ của cả nhà.';
  }

  @override
  String shoppingItemDeleted(String name) {
    return 'Đã xoá \"$name\"';
  }

  @override
  String get shoppingItemUpdated => 'Đã cập nhật món';

  @override
  String get shoppingItemActionOffline =>
      'Cần có mạng và đồng bộ xong mới sửa/xoá được món này';

  @override
  String get shoppingDeleteForbidden =>
      'Chỉ chủ nhà hoặc người lập thực đơn mới xoá được món tự sinh';

  @override
  String get shoppingItemChangedElsewhere =>
      'Món vừa được thay đổi ở máy khác — danh sách đã tải lại, thử lại nhé';

  @override
  String get mealPlanFinishAdding => 'Hoàn thành thêm món';

  @override
  String get mealPlanFinishTitle => 'Cập nhật danh sách đi chợ';

  @override
  String get mealPlanFinishAddHeader => 'Sẽ thêm (còn thiếu):';

  @override
  String get mealPlanFinishRemoveHeader =>
      'Sẽ xoá (món đã bỏ khỏi bữa, chưa mua):';

  @override
  String get mealPlanFinishConfirm => 'Cập nhật đi chợ';

  @override
  String get mealPlanFinishInSync => 'Đi chợ đã khớp với bữa này';

  @override
  String mealPlanFinishDone(int added, int removed) {
    return 'Đi chợ: thêm $added, xoá $removed món';
  }

  @override
  String get mealPlanFinishLoadFailed =>
      'Không tải được danh sách đi chợ — kiểm tra mạng rồi thử lại';

  @override
  String get shoppingAddSheetTitle => 'Thêm món cần mua';

  @override
  String get shoppingNameHint => 'Tên thực phẩm, nguyên liệu...';

  @override
  String get shoppingNameLabel => 'Tên món *';

  @override
  String get shoppingQuantityLabel => 'Số lượng *';

  @override
  String get shoppingUnitLabel => 'Đơn vị *';

  @override
  String get shoppingCategoryLabel => 'Phân loại *';

  @override
  String get shoppingNameRequired => 'Vui lòng nhập tên món';

  @override
  String get shoppingQuantityInvalid => 'Số lượng phải là số lớn hơn 0';

  @override
  String get shoppingCategoryRequired => 'Vui lòng chọn phân loại';

  @override
  String get shoppingAddToList => 'Thêm vào danh sách';

  @override
  String get dependentListTitle => 'Người phụ thuộc';

  @override
  String get dependentAddProfile => 'Thêm hồ sơ';

  @override
  String get dependentLoadFailed => 'Không thể tải danh sách người phụ thuộc.';

  @override
  String get dependentEmptyTitle => 'Chưa có người phụ thuộc';

  @override
  String get dependentEmptyBody =>
      'Thêm hồ sơ con nhỏ hoặc người thân phụ thuộc để hệ thống tự động kiểm soát dị ứng và chế độ dinh dưỡng phù hợp.';

  @override
  String get dependentAllergenInfo =>
      'Hệ thống tự động loại trừ nguyên liệu gây dị ứng khi gợi ý thực đơn cho các thành viên phụ thuộc.';

  @override
  String dependentAgeAndBirth(int age, String date) {
    return '$age tuổi · Sinh $date';
  }

  @override
  String dependentAllergenChip(String name) {
    return 'Dị ứng: $name';
  }

  @override
  String get dependentNoAllergens => 'Chưa ghi nhận dị ứng';

  @override
  String get dependentProfileNav => 'Hồ sơ người phụ thuộc';

  @override
  String get dependentFormTitle => 'Thêm người phụ thuộc';

  @override
  String get dependentNameRequired => 'Vui lòng nhập tên người phụ thuộc';

  @override
  String get dependentSaveFailed => 'Có lỗi xảy ra khi lưu hồ sơ';

  @override
  String get dependentNameLabel => 'Họ và tên hoặc biệt danh *';

  @override
  String get dependentNameHint => 'Ví dụ: Bé An, Bé Miu, Ông nội...';

  @override
  String get dependentDateOfBirth => 'Ngày sinh';

  @override
  String get dependentSave => 'Lưu hồ sơ';

  @override
  String dependentCardCount(int count) {
    return '$count hồ sơ';
  }

  @override
  String get dependentCardEmpty => 'Chưa có hồ sơ nào';

  @override
  String get dependentCardViewAll => 'Xem tất cả';

  @override
  String get dependentCardView => 'Xem';

  @override
  String get dependentDobHint => 'Không bắt buộc';

  @override
  String get dependentDobNotSet => 'Chưa cập nhật';

  @override
  String get dependentDobClear => 'Xoá ngày sinh';

  @override
  String get dependentNameTooLong => 'Tên tối đa 255 ký tự';

  @override
  String get dependentCreatedToast => 'Đã tạo hồ sơ';

  @override
  String get dependentGuardianInactiveTag => 'Cần đổi giám hộ';

  @override
  String get dependentGuardianInactiveBanner =>
      'Người giám hộ của hồ sơ này đã rời gia đình hoặc không còn quyền quản lý. Dữ liệu vẫn được giữ nguyên; chủ hộ cần chỉ định người giám hộ mới để tiếp tục chỉnh sửa.';

  @override
  String get dependentGuardianInactiveOwnerHint =>
      'Khi chưa có người giám hộ hoạt động, chỉ chủ hộ sửa được hồ sơ sức khoẻ.';

  @override
  String get dependentSummarySection => 'Tóm tắt';

  @override
  String get dependentHealthRestricted =>
      'Chỉ người giám hộ hiện tại hoặc chủ hộ mới xem được hồ sơ sức khoẻ đầy đủ.';

  @override
  String get dependentGuardianSection => 'Người giám hộ';

  @override
  String dependentGuardianYou(String name) {
    return '$name (bạn)';
  }

  @override
  String get dependentGuardianLeft => 'Đã rời gia đình';

  @override
  String get dependentGuardianNoManage => 'Không còn quyền quản lý';

  @override
  String get dependentChangeGuardian => 'Đổi người giám hộ';

  @override
  String dependentChangeGuardianTitle(String name) {
    return 'Đổi người giám hộ — $name';
  }

  @override
  String get dependentChangeGuardianEmpty =>
      'Không có thành viên nào có thể làm người giám hộ.';

  @override
  String get dependentGuardianChangedToast => 'Đã đổi người giám hộ';

  @override
  String get dependentDelete => 'Xoá hồ sơ';

  @override
  String dependentDeleteConfirmTitle(String name) {
    return 'Xoá hồ sơ \"$name\"?';
  }

  @override
  String get dependentDeleteConfirmBody =>
      'Toàn bộ dữ liệu sức khoẻ và dị ứng của hồ sơ này sẽ bị xoá vĩnh viễn. Không thể hoàn tác.';

  @override
  String get dependentDeletedToast => 'Đã xoá hồ sơ';

  @override
  String get dependentNotFoundTitle => 'Không tìm thấy hồ sơ này';

  @override
  String get dependentNotFoundBody =>
      'Hồ sơ có thể đã bị xoá hoặc không thuộc gia đình của bạn.';

  @override
  String get dependentBackToList => 'Quay lại danh sách';

  @override
  String get dependentNoAccessTitle => 'Không có quyền truy cập';

  @override
  String get dependentNoAccessHealth =>
      'Chỉ người giám hộ hiện tại hoặc chủ hộ mới sửa được hồ sơ sức khoẻ này.';

  @override
  String get dependentNoAccessAllergens =>
      'Chỉ người giám hộ hiện tại hoặc chủ hộ mới sửa được danh sách dị ứng này.';

  @override
  String dependentHealthTitle(String name) {
    return 'Sức khoẻ — $name';
  }

  @override
  String dependentAllergensTitle(String name) {
    return 'Dị ứng — $name';
  }

  @override
  String get dependentErrorForbidden =>
      'Bạn không có quyền thực hiện thao tác này.';

  @override
  String get dependentErrorNoHousehold =>
      'Bạn cần tham gia một gia đình trước.';

  @override
  String get dependentErrorInvalidGuardian =>
      'Không thể chỉ định người này làm giám hộ. Hãy chọn thành viên khác.';

  @override
  String get dependentGuardianCurrent => 'Hiện tại';

  @override
  String dependentBornOn(String date) {
    return 'Sinh $date';
  }

  @override
  String get dependentHealthUnknownDiet =>
      'Hồ sơ có chế độ ăn mà ứng dụng chưa hỗ trợ. Hãy cập nhật ứng dụng để chỉnh sửa.';

  @override
  String dependentMoreChip(int count) {
    return '+$count';
  }

  @override
  String get inventoryStatTotal => 'Tổng mặt hàng';

  @override
  String get inventoryStatExpiring => 'Sắp hết hạn';

  @override
  String get inventoryStatLowStock => 'Sắp hết hàng';

  @override
  String get inventoryValidationNameEmpty => 'Tên không được để trống';

  @override
  String get inventoryValidationQuantityEmpty => 'Số lượng không được để trống';

  @override
  String get inventoryValidationQuantityNotNumber => 'Phải là số';

  @override
  String get inventoryValidationQuantityNotPositive =>
      'Số lượng phải lớn hơn 0';

  @override
  String get inventoryValidationQuantityNegative => 'Số lượng không được âm';

  @override
  String get inventoryValidationQuantityNotWhole =>
      'Với đơn vị \"quả/cái\", phải là số nguyên';

  @override
  String get mealPlanStatusConfirmed => 'Đã chốt';

  @override
  String get mealPlanStatusVoting => 'Bình chọn';

  @override
  String get mealPlanStatusSuggested => 'Gợi ý';

  @override
  String get mealPlanStatusEmpty => 'Chưa chọn';

  @override
  String get familyRoleMember => 'Thành viên';

  @override
  String tierUpdatedClaimStale(String tier) {
    return 'Đã cập nhật gói household thành $tier. Nếu màn hình vẫn hiện gói cũ, hãy đăng nhập lại.';
  }

  @override
  String get planningPlanNotReady =>
      'Kế hoạch tuần chưa tải xong — vui lòng thử lại.';

  @override
  String get sessionExpiredError =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get shoppingPriceQuestion => 'Bạn trả bao nhiêu?';

  @override
  String get shoppingPriceOptional => 'Có thể bỏ qua';

  @override
  String get shoppingPriceLabel => 'Giá';

  @override
  String get shoppingPriceZeroHint =>
      '0 ₫ nghĩa là miễn phí. Nếu không nhớ giá, hãy bấm Bỏ qua.';

  @override
  String get shoppingPriceSkip => 'Bỏ qua';

  @override
  String get shoppingPriceSave => 'Lưu';

  @override
  String get shoppingPriceLostItemDeleted =>
      'Món đã bị xoá trên máy khác — giá bạn nhập chưa được lưu.';

  @override
  String get shoppingPriceLostListClosed =>
      'Danh sách đã sang tuần mới — giá bạn nhập chưa được lưu.';

  @override
  String get shoppingPriceNotSaved =>
      'Món này vừa được người khác cập nhật — giá bạn nhập chưa được lưu. Bỏ tick rồi tick lại để nhập lại giá.';

  @override
  String get shoppingAssign => 'Giao';

  @override
  String get shoppingAssignedMe => 'Tôi';

  @override
  String get shoppingAssigneeFormer => 'Thành viên cũ';

  @override
  String get shoppingAssignNeedsNetwork => 'Cần mạng để giao việc';

  @override
  String get shoppingAssigneeInvalid =>
      'Người này không còn nhận việc được — đã tải lại danh sách thành viên.';

  @override
  String get shoppingAssignToMe => 'Tôi nhận';

  @override
  String get shoppingUnassign => 'Bỏ giao';

  @override
  String get shoppingMineEmpty => 'Chưa có món nào được giao cho bạn.';

  @override
  String shoppingFilterMine(int count) {
    return 'Của tôi ($count)';
  }

  @override
  String get shoppingFilterMineNoCount => 'Của tôi';

  @override
  String get shoppingAssignSyncing =>
      'Đang đồng bộ… giao việc được sau khi xong';

  @override
  String get shoppingAssigneeUnknown => 'Đã giao';

  @override
  String navShoppingAssignedSemantics(int count) {
    return 'Đi chợ, $count món được giao cho bạn';
  }

  @override
  String shoppingAddRejected(String name) {
    return 'Không thêm được \"$name\" — máy chủ từ chối nên món đã bị gỡ khỏi danh sách. Vui lòng thêm lại.';
  }

  @override
  String get aiOfflineModeBanner =>
      'Đang dùng chế độ ngoại tuyến — kết quả có thể đơn giản hơn bình thường';

  @override
  String get aiOfflineEstimate => 'Ước tính offline';

  @override
  String aiOfflineEstimateConfidence(int percent) {
    return 'Ước tính offline · $percent%';
  }

  @override
  String get shoppingManageCategoriesTooltip => 'Quản lý danh mục';

  @override
  String get shoppingShareTooltip => 'Chia sẻ danh sách';

  @override
  String get shoppingCategoriesTitle => 'Danh mục đi chợ';

  @override
  String get shoppingCategoriesEmpty =>
      'Chưa có danh mục nào. Tạo danh mục để tô màu và sắp xếp danh sách đi chợ theo cách của bạn.\nDanh mục chỉ lưu trên thiết bị này, không đồng bộ cho cả nhà.';

  @override
  String get shoppingCategoriesLocalNote =>
      'Chỉ lưu trên thiết bị này — không đồng bộ cho cả nhà.';

  @override
  String get shoppingCategoryAdd => 'Thêm danh mục';

  @override
  String get shoppingCategoryEdit => 'Sửa danh mục';

  @override
  String get shoppingCategoryNameLabel => 'Tên danh mục';

  @override
  String get shoppingCategoryColorLabel => 'Màu';

  @override
  String get shoppingCategorySave => 'Lưu';

  @override
  String get shoppingCategoryCancel => 'Huỷ';

  @override
  String get shoppingCategoryDelete => 'Xoá';

  @override
  String get shoppingCategoryErrEmpty => 'Tên danh mục không được để trống';

  @override
  String shoppingCategoryErrTooLong(int max) {
    return 'Tên danh mục tối đa $max ký tự';
  }

  @override
  String get shoppingCategoryErrDuplicate => 'Đã có danh mục trùng tên';

  @override
  String get shoppingCategoriesLoadFailed => 'Không tải được danh mục';

  @override
  String get shoppingCategoryErrSaveFailed => 'Không thể lưu, vui lòng thử lại';

  @override
  String shoppingCategoryDeleteConfirm(String name) {
    return 'Xoá danh mục \"$name\"? Các mặt hàng đã gán danh mục này vẫn giữ nguyên, chỉ mất màu/vị trí gợi ý.';
  }

  @override
  String get shoppingShareTitle => 'Chia sẻ danh sách mua sắm';

  @override
  String get shoppingShareCopyText => 'Sao chép dạng text';

  @override
  String get shoppingShareNoItems => 'Chưa có mặt hàng nào để chia sẻ';

  @override
  String get shoppingShareLink => 'Chia sẻ link';

  @override
  String get shoppingShareComingSoon => 'Sắp ra mắt';

  @override
  String get shoppingShareCopied => 'Đã sao chép danh sách vào bộ nhớ tạm';

  @override
  String get shoppingShareTextHeader => '🛒 Danh sách mua sắm';

  @override
  String shoppingShareTextProgress(int checked, int total) {
    return 'Đã mua: $checked/$total';
  }

  @override
  String get shoppingShareTextUncategorized => 'Chưa phân loại';

  @override
  String get shoppingShareTextFooter => 'Tạo từ Smart Kitchen App';

  @override
  String get attendanceTitle => 'Xác nhận ăn';

  @override
  String get attendanceYes => 'Có ăn';

  @override
  String get attendanceNo => 'Không ăn';

  @override
  String get attendanceUnknown => 'Chưa phản hồi';

  @override
  String get attendanceClear => 'Bỏ phản hồi';

  @override
  String get attendanceClosed =>
      'Bữa này đã qua hoặc bạn chỉ có quyền xem nên không đổi được xác nhận ăn.';

  @override
  String get attendanceLoadFailed => 'Không tải được xác nhận ăn';

  @override
  String get attendanceSaveFailed => 'Chưa lưu được phản hồi. Hãy thử lại.';

  @override
  String get attendanceMember => 'Thành viên';

  @override
  String attendanceSummary(int yes, int unknown) {
    return '$yes thành viên có ăn · $unknown chưa phản hồi';
  }

  @override
  String get mealPlanConfirm => 'Chốt thực đơn tuần';

  @override
  String get mealPlanConfirmed => 'Thực đơn tuần đã chốt';

  @override
  String get mealPlanConfirmFailed =>
      'Chưa chốt được. Cần có món đã chọn và không còn món để trống.';

  @override
  String get mealPlanGenerateSuggestions => 'Tạo gợi ý món';

  @override
  String get mealPlanChooseRecipe => 'Chọn từ công thức';

  @override
  String get mealComposeTitle => 'Thực đơn tự động';

  @override
  String get mealComposePeoplePolicy =>
      'Thành viên chưa phản hồi được tính là có ăn. Có thể mua toàn bộ nguyên liệu.';

  @override
  String mealComposePeopleCount(int count) {
    return '$count người ăn';
  }

  @override
  String get mealComposeReplaceTitle => 'Thay toàn bộ thực đơn bữa này?';

  @override
  String get mealComposeReplaceBody =>
      'Chỉ thay món hiện có sau khi tạo xong bộ thực đơn mới.';

  @override
  String get mealComposeRegenerate => 'Gợi ý lại cả bữa';

  @override
  String get mealComposeGenerate => 'Tạo thực đơn';

  @override
  String get mealComposeLoading => 'Đang chọn thực đơn hoàn chỉnh…';

  @override
  String get mealComposeRunning =>
      'Yêu cầu vẫn đang xử lý. Bấm kiểm tra để tải kết quả; thực đơn cũ được giữ nguyên.';

  @override
  String get mealComposeIncomplete =>
      'Chưa tìm được bộ thực đơn phù hợp. Thực đơn cũ được giữ nguyên.';

  @override
  String get mealComposeStale =>
      'Bữa ăn hoặc người ăn đã thay đổi. Tải lại trước khi tạo tiếp.';

  @override
  String get mealComposeDisabled =>
      'Máy chủ chưa bật tính năng tạo thực đơn tự động.';

  @override
  String get mealComposeFailed =>
      'Chưa hoàn tất. Kiểm tra kết quả yêu cầu trước khi thử lại.';

  @override
  String get mealComposeRefresh => 'Kiểm tra hoặc tải lại';

  @override
  String get mealComposeShopping => 'Nguyên liệu cần mua';

  @override
  String get mealComposeNutritionWarning =>
      'Dinh dưỡng hoặc mục tiêu calo đang được ước tính, chưa đủ dữ liệu hoặc ngoài khoảng mục tiêu.';

  @override
  String mealComposeDishServings(String name, String servings) {
    return '$name · $servings khẩu phần công thức';
  }

  @override
  String mealComposeCalories(int calories) {
    return 'Tổng dự kiến: $calories kcal';
  }

  @override
  String get mealComposeSyncPending =>
      'Thực đơn đã được lưu. Hãy làm mới để đồng bộ lại lịch ăn.';

  @override
  String get mealplanOutcomeUnknown =>
      'Chưa xác định kết quả thao tác. Đọc lại để xem dữ liệu đã lưu; dữ liệu vẫn có thể thay đổi nếu yêu cầu trước đó hoàn tất. Tiếp tục chỉ dùng dữ liệu bạn vừa đọc.';

  @override
  String get mealplanReadAgain => 'Đọc lại';

  @override
  String get mealplanContinueSnapshot => 'Tiếp tục từ dữ liệu vừa đọc';

  @override
  String get mealplanSuggestionsChanged =>
      'Gợi ý đã thay đổi. Đọc lại gợi ý đã lưu trước khi chọn lại.';

  @override
  String get healthProfileDietUnset => 'Chưa chọn chế độ ăn';

  @override
  String get healthProfileDietNone => 'Không chọn chế độ ăn đặc biệt';

  @override
  String get healthProfileDietHelp =>
      'Ràng buộc chế độ ăn tùy luồng lập thực đơn. Khai dị ứng riêng; chọn không gluten không đồng nghĩa đã khai dị ứng Gluten.';

  @override
  String get healthProfileHeightInvalid =>
      'Nhập chiều cao từ 1 đến 300 cm hoặc để trống';

  @override
  String get healthProfileWeightInvalid =>
      'Nhập cân nặng từ 1 đến 500 kg hoặc để trống';

  @override
  String get unitKcal => 'kcal';

  @override
  String get planningRepetitionWindowHint =>
      'Thống kê món đã gán trong kế hoạch; gồm cả ngày bắt đầu và ngày kết thúc.';

  @override
  String planningRepetitionRange(String start, String end) {
    return 'Từ $start đến $end';
  }

  @override
  String get planningCandidateSignalsHint =>
      'Các thanh thể hiện mức tín hiệu tham khảo.';

  @override
  String get planningRepetitionContextHint =>
      'Thông tin lặp món phản ánh các món đã gán trong kế hoạch.';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get commonLoading => 'Đang xử lý…';

  @override
  String get commonShowPassword => 'Hiện mật khẩu';

  @override
  String get commonHidePassword => 'Ẩn mật khẩu';

  @override
  String get commonRequiredField => 'Vui lòng nhập trường này';

  @override
  String get showcaseTitle => 'Thư viện widget';

  @override
  String get showcaseEntry => 'Thư viện widget (dev)';

  @override
  String get showcaseToggleTheme => 'Đổi sáng/tối';

  @override
  String get showcaseSectionColors => 'Màu';

  @override
  String get showcaseSectionTypography => 'Chữ';

  @override
  String get showcaseSectionButtons => 'Nút bấm';

  @override
  String get showcaseSectionCards => 'Thẻ';

  @override
  String get showcaseSectionInputs => 'Ô nhập liệu';

  @override
  String get showcaseSectionStates => 'Trạng thái';

  @override
  String get showcaseSectionOverlay => 'Lớp phủ loading';

  @override
  String get showcaseSectionDialog => 'Hộp thoại';

  @override
  String get showcaseSampleLabel => 'Tên thực phẩm';

  @override
  String get showcaseSampleText => 'Cà chua bi tươi ngon';

  @override
  String get showcaseHighlighted => 'Thẻ được làm nổi bật';

  @override
  String get showcaseCardNormal => 'Thẻ thường';

  @override
  String get showcaseCardTappable => 'Thẻ bấm được';

  @override
  String get showcaseCardElevated => 'Thẻ có bóng';

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
  String get showcaseStateLoading => 'Đang tải';

  @override
  String get showcaseStateDisabled => 'Vô hiệu';

  @override
  String get showcaseTapToLoad => 'Nhấn để loading 2 giây';

  @override
  String get showcaseFieldRequired => 'Trường bắt buộc';

  @override
  String get showcaseFieldServerError => 'Trường có lỗi từ server';

  @override
  String get showcaseFieldServerErrorText => 'Tên này đã tồn tại';

  @override
  String get showcaseFieldPassword => 'Mật khẩu';

  @override
  String get showcaseFieldDisabled => 'Trường bị khoá';

  @override
  String get showcaseEmptyAction => 'Thêm mục';

  @override
  String get showcaseShowOverlay => 'Hiện lớp phủ 2 giây';

  @override
  String get showcaseOpenDialog => 'Mở hộp thoại xác nhận';

  @override
  String get showcaseOpenDestructiveDialog => 'Mở hộp thoại xoá';

  @override
  String get showcaseDialogTitle => 'Xoá mục này?';

  @override
  String get showcaseDialogMessage => 'Thao tác này không thể hoàn tác.';

  @override
  String showcaseDialogResult(String result) {
    return 'Kết quả: $result';
  }

  @override
  String get profileDefaultName => 'Thành viên';

  @override
  String get profileSessionMissingTitle => 'Không thể tải hồ sơ';

  @override
  String get profileSessionMissingMessage =>
      'Phiên đăng nhập không còn hiệu lực, vui lòng đăng nhập lại.';

  @override
  String get profileReLogin => 'Đăng nhập lại';

  @override
  String get profileWeeklyRecapNav => 'Tổng kết tuần';

  @override
  String get profileChangeAvatar => 'Đổi ảnh đại diện';

  @override
  String get profileAvatarPickAnother => 'Chọn ảnh khác';

  @override
  String get profileAvatarNewUnsaved => 'Ảnh mới — chưa lưu';

  @override
  String get profileAvatarUploading => 'Đang tải ảnh lên…';

  @override
  String get profileAvatarGallery => 'Thư viện';

  @override
  String get profileAvatarCamera => 'Máy ảnh';

  @override
  String get profileAvatarPermissionDenied =>
      'Chưa cấp quyền camera hoặc thư viện ảnh. Hãy bật trong Cài đặt.';

  @override
  String get profileNameRequired => 'Họ và tên không được để trống';

  @override
  String get profileNameTooLong => 'Họ và tên tối đa 100 ký tự';

  @override
  String get profileSaving => 'Đang lưu…';

  @override
  String get profileSaveRetry => 'Thử lại';

  @override
  String get profileSaveErrorAfterUpload =>
      'Ảnh đã tải lên nhưng chưa lưu được hồ sơ. Kiểm tra kết nối và thử lại.';

  @override
  String get avatarErrorInvalid =>
      'Ảnh không hợp lệ. Hãy chọn ảnh JPG hoặc PNG khác.';

  @override
  String get avatarErrorTooLarge => 'Ảnh quá lớn. Hãy chọn ảnh khác.';

  @override
  String get healthProfileEmptyTitle => 'Chưa thiết lập hồ sơ sức khỏe';

  @override
  String get healthProfileEmptyMessage =>
      'Thêm mục tiêu calo, chế độ ăn và dị ứng để gợi ý món phù hợp hơn.';

  @override
  String get healthProfileNotSetUp => 'Chưa thiết lập';

  @override
  String get healthProfileSetUpCta => 'Thiết lập hồ sơ sức khỏe';

  @override
  String get healthProfileEditAction => 'Chỉnh sửa';

  @override
  String get healthProfileEditTitle => 'Sửa hồ sơ sức khỏe';

  @override
  String healthProfileKcalValue(int value) {
    return '$value kcal';
  }

  @override
  String get healthProfileCaloriesNotSet => 'Chưa đặt';

  @override
  String get healthProfileCaloriesNotSetToggle => 'Chưa đặt mục tiêu';

  @override
  String healthProfileCaloriesCurrent(int value) {
    return 'Hiện tại: $value kcal';
  }

  @override
  String healthProfileCaloriesOutOfRange(int min, int max) {
    return 'Ngoài khoảng $min–$max — kéo thanh để chọn giá trị mới.';
  }

  @override
  String get healthProfileNeedsNetwork => 'Cần kết nối mạng để chỉnh sửa.';

  @override
  String get healthProfileCaloriesServerInvalid => 'Mục tiêu calo không hợp lệ';

  @override
  String get allergenNeedsNetwork => 'Cần kết nối mạng để sửa dị ứng.';

  @override
  String get allergensHealthLoadFailedTitle => 'Chưa tải được dị ứng hiện tại';

  @override
  String get allergensHealthLoadFailedMessage =>
      'Để tránh ghi đè dị ứng đã lưu, cần tải xong dữ liệu trước khi chỉnh sửa.';

  @override
  String get allergensSavedSection => 'Dị ứng đã lưu';

  @override
  String allergensCatalogCount(int count) {
    return '$count chất gây dị ứng phổ biến';
  }

  @override
  String allergensSelectedCount(int count) {
    return '$count đã chọn';
  }

  @override
  String get allergenSaveError => 'Có lỗi khi lưu, vui lòng thử lại.';

  @override
  String familyRemoveConfirmBody(String name) {
    return '$name sẽ không còn xem được kho, thực đơn và danh sách mua sắm của gia đình.';
  }

  @override
  String get familyRemoveConfirmAction => 'Xóa';

  @override
  String familyRemoveSuccess(String name) {
    return 'Đã xóa $name khỏi gia đình.';
  }

  @override
  String familyMemberYou(String name) {
    return '$name (bạn)';
  }

  @override
  String get familyGuestBadge => 'Khách';

  @override
  String familyJoinedAt(String date) {
    return 'Tham gia $date';
  }

  @override
  String get familyNeedsNetwork =>
      'Cần kết nối mạng để mời hoặc xóa thành viên.';

  @override
  String get familyErrorNotOwner => 'Bạn không còn quyền quản lý gia đình này.';

  @override
  String get familyErrorInviteLimit =>
      'Đã có 3 lời mời còn hiệu lực. Hãy đợi lời mời cũ hết hạn rồi thử lại.';

  @override
  String get familyErrorCannotRemove => 'Không thể xóa thành viên này.';

  @override
  String familyInviteExpiresAt(String date) {
    return 'Hết hạn: $date';
  }

  @override
  String get familyInviteCopyCode => 'Sao chép mã';

  @override
  String get familyInviteCopyLink => 'Sao chép liên kết';

  @override
  String get familyInviteCopied => 'Đã sao chép';

  @override
  String get familyInviteShowLast => 'Xem lại lời mời vừa tạo';

  @override
  String get memberHealthForbidden =>
      'Bạn không có quyền xem hồ sơ sức khỏe của thành viên này.';

  @override
  String get memberDetailPrivacyNote =>
      'Thông tin chiều cao/cân nặng/calo là riêng tư và không hiển thị ở đây.';

  @override
  String get memberDetailNotFound => 'Không tìm thấy thành viên này.';

  @override
  String get memberDetailClose => 'Đóng';

  @override
  String get nutritionTitle => 'Dinh dưỡng tuần';

  @override
  String get nutritionWeekThisTitle => 'Dinh dưỡng tuần này';

  @override
  String get nutritionComplianceExcellent => 'Xuất sắc';

  @override
  String get nutritionComplianceGood => 'Tốt';

  @override
  String get nutritionComplianceNeedsImprovement => 'Cần cải thiện';

  @override
  String get nutritionCompliancePoor => 'Chưa đạt';

  @override
  String get nutritionComplianceUnknown => 'Chưa có đánh giá';

  @override
  String nutritionScoreOutOf(int score) {
    return '$score/100';
  }

  @override
  String get nutritionScoreLabel => 'Điểm tuân thủ kế hoạch';

  @override
  String get nutritionAllergenNotChecked =>
      'Chưa kiểm tra dị ứng — điểm chỉ dựa trên calo';

  @override
  String get nutritionSetTarget => 'Đặt mục tiêu calo';

  @override
  String get nutritionWeeklyTotal => 'Tổng tuần';

  @override
  String nutritionTargetForDays(int days, String kcal) {
    return 'Mục tiêu cho $days ngày có dữ liệu: $kcal kcal';
  }

  @override
  String nutritionWeeklyDelta(String delta) {
    return '$delta kcal so với mục tiêu';
  }

  @override
  String get nutritionNoTarget => 'Chưa đặt mục tiêu';

  @override
  String nutritionAvgPerDay(String kcal, int days) {
    return 'Trung bình $kcal kcal/ngày ($days ngày có dữ liệu)';
  }

  @override
  String get nutritionNoDataDays => 'Chưa có ngày nào có dữ liệu';

  @override
  String nutritionMissingData(int count) {
    return '$count món chưa có dữ liệu dinh dưỡng';
  }

  @override
  String nutritionKcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String nutritionMacroLine(String p, String c, String f) {
    return 'Đạm $p g · Tinh bột $c g · Béo $f g';
  }

  @override
  String get nutritionNoMealsDay => 'Chưa có món nào';

  @override
  String get nutritionProtein => 'Chất đạm';

  @override
  String get nutritionCarbs => 'Tinh bột';

  @override
  String get nutritionFat => 'Chất béo';

  @override
  String nutritionMacroPercent(String name, String percent) {
    return '$name $percent%';
  }

  @override
  String get nutritionNoMacroData => 'Chưa có dữ liệu dinh dưỡng';

  @override
  String get nutritionDayOver => 'Vượt mục tiêu';

  @override
  String get nutritionDayUnder => 'Thiếu nhiều';

  @override
  String get nutritionDayOnTarget => 'Đạt';

  @override
  String get nutritionEmpty => 'Chưa có món nào được xác nhận trong tuần này';

  @override
  String get nutritionLoadFailed => 'Không tải được dữ liệu dinh dưỡng';

  @override
  String get nutritionViewMealPlan => 'Xem kế hoạch tuần';

  @override
  String get nutritionDishNoData => 'chưa có dữ liệu';

  @override
  String get nutritionDailyBreakdown => 'Chi tiết theo ngày';

  @override
  String get nutritionMealBreakfast => 'Sáng';

  @override
  String get nutritionMealLunch => 'Trưa';

  @override
  String get nutritionMealDinner => 'Tối';

  @override
  String get nutritionMealSnack => 'Bữa phụ';

  @override
  String nutritionBarSemantics(String day, String kcal) {
    return '$day: $kcal kcal';
  }

  @override
  String nutritionChartSemantics(String days) {
    return 'Calo theo ngày: $days';
  }

  @override
  String get nutritionMealOther => 'Bữa khác';

  @override
  String nutritionDishLine(String meal, String dish, String value) {
    return '$meal: $dish · $value';
  }

  @override
  String get receiptScanTitle => 'Quét hoá đơn';

  @override
  String get receiptScanTooltip => 'Quét hoá đơn';

  @override
  String get receiptScanHint =>
      'Chụp rõ toàn bộ hoá đơn. Món khớp danh sách mua sắm sẽ được chọn sẵn; món mua thêm có thể đưa vào tồn kho.';

  @override
  String get receiptScanNoImage => 'Chưa có ảnh';

  @override
  String get receiptScanning => 'Đang đọc hoá đơn…';

  @override
  String get receiptErrorAiUnavailable =>
      'Dịch vụ đọc hoá đơn đang bận hoặc chưa sẵn sàng. Thử lại với đúng ảnh này, hoặc chọn ảnh khác.';

  @override
  String get receiptErrorInProgress =>
      'Hoá đơn này vẫn đang được đọc — thử lại sau vài giây.';

  @override
  String get receiptErrorImageRejected =>
      'Không xử lý được ảnh này. Thử lại với cùng ảnh sẽ cho cùng kết quả — hãy chụp ảnh khác.';

  @override
  String get receiptErrorNoHouseholdTitle => 'Bạn chưa thuộc gia đình nào';

  @override
  String get receiptErrorNoHousehold =>
      'Tham gia gia đình trước khi quét hoá đơn.';

  @override
  String get receiptClose => 'Đóng';

  @override
  String get receiptResultTitle => 'Kết quả quét';

  @override
  String get receiptRestart => 'Đặt lại';

  @override
  String get receiptRetake => 'Chụp lại';

  @override
  String get receiptEmpty => 'Không đọc được hóa đơn, hãy chụp lại';

  @override
  String receiptSummaryTotal(String amount) {
    return 'Tổng $amount';
  }

  @override
  String receiptSummaryCounts(int matched, int unmatched) {
    return '$matched dòng khớp · $unmatched ngoài danh sách';
  }

  @override
  String get receiptMatchedSection => 'Khớp với danh sách mua sắm';

  @override
  String receiptMatchedCount(int lines, int items) {
    return '$lines dòng · $items món';
  }

  @override
  String get receiptUnmatchedSection => 'Không có trong danh sách';

  @override
  String receiptUnmatchedCount(int count) {
    return '$count món';
  }

  @override
  String receiptOnReceipt(String raw) {
    return 'Trên hoá đơn: \"$raw\"';
  }

  @override
  String get receiptBadgeReview => 'Kiểm tra lại';

  @override
  String receiptCatalogHint(int percent) {
    return 'Gợi ý catalog $percent%';
  }

  @override
  String get receiptMarkedBought => 'Đã đánh dấu đã mua';

  @override
  String get receiptNotUpdated => 'Chưa cập nhật được';

  @override
  String get receiptSkipped => 'Bỏ qua';

  @override
  String get receiptAddToInventory => 'Thêm vào tồn kho';

  @override
  String get receiptAdding => 'Đang thêm…';

  @override
  String get receiptAdded => 'Đã thêm';

  @override
  String get receiptCategoryOptional => 'Danh mục (tuỳ chọn)';

  @override
  String get receiptUnitHint => 'Chọn đơn vị trước khi thêm';

  @override
  String receiptCommit(int count) {
    return 'Cập nhật danh sách mua sắm ($count)';
  }

  @override
  String get receiptDone => 'Xong';

  @override
  String receiptCommitFailedBanner(int count) {
    return '$count món chưa cập nhật được — kiểm tra ở màn Mua sắm.';
  }

  @override
  String get receiptDoneTitle => 'Đã cập nhật';

  @override
  String receiptDoneToast(int count) {
    return 'Đã cập nhật $count món';
  }

  @override
  String get authBadCredentials => 'Sai email hoặc mật khẩu';

  @override
  String get authEmailExists => 'Email này đã được đăng ký';

  @override
  String get authNameRequired => 'Vui lòng nhập họ tên';

  @override
  String get authNameTooLong => 'Họ tên tối đa 100 ký tự';

  @override
  String get householdFull => 'Gia đình này đã đủ 10 thành viên';

  @override
  String get joinRateLimited =>
      'Bạn thao tác quá nhanh, vui lòng thử lại sau ít phút';

  @override
  String get inviteQrInvalid => 'Mã QR không hợp lệ';

  @override
  String get joinGoHome => 'Về trang chủ';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get notificationsEmpty => 'Chưa có thông báo nào.';

  @override
  String get notificationsMarkAllRead => 'Đánh dấu đã đọc tất cả';

  @override
  String get notificationsLoadFailed =>
      'Không tải được thông báo mới nhất — kéo xuống để thử lại';

  @override
  String get notificationsLoadMoreFailed => 'Không tải thêm được thông báo';

  @override
  String get notificationsMarkReadFailed =>
      'Không cập nhật được trạng thái đã đọc, hãy thử lại';

  @override
  String get notificationsNavTitle => 'Thông báo';

  @override
  String get notificationPermissionTitle => 'Bật thông báo';

  @override
  String get notificationPermissionBody =>
      'Nhận nhắc hạn dùng thực phẩm, lịch mua sắm và bữa ăn đã lên kế hoạch.';

  @override
  String get notificationPermissionEnable => 'Bật thông báo';

  @override
  String get notificationPermissionLater => 'Để sau';

  @override
  String get notificationPermissionDeniedBanner => 'Thông báo đang tắt';

  @override
  String get notificationPermissionNotDeterminedBanner =>
      'Bạn chưa bật thông báo';

  @override
  String get notificationPermissionUnsupported =>
      'Thông báo chưa khả dụng trên thiết bị này';

  @override
  String get notificationOpenSettings => 'Mở Cài đặt';

  @override
  String get notificationRegistrationFailed =>
      'Chưa đăng ký nhận thông báo được, sẽ thử lại';

  @override
  String get notificationJustNow => 'Vừa xong';

  @override
  String notificationMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String notificationHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String get notificationUntitled => 'Thông báo mới';

  @override
  String notificationsUnreadBadge(int count) {
    return '$count chưa đọc';
  }

  @override
  String shoppingCheckoutCta(int count) {
    return 'Cất vào kho ($count)';
  }

  @override
  String get shoppingCheckoutTitle => 'Cất vào kho';

  @override
  String get shoppingCheckoutHint =>
      'Kiểm tra hạn dùng rồi xác nhận để thêm các món này vào kho.';

  @override
  String shoppingCheckoutConfirm(int count) {
    return 'Cất $count món vào kho';
  }

  @override
  String shoppingCheckoutDone(int count) {
    return 'Đã cất $count món vào kho';
  }

  @override
  String get shoppingCheckoutEmpty =>
      'Không có món đã mua nào chờ cất vào kho.';

  @override
  String get shoppingCheckoutOffline => 'Cần có mạng để cất đồ vào kho.';

  @override
  String get shoppingCheckoutReloaded =>
      'Danh sách đã thay đổi và được tải lại. Hãy kiểm tra rồi xác nhận lại.';

  @override
  String get shoppingCheckoutDuplicate => 'Đã có trong kho · tạo lô mới';

  @override
  String get shoppingCheckoutInvalidRow => 'Kiểm tra lại số lượng / đơn vị';

  @override
  String get shoppingInInventoryBadge => 'Đã vào kho';

  @override
  String get shoppingInInventoryToggleBlocked =>
      'Món này đã cất vào kho, không bỏ đánh dấu được nữa.';

  @override
  String get expiryChipAdd => 'Thêm hạn dùng';

  @override
  String expiryChipSuggested(Object date) {
    return 'HSD $date · gợi ý';
  }

  @override
  String expiryChipSet(Object date) {
    return 'HSD $date';
  }

  @override
  String get errShopItemAlreadyInInventory => 'Món này đã được cất vào kho.';

  @override
  String get errShopItemNotBought => 'Chỉ món đã mua mới cất vào kho được.';

  @override
  String get homeGreetingMorning => 'Chào buổi sáng';

  @override
  String get homeGreetingNoon => 'Chào buổi trưa';

  @override
  String get familyMemberActions => 'Thao tác với thành viên';

  @override
  String get mealPlanDishSourceTitle => 'Chọn món bằng cách nào?';

  @override
  String get mealPlanDishSourceAi => 'Gợi ý AI';

  @override
  String get inventoryDeleteConfirmMessage => 'Mặt hàng sẽ bị xoá khỏi kho.';

  @override
  String get inventoryDeleteReasonTitle => 'Vì sao xoá mặt hàng này?';

  @override
  String get allergenGluten => 'Gluten (lúa mì)';

  @override
  String get allergenCrustaceans => 'Giáp xác (tôm, cua)';

  @override
  String get allergenEggs => 'Trứng';

  @override
  String get allergenFish => 'Cá';

  @override
  String get allergenPeanuts => 'Đậu phộng';

  @override
  String get allergenSoybeans => 'Đậu nành';

  @override
  String get allergenMilk => 'Sữa';

  @override
  String get allergenTreeNuts => 'Hạt cây (hạnh nhân, óc chó…)';

  @override
  String get allergenCelery => 'Cần tây';

  @override
  String get allergenMustard => 'Mù tạt';

  @override
  String get allergenSesame => 'Mè (vừng)';

  @override
  String get allergenSulphurDioxide => 'Sulfit (SO₂)';

  @override
  String get allergenLupin => 'Đậu lupin';

  @override
  String get allergenMolluscs => 'Nhuyễn thể (mực, sò…)';

  @override
  String get dietTypeUnsetShort => 'Chưa chọn';

  @override
  String get dietTypeNoneShort => 'Không kiêng';

  @override
  String get dietTypeUnsetDescription =>
      'Chưa chọn chế độ ăn — thực đơn không áp ràng buộc nào.';

  @override
  String get dietTypeNoneDescription =>
      'Ăn bình thường, không kiêng nhóm thực phẩm nào.';

  @override
  String get dietTypeKetoDescription =>
      'Rất ít tinh bột, nhiều chất béo — hạn chế cơm, bánh mì, đồ ngọt.';

  @override
  String get dietTypeVegetarianDescription =>
      'Không ăn thịt, cá; vẫn dùng trứng và sữa.';

  @override
  String get dietTypeVeganDescription =>
      'Thuần chay: không thịt, cá, trứng, sữa hay sản phẩm từ động vật.';

  @override
  String get dietTypePescatarianDescription =>
      'Không ăn thịt nhưng vẫn ăn cá và hải sản.';

  @override
  String get dietTypeGlutenFreeDescription =>
      'Tránh lúa mì, lúa mạch và thực phẩm chứa gluten.';

  @override
  String get dietTypeDiabeticDescription =>
      'Hạn chế đường và tinh bột hấp thu nhanh, ưu tiên món ít ngọt.';

  @override
  String get inventoryCategoryLabel => 'Phân loại *';

  @override
  String get inventoryCategoryRequired => 'Vui lòng chọn phân loại';

  @override
  String get inventoryZeroQuantityTitle => 'Đã dùng hết mặt hàng này?';

  @override
  String get inventoryZeroQuantityConfirm => 'Xác nhận';

  @override
  String get attendanceUnsure => 'Chưa rõ';

  @override
  String attendanceYou(String status) {
    return 'Bạn: $status';
  }

  @override
  String get planningGuestSlotTitle => 'Khách ăn cùng bữa này';

  @override
  String get planningGuestSlotScopeBanner =>
      'Khách ăn tạm thời — chỉ áp dụng cho bữa này, không lưu vào hồ sơ gia đình. Người ăn thường xuyên (con nhỏ, ông bà sống cùng) thì dùng mục Thành viên phụ thuộc trong hồ sơ gia đình.';

  @override
  String get planningGuestSlotEmpty => 'Bữa này chưa có khách nào.';

  @override
  String get planningGuestSlotDeleteConfirm => 'Xoá khách này khỏi bữa này?';

  @override
  String get planningGuestSlotUpdated =>
      'Đã cập nhật. Gợi ý AI của bữa này có thể đã thay đổi.';

  @override
  String planningGuestSlotCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count khách',
      zero: 'Chưa có khách',
    );
    return '$_temp0';
  }

  @override
  String get healthProfileGender => 'Giới tính';

  @override
  String get healthProfileGenderMale => 'Nam';

  @override
  String get healthProfileGenderFemale => 'Nữ';

  @override
  String get healthProfileBirthDate => 'Ngày sinh';

  @override
  String get healthProfileBirthDateChoose => 'Chọn ngày sinh…';

  @override
  String get healthProfileBirthDateInvalid => 'Ngày sinh phải ở quá khứ';

  @override
  String get healthProfileActivityLevel => 'Mức vận động';

  @override
  String get activityLevelSedentary => 'Ít vận động';

  @override
  String get activityLevelLight => 'Nhẹ (1–3 buổi/tuần)';

  @override
  String get activityLevelModerate => 'Vừa (3–5 buổi/tuần)';

  @override
  String get activityLevelActive => 'Nhiều (6–7 buổi/tuần)';

  @override
  String get activityLevelVeryActive => 'Rất nhiều (lao động nặng)';

  @override
  String healthProfileCalorieSuggestion(int value) {
    return 'Gợi ý: $value kcal';
  }

  @override
  String get healthProfileCalorieApply => 'Áp dụng';

  @override
  String get healthProfileCalorieSuggestionHint =>
      'Nhập chiều cao, cân nặng, giới tính, ngày sinh, mức vận động để được gợi ý';

  @override
  String recipeCardServes(int count) {
    return '$count người';
  }

  @override
  String get recipesFilterApply => 'Áp dụng';

  @override
  String get recipesFilterReset => 'Đặt lại';

  @override
  String recipesFilterMaxMinutes(int minutes) {
    return '≤ $minutes phút';
  }

  @override
  String get healthProfileCalorieSuggestionAdultOnly =>
      'Công thức gợi ý áp dụng cho người từ 18 tuổi';

  @override
  String get healthProfileChoiceInvalid =>
      'Lựa chọn không hợp lệ, hãy chọn lại';

  @override
  String get mealDishRoleStaple => 'Món tinh bột';

  @override
  String get mealDishRoleMain => 'Món mặn';

  @override
  String get mealDishRoleVegetable => 'Món rau';

  @override
  String get mealDishRoleSoup => 'Món canh';

  @override
  String get mealDishRoleCompleteMeal => 'Món một đĩa';

  @override
  String get mealDishRoleLightMeal => 'Bữa nhẹ';

  @override
  String mealComposeServingsShort(String servings) {
    return '$servings khẩu phần';
  }

  @override
  String get nutritionProteinShort => 'Đạm';

  @override
  String get nutritionCarbsShort => 'Tinh bột';

  @override
  String get nutritionFatShort => 'Béo';

  @override
  String nutritionGramValue(String name, String grams) {
    return '$name $grams g';
  }

  @override
  String get insightsMacroChartTitle => 'Cơ cấu dinh dưỡng hằng ngày';

  @override
  String get insightsMacroChartSubtitle =>
      'Lượng chất đạm, tinh bột và chất béo tính theo gam (g)';

  @override
  String insightsMacroTooltip(
      int day, int month, String p, String c, String f, String total) {
    return 'Ngày $day/$month\n• Đạm: $p g\n• Tinh bột: $c g\n• Béo: $f g\nTổng: $total g';
  }

  @override
  String get mealPlanNoSlotsForDay => 'Chưa có bữa nào trong ngày này';

  @override
  String get mealPlanSlotLocked =>
      'Bữa đã qua giờ hoặc đã nấu, không thể chỉnh sửa';

  @override
  String get mealPlanSlotLockedToast =>
      'Bữa này đã khoá, không thể chỉnh sửa nữa';

  @override
  String get mealPlanDishCooked => 'Đã nấu';

  @override
  String get homeUpcomingAllCooked => 'Đã nấu xong';

  @override
  String get dishCookedTitle => 'Món đã nấu xong';

  @override
  String get dishCookedMessage => 'Món này đã được nấu xong theo thực đơn.';

  @override
  String dishCookedMessageAt(String time, String date) {
    return 'Món này đã được nấu xong lúc $time ngày $date.';
  }

  @override
  String get dishCookedClose => 'Đóng';

  @override
  String get mealPlanAllergyWarningTitle => 'Cảnh báo dị ứng';

  @override
  String get mealPlanAllergyWarningMessage =>
      'Món này có chất gây dị ứng với người ăn bữa này:';

  @override
  String mealPlanAllergyPersonLine(String name, String allergens) {
    return '$name: $allergens';
  }

  @override
  String get mealPlanAllergyUnverifiedNote =>
      'Dữ liệu dị ứng của món này chưa kiểm chứng — hãy kiểm tra lại nguyên liệu.';

  @override
  String get mealPlanAllergyContinue => 'Tiếp tục';

  @override
  String get mealPlanAllergyGuest => 'Khách';

  @override
  String get mealPlanAllergyMember => 'Thành viên';

  @override
  String get mealPlanMissingAddWithShopping => 'Thêm món + đi chợ';

  @override
  String get mealPlanMissingAddOnly => 'Chỉ thêm món';

  @override
  String get monthlyRecapTitle => 'Tổng kết tháng';

  @override
  String get monthlyRecapPreviousMonth => 'Tháng trước';

  @override
  String get monthlyRecapNextMonth => 'Tháng sau';

  @override
  String get monthlyRecapNoHousehold =>
      'Tham gia một hộ gia đình để xem Tổng kết tháng';

  @override
  String get monthlyRecapMonthInvalid =>
      'Tháng này chưa có tổng kết. Hãy chọn tháng khác.';

  @override
  String get monthlyRecapHeroFallback =>
      'Chưa có nhận xét cá nhân hoá cho bạn trong tháng này. Tiếp tục ghi nhật ký bữa ăn để có tổng kết chi tiết hơn!';

  @override
  String get monthlyRecapAvgCalories => 'Calo trung bình mỗi ngày';

  @override
  String get monthlyRecapAdherenceCaption =>
      'Mức bám sát kế hoạch bữa ăn trong tháng';

  @override
  String monthlyRecapStreak(int count) {
    return '$count tuần';
  }

  @override
  String get monthlyRecapStreakCaption => 'Chuỗi tuần đạt mục tiêu';

  @override
  String get monthlyRecapEmptyInsights =>
      'Chưa có nhận xét cá nhân hoá nào cho tháng này.';

  @override
  String get monthlyRecapShare =>
      'Tổng kết tháng của nhà tôi trên Smart Kitchen!';

  @override
  String monthlyRecapWeekLabel(String date) {
    return 'Tuần $date';
  }

  @override
  String monthlyRecapShowWeeks(int count) {
    return 'Xem chi tiết từng tuần ($count)';
  }

  @override
  String get monthlyRecapHideWeeks => 'Ẩn chi tiết từng tuần';

  @override
  String monthlyRecapMonthRange(String start, String end) {
    return 'Từ $start đến $end';
  }

  @override
  String get monthlyRecapWasteTitle => 'Lãng phí trong tháng';

  @override
  String get monthlyRecapWasteNone =>
      '🎉 Tháng này nhà bạn không bỏ đi món nào. Giữ nhịp này nhé!';

  @override
  String get monthlyRecapSpendTitle => 'Chi tiêu trong tháng';

  @override
  String get monthlyRecapSpendNone =>
      'Chưa có món nào được nhập giá trong tháng này';

  @override
  String monthlyRecapSpendPercent(int percent) {
    return '$percent% ngân sách tháng';
  }

  @override
  String monthlyRecapSpendOver(int percent, String amount) {
    return '$percent% ngân sách tháng · Vượt $amount';
  }

  @override
  String monthlyRecapBudgetConvertedWeekly(String amount) {
    return 'Ngân sách tuần ($amount) đã được quy đổi theo tháng.';
  }

  @override
  String monthlyRecapBudgetConvertedOther(String amount) {
    return 'Ngân sách bạn đặt ($amount) đã được quy đổi theo tháng.';
  }

  @override
  String get monthlyRecapSpendTrend => 'Xu hướng theo tuần';

  @override
  String get monthlyRecapSpendCategoryEmpty =>
      'Chưa có khoản chi nào được nhập giá trong tháng này';

  @override
  String get monthlyRecapSpendUpsell =>
      'Xem chi tiêu theo nhóm và xu hướng theo tuần với gói Premium';

  @override
  String get monthlyRecapSpendDetailNeutral =>
      'Chưa có dữ liệu chi tiết cho tháng này.';
}
