import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import 'env_config.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../routing/app_pages.dart';
import '../routing/app_routes.dart';
import '../data/notification/notification_service.dart';
import '../scenes/inventory/inventory_catch_up.dart';
import '../stores/notification_store.dart';
import '../stores/theme_store.dart';
import '../utils/l10n_x.dart';

/// Widget gốc (fe-app-shell.md §3). Chỉ lắp theme + bảng route + i18n;
/// mọi logic khởi tạo nằm ở `bootstrap()`.
class SmartKitchenApp extends StatelessWidget {
  const SmartKitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Không bọc Observer khi chưa có ThemeStore (test dựng app không qua
    // bootstrap) — Observer không đọc observable nào sẽ cảnh báo (design §6).
    if (!Get.isRegistered<ThemeStore>()) return _buildApp(ThemeMode.light);
    final themeStore = Get.find<ThemeStore>();
    return Observer(builder: (_) => _buildApp(themeStore.themeMode));
  }

  Widget _buildApp(ThemeMode themeMode) {
    return GetMaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Bản demo dùng copy tiếng Việt nhất quán, không phụ thuộc locale của
      // emulator. Bản kết nối backend thật vẫn theo ngôn ngữ hệ điều hành.
      locale: EnvConfig.isDemoMode ? const Locale('vi') : null,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => _NotificationUiHost(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _NotificationUiHost extends StatefulWidget {
  const _NotificationUiHost({required this.child});

  final Widget child;

  @override
  State<_NotificationUiHost> createState() => _NotificationUiHostState();
}

class _NotificationUiHostState extends State<_NotificationUiHost>
    with WidgetsBindingObserver {
  StreamSubscription<NotificationUiEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!Get.isRegistered<NotificationService>()) return;
    final service = Get.find<NotificationService>();
    _subscription = service.uiEvents.listen(_schedule);
    for (final event in service.attachUi()) {
      _schedule(event);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  /// Quay lại app → đọc lại quyền (người dùng có thể đổi trong Cài đặt) —
  /// fcm-notification-flow.md §14.4. #134 A8: catch-up kho nếu isolate nền
  /// đã đặt cờ pending-sync. #201: tải lại hộp thư (push lúc app nền/tắt chỉ
  /// có ở server).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (Get.isRegistered<NotificationStore>()) {
      final notifications = Get.find<NotificationStore>();
      unawaited(notifications.refreshPermission());
      unawaited(notifications.refresh());
    }
    if (Get.isRegistered<InventoryCatchUp>()) {
      unawaited(Get.find<InventoryCatchUp>().run());
    }
  }

  void _schedule(NotificationUiEvent event) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handle(event);
    });
  }

  void _handle(NotificationUiEvent event) {
    switch (event.type) {
      case NotificationUiEventType.inventoryUpdated:
        return _show(context.l10n.notificationInventoryUpdated);
      case NotificationUiEventType.inventoryAlreadyUsed:
        return _show(context.l10n.notificationInventoryAlreadyUsed);
      case NotificationUiEventType.inventoryAlreadyDiscarded:
        return _show(context.l10n.notificationInventoryAlreadyDiscarded);
      case NotificationUiEventType.inventoryAlreadyProcessed:
        return _show(context.l10n.notificationInventoryAlreadyProcessed);
      case NotificationUiEventType.inventoryGone:
        return _show(context.l10n.notificationInventoryGone);
      case NotificationUiEventType.inventoryReadonly:
        return _show(context.l10n.notificationInventoryReadonly);
      case NotificationUiEventType.noNetwork:
        return _show(context.l10n.notificationNoNetwork);
      case NotificationUiEventType.actionFailed:
        return _show(context.l10n.notificationActionFailed);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
