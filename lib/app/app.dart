import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../routing/app_pages.dart';
import '../routing/app_routes.dart';

/// Widget gốc (fe-app-shell.md §3). Chỉ lắp theme + bảng route + i18n;
/// mọi logic khởi tạo nằm ở `bootstrap()`.
class SmartKitchenApp extends StatelessWidget {
  const SmartKitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
