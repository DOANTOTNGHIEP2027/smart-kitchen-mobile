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
}
