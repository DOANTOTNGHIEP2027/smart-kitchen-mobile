import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../data/auth/firebase_bootstrapper.dart';
import '../data/auth/secure_token_storage.dart';
import '../data/auth/token_storage.dart';
import '../data/network/dio_client.dart';
import '../stores/session_store.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseStatus = await FirebaseBootstrapper.initialize();
  final tokenStorage = SecureTokenStorage();
  final sessionStore = SessionStore(tokenStorage);
  final dioClient = DioClient.build(
    tokenStorage: tokenStorage,
    onAccessTokenRefreshed: (accessToken) async {
      sessionStore.applyRefreshedClaims(accessToken);
    },
    onRefreshFailure: () async {
      await sessionStore.clear();
    },
  );
  sessionStore.configureRefresh(dioClient.refreshTokens);

  Get.put<TokenStorage>(tokenStorage, permanent: true);
  Get.put<SessionStore>(sessionStore, permanent: true);
  Get.put<DioClient>(dioClient, permanent: true);
  Get.put<FirebaseSetupStatus>(firebaseStatus, permanent: true);

  await sessionStore.bootstrap();
  runApp(const SmartKitchenApp());
}
