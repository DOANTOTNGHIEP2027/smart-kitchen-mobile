import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/realtime/realtime_service.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/vote_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/family_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/profile_api.dart';
import 'package:smart_kitchen_mobile/services/connectivity_service.dart';
import 'package:smart_kitchen_mobile/stores/realtime_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

/// Stub cho toàn bộ dependency `AppShellScene._ensureBindings()` cần, để
/// shell render được trong widget test mà không phải wire backend thật.
///
/// Register (idempotent qua `Get.isRegistered`):
///  - SessionStore (rỗng — chưa authenticated)
///  - AppDatabase (memory qua `forTesting(NativeDatabase.memory())`)
///  - 2 DAO + 6 API bằng mocktail.
///  - ConnectivityService + RealtimeService/RealtimeStore.
///
/// Shell gọi `.dependencies()` đăng ký `InventoryStore`, `MealPlanStore`,
/// `ProfileStore` → chúng `Get.find` các phần đăng ký ở đây.
void registerShellStubBindings({
  TokenStorage? tokenStorage,
}) {
  final ts = tokenStorage ?? TokenStorage();
  if (!Get.isRegistered<SessionStore>()) {
    Get.put<SessionStore>(
      SessionStore(ts, AuthRefreshUseCase(Dio())),
      permanent: true,
    );
  }
  if (!Get.isRegistered<AppDatabase>()) {
    Get.put<AppDatabase>(
      AppDatabase.forTesting(NativeDatabase.memory()),
      permanent: true,
    );
  }
  if (!Get.isRegistered<ReadCacheDao>()) {
    Get.put<ReadCacheDao>(ReadCacheDao(Get.find<AppDatabase>()), permanent: true);
  }
  if (!Get.isRegistered<InventoryDao>()) {
    Get.put<InventoryDao>(InventoryDao(Get.find<AppDatabase>()), permanent: true);
  }
  if (!Get.isRegistered<InventoryApi>()) {
    Get.put<InventoryApi>(_MockInventoryApi(), permanent: true);
  }
  if (!Get.isRegistered<MealPlanApi>()) {
    Get.put<MealPlanApi>(_MockMealPlanApi(), permanent: true);
  }
  if (!Get.isRegistered<VoteApi>()) {
    Get.put<VoteApi>(_MockVoteApi(), permanent: true);
  }
  if (!Get.isRegistered<HealthApi>()) {
    Get.put<HealthApi>(_MockHealthApi(), permanent: true);
  }
  if (!Get.isRegistered<ProfileApi>()) {
    Get.put<ProfileApi>(_MockProfileApi(), permanent: true);
  }
  if (!Get.isRegistered<FamilyApi>()) {
    Get.put<FamilyApi>(_MockFamilyApi(), permanent: true);
  }
  if (!Get.isRegistered<ConnectivityService>()) {
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
  }
  if (!Get.isRegistered<RealtimeService>()) {
    Get.put<RealtimeService>(
      RealtimeService(tokenStorage: ts),
      permanent: true,
    );
  }
  if (!Get.isRegistered<RealtimeStore>()) {
    Get.put<RealtimeStore>(
      RealtimeStore(
        realtimeService: Get.find<RealtimeService>(),
        connectivityService: Get.find<ConnectivityService>(),
        sessionStore: Get.find<SessionStore>(),
      ),
      permanent: true,
    );
  }
  _wireStubResponses();
}

// ── Mock interfaces bằng mocktail ─────────────────────────────────────
//
// Mocktail cần stub method cụ thể khi test chạm tới nó. Shell renders
// feature scene → scene gọi API → mock phải trả giá trị sample giả.
// Stub toàn bộ method mà shell path chạm, trả list/dto rỗng để UI
// không ném Null và chạy tới empty state.

class _MockInventoryApi extends Mock implements InventoryApi {}
class _MockMealPlanApi extends Mock implements MealPlanApi {}
class _MockVoteApi extends Mock implements VoteApi {}
class _MockHealthApi extends Mock implements HealthApi {}
class _MockProfileApi extends Mock implements ProfileApi {}
class _MockFamilyApi extends Mock implements FamilyApi {}

/// Stub các method mà shell render sẽ chạm tới (tránh `Null` crash và
/// để feature scene render được ở empty/success state).
void _wireStubResponses() {
  final inventory = Get.find<InventoryApi>();
  final mealPlan = Get.find<MealPlanApi>();

  when(() => inventory.list(page: any(named: 'page'), size: any(named: 'size')))
      .thenAnswer(
        (_) async => const InventoryListPage(
          items: <InventoryItemModel>[],
          page: 0,
          size: 100,
          totalElements: 0,
          totalPages: 0,
        ),
      );
  when(() => mealPlan.getCurrent()).thenAnswer(
    (_) async => MealPlanDto(
      id: 'mp-1',
      householdId: 'h1',
      weekStart: DateTime(2026, 9, 14),
      slots: const <MealPlanSlot>[],
    ),
  );
}
