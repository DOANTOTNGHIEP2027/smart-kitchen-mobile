import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_theme.dart';
import '../routing/app_pages.dart';
import '../routing/app_routes.dart';
import 'app_translations.dart';

class SmartKitchenApp extends StatelessWidget {
  const SmartKitchenApp({super.key, this.initialRoute = AppRoutes.splash});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Kitchen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('vi', 'VN'),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
    );
  }
}
