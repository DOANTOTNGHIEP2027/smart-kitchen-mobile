import 'package:get/get.dart';

/// Centralized copy for the platform shell. Feature modules add their own keys
/// here (or through a dedicated translation map) instead of embedding text in widgets.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => const {
        'en_US': {
          'app_title': 'Smart Kitchen',
          'loading': 'Loading…',
          'retry': 'Try again',
          'coming_soon': 'This feature is coming soon',
          'nothing_here': 'Nothing here yet',
          'something_went_wrong': 'Something went wrong',
          'sign_in_unavailable': 'Sign-in screens will be available soon',
          'home': 'Home',
          'inventory': 'Inventory',
          'planning': 'Planning',
          'shopping': 'Shopping',
          'profile': 'Profile',
        },
        'vi_VN': {
          'app_title': 'Smart Kitchen',
          'loading': 'Đang tải…',
          'retry': 'Thử lại',
          'coming_soon': 'Tính năng đang được hoàn thiện',
          'nothing_here': 'Chưa có dữ liệu',
          'something_went_wrong': 'Đã có lỗi xảy ra',
          'sign_in_unavailable': 'Màn hình đăng nhập sẽ sớm khả dụng',
          'home': 'Trang chủ',
          'inventory': 'Kho',
          'planning': 'Thực đơn',
          'shopping': 'Mua sắm',
          'profile': 'Hồ sơ',
        },
      };
}
