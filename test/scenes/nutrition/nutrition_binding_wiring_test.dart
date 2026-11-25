import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/scenes/meal_plan_routes.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/stores/nutrition_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/profile_family_bindings.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';

import '../../helpers/secure_storage_channel.dart';
import '../../helpers/shell_bindings_stub.dart';

/// Wiring thật theo thứ tự của shell (`AppShellScene._ensureBindings`:
/// WeeklyMealPlanBinding chạy TRƯỚC ProfileBinding) — code review #64 HIGH-1.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();

  setUp(() {
    storage.install();
    registerShellStubBindings(tokenStorage: TokenStorage());
  });

  tearDown(() {
    storage.uninstall();
    Get.reset();
  });

  test('store tab Kế hoạch theo kịp mục tiêu đổi ở Hồ sơ sức khoẻ', () async {
    final health = Get.find<HealthApi>();
    var target = 1800;
    when(health.getMyHealthProfile).thenAnswer((_) async => HealthProfile(
          userId: 'u1',
          targetDailyCalories: target,
          allergens: const <Allergen>[],
        ));

    WeeklyMealPlanBinding().dependencies(); // trước ProfileBinding, như shell
    ProfileBinding().dependencies();

    final nutrition = Get.find<NutritionStore>(tag: NutritionStore.mealPlanTag);
    await Future<void>.delayed(Duration.zero);
    expect(nutrition.targetDailyCalories, 1800);

    // Người dùng lưu mục tiêu mới ở màn hồ sơ sức khoẻ → ProfileStore tải lại.
    target = 2500;
    await Get.find<ProfileStore>().loadHealthProfile();
    expect(nutrition.targetDailyCalories, 2500);
  });

  test('store Profile cũng theo ProfileStore', () async {
    final health = Get.find<HealthApi>();
    when(health.getMyHealthProfile).thenAnswer((_) async => const HealthProfile(
          userId: 'u1',
          targetDailyCalories: 2100,
          allergens: <Allergen>[],
        ));
    ProfileBinding().dependencies();
    final nutrition = Get.find<NutritionStore>(tag: NutritionStore.profileTag);
    await Get.find<ProfileStore>().loadHealthProfile();
    expect(nutrition.targetDailyCalories, 2100);
  });
}
