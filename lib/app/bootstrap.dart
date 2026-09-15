import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../data/auth/token_storage.dart';
import '../data/auth/google_auth_gateway.dart';
import '../data/network/dio_client.dart';
import '../demo/demo_backend_adapter.dart';
import '../domain/auth/auth_refresh_usecase.dart';
import '../stores/session_store.dart';
import '../scenes/auth/api/auth_api.dart';
import '../scenes/auth/stores/auth_store.dart';
import '../scenes/household/api/household_api.dart';
import '../scenes/household/stores/household_store.dart';
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

  await sessionStore.bootstrap(); // thử silent refresh, set AuthStatus

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
