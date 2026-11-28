import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/meal_log_api.dart';
import 'package:smart_kitchen_mobile/scenes/nutrition/stores/nutrition_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/profile_family_bindings.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';

import '../../helpers/secure_storage_channel.dart';
import '../../helpers/shell_bindings_stub.dart';
import 'nutrition_fakes.dart';

/// Wiring thật của NutritionStore ở tab Hồ sơ. Màn thực đơn tuần không còn
/// hiện tổng hợp dinh dưỡng (#201) nên không còn store tag mealPlan.
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

  test('store Profile cũng theo ProfileStore', () async {
    final health = Get.find<HealthApi>();
    when(health.getMyHealthProfile).thenAnswer((_) async => const HealthProfile(
          userId: 'u1',
          targetDailyCalories: 2100,
          allergens: <Allergen>[],
        ));
    Get.put<MealLogApi>(NutritionMealLogApi());
    ProfileBinding().dependencies();
    final nutrition = Get.find<NutritionStore>(tag: NutritionStore.profileTag);
    await Get.find<ProfileStore>().loadHealthProfile();
    expect(nutrition.targetDailyCalories, 2100);
  });
}
