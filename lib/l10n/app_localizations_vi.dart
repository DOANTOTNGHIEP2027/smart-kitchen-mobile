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
  String get cameraUnavailable => 'Không thể dùng camera';

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
  String get profileEditBlocked => 'Tính năng đang hoàn thiện, sẽ sớm ra mắt.';

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
  String get healthProfileAllergensEmpty => 'Chưa chọn dị ứng nào.';

  @override
  String get healthProfileAllergensEdit => 'Sửa dị ứng';

  @override
  String get healthSave => 'Lưu hồ sơ sức khoẻ';

  @override
  String get healthSavedToast => 'Đã lưu hồ sơ sức khoẻ';

  @override
  String get healthSavedDialogTitle => 'Đã lưu hồ sơ sức khoẻ';

  @override
  String get healthSavedDialogMessage =>
      'Hồ sơ sức khoẻ của bạn đã được lưu thành công.';

  @override
  String get healthSavedDialogConfirm => 'Xong';

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
  String get familyCreateInvite => 'Tạo lời mời';

  @override
  String get familyRemove => 'Xoá khỏi gia đình';

  @override
  String get familyRemoveConfirm => 'Xoá thành viên này khỏi gia đình?';

  @override
  String get familyRemoveCancel => 'Huỷ';

  @override
  String get familyYou => 'Bạn';

  @override
  String get familyInviteRateLimited => 'Bạn đã có 3 lời mời đang mở.';

  @override
  String get memberDetailTitle => 'Thành viên';

  @override
  String get memberDetailDietType => 'Chế độ ăn';

  @override
  String get memberDetailAllergensSection => 'Dị ứng';

  @override
  String get memberDetailAllergensEmpty => 'Chưa có dị ứng.';

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
  String get inventoryDeleteCorrected => 'Xoá nhầm, sửa số liệu';

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
  String get mealplanDeleteDishMessage =>
      'Nếu đang có phiên vote, phiên đó sẽ bị huỷ.';

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
      'Phiên đã tồn tại nhưng chưa tải lại được danh sách gợi ý.';

  @override
  String get mealplanSuggestionsExhausted =>
      'Đã xem hết gợi ý. Chờ vote hoặc thử re-roll.';

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
  String get mealplanActionRolledBack => 'Đã hoàn tác thao tác.';

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
}
