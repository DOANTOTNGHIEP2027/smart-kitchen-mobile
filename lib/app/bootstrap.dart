import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constants/app_version.dart';
import '../data/auth/token_storage.dart';
import '../data/auth/google_auth_gateway.dart';
import '../data/db/app_database.dart';
import '../data/db/read_cache_dao.dart';
import '../data/network/dio_client.dart';
import '../data/network/cache/connectivity_signal.dart';
import '../demo/demo_backend_adapter.dart';
import '../domain/auth/auth_refresh_usecase.dart';
import '../domain/auth/auth_revoke_usecase.dart';
import '../stores/session_store.dart';
import '../stores/theme_store.dart';
import '../scenes/auth/api/auth_api.dart';
import '../scenes/auth/stores/auth_store.dart';
import '../scenes/household/api/household_api.dart';
import '../scenes/household/stores/household_store.dart';
import '../scenes/profile/api/dependent_api.dart';
import '../scenes/profile/api/family_api.dart';
import '../scenes/profile/api/health_api.dart';
import '../scenes/profile/api/profile_api.dart';
import '../scenes/inventory/data/inventory_api.dart';
import '../scenes/inventory/data/inventory_dao.dart';
import '../scenes/inventory/inventory_catch_up.dart';
import '../scenes/inventory/stores/inventory_store.dart';
import '../scenes/assistant/data/assistant_api.dart';
import '../scenes/cooking/data/cooking_session_api.dart';
import '../scenes/cooking/data/recipe_api.dart';
import '../scenes/recipe/data/recipe_catalog_api.dart';
import '../scenes/mealplan/data/meal_plan_api.dart';
import '../scenes/mealplan/data/meal_suggestion_api.dart';
import '../scenes/mealplan/data/meal_attendance_api.dart';
import '../data/notification/bg_files.dart';
import '../data/notification/cross_isolate_lock.dart';
import '../data/notification/device_api.dart';
import '../data/notification/notification_api.dart';
import '../data/notification/notification_service.dart';
import '../data/notification/quick_action_api.dart';
import '../data/realtime/realtime_service.dart';
import '../services/connectivity_service.dart';
import '../stores/realtime_store.dart';
import '../stores/notification_store.dart';
import '../data/notification/notification_prefs.dart';
import '../data/notification/push_gateway.dart';
import '../data/ai_runtime/connectivity/connectivity_gate.dart';
import '../data/ai_runtime/engine/model_registry.dart';
import '../data/ai_runtime/engine/on_device_inference_engine.dart';
import '../data/ai_runtime/engine/on_device_inference_engine_impl.dart';
import '../data/ai_runtime/hybrid_ai_runner.dart';
import 'app.dart';
import 'env_config.dart';
import 'realtime_startup.dart';

/// #93 §6.4 — mốc Timeline chi tiết cho đo cold start, chỉ bật khi
/// `--dart-define=PERF_MARKS=true` (đọc trong DevTools/Perfetto).
const bool _kPerfMarks = bool.fromEnvironment('PERF_MARKS');

void _perfMark(String name) {
  if (_kPerfMarks) developer.Timeline.instantSync(name);
}

/// Chuỗi bootstrap (fe-app-shell.md §5).
///
/// Đến lúc `runApp()` chạy, `SessionStore.status` đã được resolve — nên
/// `SplashScene` chỉ việc đọc và redirect, không cần guard.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.load();
  final firebaseAvailable = await _initFirebase();

  final tokenStorage = TokenStorage();
  // #134 A5.4: CẢ 3 đường refresh của main isolate (interceptor, bootstrap,
  // refreshSession) đi qua cùng mutex liên isolate với quick-action nền.
  final bgFiles = BgFiles.production();
  final refreshGate = RefreshGate(
    lock: kIsWeb ? InProcessLock() : FileLeaseLock(directory: bgFiles.directory),
    tokenStorage: tokenStorage,
  );
  final dioClient =
      DioClient.build(tokenStorage: tokenStorage, refreshGate: refreshGate);

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
    revokeUseCase: AuthRevokeUseCase(dioClient.dio),
    refreshGate: refreshGate,
  );
  Get.put<SessionStore>(sessionStore, permanent: true);
  Get.put<ThemeStore>(ThemeStore(), permanent: true);
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
  Get.put<DependentApi>(DependentApiImpl(dioClient), permanent: true);
  Get.put<ProfileApi>(ProfileApiImpl(dioClient), permanent: true);

  // FE-5: InventoryApi + InventoryDao đăng ký permanent — InventoryStore và
  // InventoryFormStore đều dùng.
  Get.put<InventoryApi>(InventoryApiImpl(dioClient), permanent: true);
  Get.put<InventoryDao>(InventoryDao(Get.find<AppDatabase>()), permanent: true);

  // FE-6: CookingApi + RecipeApi — cả CookingSessionStore đều dùng.
  Get.put<CookingSessionApi>(CookingSessionApiImpl(dioClient), permanent: true);
  Get.put<RecipeApi>(RecipeApiImpl(dioClient), permanent: true);
  Get.put<AssistantApi>(AssistantApiImpl(dioClient), permanent: true);
  Get.put<RecipeCatalogApi>(RecipeCatalogApiImpl(dioClient), permanent: true);

  // FE-7: MealPlanApi + VoteApi — MealPlanStore/VoteSessionStore dùng.
  Get.put<MealPlanApi>(MealPlanApiImpl(dioClient), permanent: true);
  Get.put<MealSuggestionApi>(MealSuggestionApi(dioClient), permanent: true);
  Get.put<MealAttendanceApi>(MealAttendanceApi(dioClient), permanent: true);

  // FE-3: Realtime WebSocket + FCM notification + Connectivity.
  final connectivityService = ConnectivityService();
  await connectivityService.init();
  Get.put<ConnectivityService>(connectivityService, permanent: true);

  // On-device AI runtime (on-device-ai-runtime.md §10): chỉ đọc asset local,
  // không mạng/auth. Package thiếu/hỏng chỉ tắt đúng task đó, không crash.
  // Chạy SONG SONG với sessionStore.bootstrap() (§10) — await chung bên dưới.
  final modelRegistry = ModelRegistry(appVersion: AppVersion.current);
  final modelRegistryReady = modelRegistry.bootstrap();
  Get.put<ModelRegistry>(modelRegistry, permanent: true);
  final onDeviceEngine = OnDeviceInferenceEngineImpl(modelRegistry);
  Get.put<OnDeviceInferenceEngine>(onDeviceEngine, permanent: true);
  Get.put<HybridAIRunner>(
    HybridAIRunner(
        ConnectivityGate(connectivityService), onDeviceEngine, modelRegistry),
    permanent: true,
  );

  // Task 4 (image caching): Signal phát tán trạng thái offline/online dùng chung
  // cho mọi AppCachedImage — app xem mạng online cho tới khi callback xác nhận
  // offline (tránh ấn xoá cache không cần thiết khi mạng thực chất chỉ chập chờn).
  // Dùng CÙNG instance Connectivity với ConnectivityService để không trùng
  // listener/tiêu thụ thêm resource (fix connectivity dupe khi review Task 4).
  final connectivitySignal = ConnectivitySignal(connectivityService.instance);
  await connectivitySignal.init();
  Get.put<ConnectivitySignal>(connectivitySignal, permanent: true);

  // Demo không được cố mở WebSocket tới backend thật. RealtimeService vẫn là
  // no-op stream để mọi feature có thể đăng ký listener như production.
  final realtimeService = RealtimeService(
    tokenStorage: tokenStorage,
    enabled: !EnvConfig.isDemoMode,
  );
  Get.put<RealtimeService>(realtimeService, permanent: true);

  Get.put<DeviceApi>(DeviceApiImpl(dioClient), permanent: true);
  Get.put<QuickActionApi>(QuickActionApiImpl(dioClient), permanent: true);
  Get.put<NotificationApi>(NotificationApiImpl(dioClient), permanent: true);

  // #48 — quyền + token + danh sách trong phiên do NotificationStore giữ
  // (fcm-notification-flow.md §6); service chỉ là adapter platform.
  final notificationStore = NotificationStore(
    gateway: FirebasePushGateway(firebaseAvailable: firebaseAvailable),
    deviceApi: Get.find<DeviceApi>(),
    prefs: SecureNotificationPrefs(),
    session: sessionStore,
    api: Get.find<NotificationApi>(),
  );
  Get.put<NotificationStore>(notificationStore, permanent: true);
  final notificationService = NotificationService(
    quickActionApi: Get.find<QuickActionApi>(),
    firebaseAvailable: firebaseAvailable,
    onNavigate: notificationStore.navigateTo,
    onInventoryChanged: () async {
      if (Get.isRegistered<InventoryStore>()) {
        await Get.find<InventoryStore>().syncFromServer();
      }
    },
  )..attachSink(notificationStore.addNotification);
  Get.put<NotificationService>(notificationService, permanent: true);

  // #134 A8: catch-up kho khi isolate nền đã đổi kho (cờ file + ping port).
  final inventoryCatchUp = InventoryCatchUp(files: bgFiles);
  if (!kIsWeb) inventoryCatchUp.listen();
  Get.put<InventoryCatchUp>(inventoryCatchUp, permanent: true);

  _perfMark('perf.session.start');
  await Future.wait<void>(<Future<void>>[
    sessionStore.bootstrap(), // thử silent refresh, set AuthStatus
    modelRegistryReady,
  ]);
  _perfMark('perf.session.end');

  // #93 §5.4: dựng + Get.put TRƯỚC runApp để binding inventory/shopping thấy
  // `Get.isRegistered<RealtimeStore>()`; chỉ `init()` chạy sau frame đầu.
  // Reaction auth do RealtimeStore.init() sở hữu DUY NHẤT — không đăng ký ở đây.
  final realtimeStore = RealtimeStore(
    realtimeService: realtimeService,
    connectivityService: connectivityService,
    sessionStore: sessionStore,
  );
  Get.put<RealtimeStore>(realtimeStore, permanent: true);

  // Store init TRƯỚC service: getInitialMessage (cold start) đi vào store đã
  // gắn sink (§14.1). Store tự theo session để đăng ký/xoá token (§14.3).
  // KHÔNG xin quyền ở bootstrap (Guard 1).
  await notificationStore.init();
  await notificationService.init();

  _perfMark('perf.runApp');
  runApp(const SmartKitchenApp());

  // Sau runApp: không await, có log, không ném ra zone (#93 §5.4 F1).
  startRealtimeAfterFirstFrame(realtimeStore);
  unawaited(inventoryCatchUp.run());
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
