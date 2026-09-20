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
}
