import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../routing/app_routes.dart';
import '../../stores/session_store.dart';

class SplashScene extends StatefulWidget {
  const SplashScene({super.key});

  @override
  State<SplashScene> createState() => _SplashSceneState();
}

class _SplashSceneState extends State<SplashScene> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = Get.isRegistered<SessionStore>()
          ? Get.find<SessionStore>().status
          : AuthStatus.unauthenticated;
      Get.offAllNamed(
        status == AuthStatus.authenticated
            ? (Get.find<SessionStore>().householdId == null
                ? AppRoutes.householdSetup
                : AppRoutes.shellRoot)
            : AppRoutes.login,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BrandMark(),
            const SizedBox(height: 12),
            Text(
              'app_title'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x55FF7A45), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: const SizedBox(width: 56, height: 56),
    );
  }
}
