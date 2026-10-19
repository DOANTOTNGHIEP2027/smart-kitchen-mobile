import 'package:get/get.dart';

import '../../routing/route_guards.dart';
import 'allergen_select_screen.dart';
import 'dependent_form_screen.dart';
import 'dependent_list_screen.dart';
import 'edit_profile_screen.dart';
import 'family_screen.dart';
import 'health_profile_screen.dart';
import 'member_detail_screen.dart';
import 'profile_family_bindings.dart';
import 'profile_screen.dart';
import 'tier_upgrade_screen.dart';

abstract class ProfileFamilyRoutes {
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileHealth = '/profile/health';
  static const String profileAllergens = '/profile/allergens';
  static const String family = '/family';
  /// Phải khai báo TRƯỚC `/family/:userId` để không bị khớp nhầm thành userId.
  static const String tierUpgrade = '/family/tier-upgrade';
  static const String memberDetail = '/family/:userId';
  static const String dependents = '/dependents';
  static const String dependentAdd = '/dependents/add';
}

final List<GetPage<dynamic>> profileFamilyPages = <GetPage<dynamic>>[
  GetPage<void>(
    name: ProfileFamilyRoutes.profile,
    page: () => const ProfileScreen(),
    binding: ProfileBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: ProfileFamilyRoutes.profileEdit,
    page: () => const EditProfileScreen(),
    binding: ProfileBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: ProfileFamilyRoutes.profileHealth,
    page: () => const HealthProfileScreen(),
    binding: ProfileBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: ProfileFamilyRoutes.profileAllergens,
    page: () => const AllergenSelectScreen(),
    binding: ProfileBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: ProfileFamilyRoutes.family,
    page: () => const FamilyScreen(),
    binding: FamilyBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: ProfileFamilyRoutes.tierUpgrade,
    page: () => const TierUpgradeScreen(),
    binding: FamilyBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: ProfileFamilyRoutes.memberDetail,
    page: () => const MemberDetailScreen(),
    binding: FamilyBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: ProfileFamilyRoutes.dependents,
    page: () => const DependentListScreen(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
  GetPage<void>(
    name: ProfileFamilyRoutes.dependentAdd,
    page: () => const DependentFormScreen(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
