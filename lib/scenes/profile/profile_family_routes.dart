import 'package:get/get.dart';

import '../../routing/route_guards.dart';
import 'allergen_select_screen.dart';
import 'edit_profile_screen.dart';
import 'family_screen.dart';
import 'health_profile_screen.dart';
import 'member_detail_screen.dart';
import 'profile_family_bindings.dart';
import 'profile_screen.dart';

abstract class ProfileFamilyRoutes {
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileHealth = '/profile/health';
  static const String profileAllergens = '/profile/allergens';
  static const String family = '/family';
  static const String memberDetail = '/family/:userId';
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
    name: ProfileFamilyRoutes.memberDetail,
    page: () => const MemberDetailScreen(),
    binding: FamilyBinding(),
    middlewares: <GetMiddleware>[AuthGuard()],
  ),
];
