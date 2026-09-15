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
}
