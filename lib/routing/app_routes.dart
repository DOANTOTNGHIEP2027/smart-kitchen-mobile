/// Hằng số tên route (fe-app-shell.md §6.1). Không magic string ở call site.
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String shellRoot = '/';

  // Dành riêng cho fe-onboarding (#28) — khai báo ở đây để không feature nào
  // đụng độ tên, và vì chính logic guard/redirect của shell tham chiếu tới
  // chúng. Việc đăng ký GetPage cho hai route này thuộc về onboarding.
  static const String login = '/login'; // đích redirect của AuthGuard, §6.2
  static const String emailLogin = '/login/email';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String qrJoin = '/join'; // seam deep-link mời tham gia
  static const String qrJoinCode = '/join/:code';
  static const String householdSetup = '/household/setup';
  static const String householdCreate = '/household/create';
  static const String profileUpgrade = '/profile/upgrade';

  // Profile + family (FE-3 #29)
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileHealth = '/profile/health';
  static const String profileAllergens = '/profile/allergens';
  static const String family = '/family';
  static const String memberDetail = '/family/:userId';

  // Inventory (FE-5 #56 #58)
  static const String inventory = '/inventory';
  static const String inventoryAdd = '/inventory/add';
  static const String inventoryEdit = '/inventory/:id/edit';
}
