import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../data/auth/token_storage.dart';
import '../data/auth/google_auth_gateway.dart';
import '../data/db/app_database.dart';
import '../data/db/read_cache_dao.dart';
import '../data/network/dio_client.dart';
import '../demo/demo_backend_adapter.dart';
import '../domain/auth/auth_refresh_usecase.dart';
import '../stores/session_store.dart';
import '../scenes/auth/api/auth_api.dart';
import '../scenes/auth/stores/auth_store.dart';
import '../scenes/household/api/household_api.dart';
import '../scenes/household/stores/household_store.dart';
import '../scenes/profile/api/family_api.dart';
import '../scenes/profile/api/health_api.dart';
import '../scenes/profile/api/profile_api.dart';
import '../scenes/inventory/data/inventory_api.dart';
import '../scenes/inventory/data/inventory_dao.dart';
import '../scenes/cooking/data/cooking_session_api.dart';
import '../scenes/cooking/data/recipe_api.dart';
import '../scenes/mealplan/data/meal_plan_api.dart';
import '../scenes/mealplan/data/vote_api.dart';
import '../data/notification/device_api.dart';
import '../data/notification/notification_service.dart';
import '../data/realtime/realtime_service.dart';
import '../services/connectivity_service.dart';
import '../stores/realtime_store.dart';
import 'app.dart';
import 'env_config.dart';

/// Chuỗi bootstrap (fe-app-shell.md §5).
///
/// Đến lúc `runApp()` chạy, `SessionStore.status` đã được resolve — nên
/// `SplashScene` chỉ việc đọc và redirect, không cần guard.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.load();
  final firebaseAvailable = await _initFirebase();

  final tokenStorage = TokenStorage();
  final dioClient = DioClient.build(tokenStorage: tokenStorage);

  if (EnvConfig.isDemoMode) {
    // Chỉ thay tầng transport — api/store/scene và toàn bộ pipeline
    // interceptor vẫn chạy nguyên code production, nên demo chứng minh được
    // luồng thật chứ không phải một UI rỗng.
    dioClient.dio.httpClientAdapter = DemoBackendAdapter();
    developer.log(
      'DEMO MODE: mọi request HTTP được giả lập trong app.',
      name: 'bootstrap',
    );
  }

  Get.put<TokenStorage>(tokenStorage, permanent: true);
  Get.put<DioClient>(dioClient, permanent: true);

  final sessionStore = SessionStore(
    tokenStorage,
    AuthRefreshUseCase(dioClient.dio),
  );
  Get.put<SessionStore>(sessionStore, permanent: true);
  Get.put<AuthApi>(AuthApiImpl(dioClient), permanent: true);
  Get.put<HouseholdApi>(HouseholdApiImpl(dioClient), permanent: true);
  Get.put<GoogleAuthGateway>(
    firebaseAvailable
        ? GoogleAuthGatewayImpl()
        : const UnavailableGoogleAuthGateway(),
    permanent: true,
  );
  Get.put<AuthStore>(
    AuthStore(Get.find<AuthApi>(), sessionStore, Get.find<GoogleAuthGateway>()),
    permanent: true,
  );
  Get.put<HouseholdStore>(
    HouseholdStore(Get.find<HouseholdApi>(), Get.find<AuthApi>(), sessionStore),
    permanent: true,
  );

  // FE-3: Drift + read-cache + 3 API của profile/family/health.
  Get.put<AppDatabase>(AppDatabase(), permanent: true);
  Get.put<ReadCacheDao>(ReadCacheDao(Get.find<AppDatabase>()), permanent: true);
  Get.put<HealthApi>(HealthApiImpl(dioClient), permanent: true);
  Get.put<FamilyApi>(FamilyApiImpl(dioClient), permanent: true);
  Get.put<ProfileApi>(ProfileApiImpl(dioClient), permanent: true);

  // FE-5: InventoryApi + InventoryDao đăng ký permanent — InventoryStore và
  // InventoryFormStore đều dùng.
  Get.put<InventoryApi>(InventoryApiImpl(dioClient), permanent: true);
  Get.put<InventoryDao>(InventoryDao(Get.find<AppDatabase>()), permanent: true);

  // FE-6: CookingApi + RecipeApi — cả CookingSessionStore đều dùng.
  Get.put<CookingSessionApi>(CookingSessionApiImpl(dioClient),
      permanent: true);
  Get.put<RecipeApi>(RecipeApiImpl(dioClient), permanent: true);

  // FE-7: MealPlanApi + VoteApi — MealPlanStore/VoteSessionStore dùng.
  Get.put<MealPlanApi>(MealPlanApiImpl(dioClient), permanent: true);
  Get.put<VoteApi>(VoteApiImpl(dioClient), permanent: true);

  // FE-3: Realtime WebSocket + FCM notification + Connectivity.
  final connectivityService = ConnectivityService();
  await connectivityService.init();
  Get.put<ConnectivityService>(connectivityService, permanent: true);

  // Demo không được cố mở WebSocket tới backend thật. RealtimeService vẫn là
  // no-op stream để mọi feature có thể đăng ký listener như production.
  final realtimeService = RealtimeService(
    tokenStorage: tokenStorage,
    enabled: !EnvConfig.isDemoMode,
  );
  Get.put<RealtimeService>(realtimeService, permanent: true);

  Get.put<DeviceApi>(DeviceApiImpl(dioClient), permanent: true);

  final notificationService = NotificationService(
    deviceApi: Get.find<DeviceApi>(),
    isAuthenticated: () => sessionStore.isAuthenticated,
  );
  Get.put<NotificationService>(notificationService, permanent: true);

  await sessionStore.bootstrap(); // thử silent refresh, set AuthStatus

  // RealtimeStore init PHẢI sau sessionStore.bootstrap() để biết auth state.
  final realtimeStore = RealtimeStore(
    realtimeService: realtimeService,
    connectivityService: connectivityService,
    sessionStore: sessionStore,
  );
  Get.put<RealtimeStore>(realtimeStore, permanent: true);
  await realtimeStore.init();
  reaction<(AuthStatus, String?)>(
    (_) => (sessionStore.status, sessionStore.householdId),
    (_) => unawaited(realtimeStore.onAuthChanged()),
  );

  // NotificationService init SAU Firebase init — nếu Firebase không có thì
  // service sẽ degrade graceful (catch mọi exception nội bộ).
  await notificationService.init();
  reaction<AuthStatus>(
    (_) => sessionStore.status,
    (_) => unawaited(notificationService.onAuthChanged()),
    fireImmediately: true,
  );

  runApp(const SmartKitchenApp());
}

/// Issue #16 — phải chạy trước bất kỳ lần dùng `FirebaseAuth`/`GoogleSignIn` nào.
///
/// File config platform (`google-services.json` / `GoogleService-Info.plist` /
/// options cho web) chưa có trong repo — đó là bước ops, không phải khoảng
/// trống thiết kế (open question Q6). Cho tới lúc đó, init thất bại không được
/// phép chặn app boot: chỉ luồng Google Sign-In (thuộc `fe-onboarding`) mới
/// phụ thuộc vào nó, mọi thứ còn lại vẫn chạy bình thường.
Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (error) {
    developer.log(
      'Firebase chưa được cấu hình — bỏ qua, Google Sign-In sẽ không dùng được. '
      'Xem fe-app-shell.md §9 và open question Q6.',
      name: 'bootstrap',
      error: error,
    );
    return false;
  }
}
