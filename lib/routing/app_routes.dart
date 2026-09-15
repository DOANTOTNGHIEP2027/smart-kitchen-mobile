/// Hằng số tên route (fe-app-shell.md §6.1). Không magic string ở call site.
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String shellRoot = '/';

  // Dành riêng cho fe-onboarding (#28) — khai báo ở đây để không feature nào
  // đụng độ tên, và vì chính logic guard/redirect của shell tham chiếu tới
  // chúng. Việc đăng ký GetPage cho hai route này thuộc về onboarding.
  static const String login = '/login'; // đích redirect của AuthGuard, §6.2
  static const String qrJoin = '/join'; // seam deep-link mời tham gia

  // ~30 màn hình còn lại của fe-onboarding KHÔNG được đặt trước ở đây —
  // feature đó tự sở hữu hằng số route của mình trong file riêng và tự append
  // danh sách GetPage vào AppPages.pages.
}
