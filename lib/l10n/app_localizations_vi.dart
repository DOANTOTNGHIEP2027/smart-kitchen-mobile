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
  String get commonBack => 'Quay lại';

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonLater => 'Để sau';

  @override
  String get stateEmptyDefault => 'Chưa có dữ liệu';

  @override
  String get stateErrorDefault => 'Đã có lỗi xảy ra';

  @override
  String get errNetworkTitle => 'Không có kết nối mạng';

  @override
  String get errServerTitle => 'Đã có lỗi xảy ra, vui lòng thử lại';

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
  String get authLandingTitle => 'Chào mừng đến Smart Kitchen';

  @override
  String get authLandingSubtitle =>
      'Lên thực đơn, quản lý kho thực phẩm và giảm lãng phí cùng cả nhà.';

  @override
  String get authGoogleCta => 'Tiếp tục với Google';

  @override
  String get authEmailLoginCta => 'Đăng nhập bằng email';

  @override
  String get authEmailRegisterCta => 'Tạo tài khoản';

  @override
  String get authQrJoinCta => 'Quét mã QR tham gia gia đình';

  @override
  String get authGoogleLoading => 'Đang xác thực với Google…';

  @override
  String get authUseEmailInstead => 'Dùng email thay thế';

  @override
  String get errGoogleUnavailable => 'Không thể kết nối Google lúc này.';

  @override
  String get errGoogleNoEmail =>
      'Tài khoản Google này không có email dùng được. Hãy đăng ký bằng email.';

  @override
  String get errGoogleFailed => 'Xác thực Google thất bại, vui lòng thử lại.';

  @override
  String get toastAccountLinked =>
      'Tài khoản Google đã được liên kết với email hiện có.';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Mật khẩu';

  @override
  String get fieldFullName => 'Họ và tên';

  @override
  String get fieldFullNameOptional => 'Họ và tên (không bắt buộc)';

  @override
  String get fieldOtp => 'Mã 6 chữ số';

  @override
  String get fieldHouseholdName => 'Tên gia đình';

  @override
  String get fieldInviteCode => 'Mã mời';

  @override
  String get fieldDisplayName => 'Tên hiển thị của bạn';

  @override
  String get errInvalidEmail => 'Email không hợp lệ';

  @override
  String get errPasswordTooShort => 'Mật khẩu tối thiểu 8 ký tự';

  @override
  String get errPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get errFullNameRequired => 'Vui lòng nhập tên';

  @override
  String get errHouseholdNameRequired => 'Vui lòng nhập tên gia đình';

  @override
  String get registerTitle => 'Tạo tài khoản';

  @override
  String get registerCta => 'Đăng ký';

  @override
  String get registerHaveAccount => 'Đã có tài khoản? Đăng nhập';

  @override
  String get errEmailTaken => 'Email này đã được đăng ký';

  @override
  String get otpTitle => 'Xác minh email';

  @override
  String otpSubtitle(String email) {
    return 'Mã 6 chữ số đã được gửi tới $email.';
  }

  @override
  String get otpVerifyCta => 'Xác minh';

  @override
  String get otpResendCta => 'Gửi lại mã';

  @override
  String otpResendIn(int seconds) {
    return 'Gửi lại sau ${seconds}s';
  }

  @override
  String get errOtpInvalid => 'Mã OTP không đúng hoặc đã hết hạn';

  @override
  String get errOtpLimit =>
      'Bạn đã yêu cầu mã quá nhiều lần, vui lòng đợi trước khi thử lại.';

  @override
  String get toastOtpSent => 'Đã gửi mã';

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get loginCta => 'Đăng nhập';

  @override
  String get loginNoAccount => 'Chưa có tài khoản? Đăng ký';

  @override
  String get errBadCredentials => 'Email hoặc mật khẩu không đúng';

  @override
  String errLoginLocked(int seconds) {
    return 'Quá nhiều lần thử, vui lòng thử lại sau ${seconds}s.';
  }

  @override
  String get householdSetupTitle => 'Thiết lập gia đình';

  @override
  String get householdSetupSubtitle =>
      'Smart Kitchen hoạt động quanh kho thực phẩm chung của gia đình. Tạo mới hoặc tham gia một gia đình có sẵn.';

  @override
  String get householdCreateCta => 'Tạo gia đình mới';

  @override
  String get householdJoinCta => 'Tham gia bằng mã mời';

  @override
  String get createHouseholdTitle => 'Tạo gia đình';

  @override
  String get createHouseholdCta => 'Tạo';

  @override
  String get createHouseholdDoneTitle => 'Đã tạo gia đình';

  @override
  String get createHouseholdDoneSubtitle =>
      'Chia sẻ mã này để người nhà tham gia.';

  @override
  String get errHouseholdRace => 'Bạn đã thuộc một gia đình. Đang chuyển tiếp…';

  @override
  String get inviteCodeLabel => 'Mã mời';

  @override
  String get inviteCopyCta => 'Sao chép link';

  @override
  String get toastInviteCopied => 'Đã sao chép link mời';

  @override
  String inviteExpiresAt(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Hết hạn $dateString';
  }

  @override
  String get inviteContinueCta => 'Tiếp tục';

  @override
  String get scanTitle => 'Quét mã QR mời';

  @override
  String get scanHint => 'Hướng camera vào mã QR lời mời';

  @override
  String get scanPermissionDenied =>
      'Smart Kitchen cần quyền camera để quét mã QR lời mời.';

  @override
  String get scanEnterManually => 'Nhập mã thủ công';

  @override
  String get scanRetry => 'Quét lại';

  @override
  String get inviteCodeTitle => 'Nhập mã mời';

  @override
  String get inviteCodeCta => 'Kiểm tra';

  @override
  String get errInviteCodeFormat => 'Mã mời gồm 8 chữ cái hoặc chữ số';

  @override
  String get previewTitle => 'Tham gia gia đình này?';

  @override
  String previewOwner(String name) {
    return 'Chủ nhà: $name';
  }

  @override
  String previewMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thành viên',
      one: '1 thành viên',
    );
    return '$_temp0';
  }

  @override
  String get previewJoinCta => 'Tham gia';

  @override
  String get errInviteInvalid => 'Mã mời không hợp lệ hoặc đã hết hạn';

  @override
  String get inviteTryAnother => 'Nhập mã khác';

  @override
  String get errAlreadyInHousehold => 'Bạn đã thuộc về một gia đình khác.';

  @override
  String get errInviteRace => 'Mã mời vừa được sử dụng bởi người khác';

  @override
  String get toastJoined => 'Bạn đã tham gia gia đình';

  @override
  String get upgradeBannerText => 'Thiết lập email để không mất tài khoản';

  @override
  String get upgradeBannerCta => 'Thiết lập email';

  @override
  String get upgradeTitle => 'Bảo vệ tài khoản';

  @override
  String get upgradeSubtitle =>
      'Thêm email và mật khẩu để đăng nhập lại trên mọi thiết bị.';

  @override
  String get upgradeCta => 'Tiếp tục';
}
