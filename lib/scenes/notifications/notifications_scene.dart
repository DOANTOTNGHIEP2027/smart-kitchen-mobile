import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors_extension.dart';
import '../../constants/app_dimens.dart';
import '../../data/notification/app_notification.dart';
import '../../data/notification/notification_routing.dart';
import '../../data/notification/push_gateway.dart';
import '../../stores/notification_store.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/feature_banner.dart';
import '../../widgets/states/app_empty_view.dart';
import 'notifications_routes.dart';

/// Màn thông báo trong phiên — tối giản (fcm-notification-flow.md §8, N4).
class NotificationsScene extends StatelessWidget {
  const NotificationsScene({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<NotificationStore>();
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.notificationsTitle,
      actions: <Widget>[
        Observer(
          builder: (_) => TextButton(
            key: const ValueKey<String>('notifications-mark-all-read'),
            onPressed: store.unreadCount == 0 ? null : store.markAllRead,
            child: Text(l10n.notificationsMarkAllRead),
          ),
        ),
      ],
      body: Observer(builder: (_) {
        final items = store.notifications.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            NotificationPermissionBanner(store: store),
            if (store.registrationError != null)
              FeatureBanner(
                key: const ValueKey<String>('notifications-registration-error'),
                message: l10n.notificationRegistrationFailed,
                isError: false,
                margin: const EdgeInsets.fromLTRB(
                    AppDimens.md, AppDimens.sm, AppDimens.md, 0),
              ),
            Expanded(
              child: items.isEmpty
                  ? AppEmptyView(
                      icon: Icons.notifications_none_rounded,
                      message: l10n.notificationsEmpty,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppDimens.md),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimens.sm),
                      itemBuilder: (_, i) => _NotificationTile(
                        notification: items[i],
                        onTap: () {
                          store.markRead(items[i].id);
                          if (items[i].target !=
                              NotificationTarget.notifications) {
                            Get.toNamed<void>(
                                NotificationsRoutes.routeFor(items[i].target));
                          }
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

/// Banner trạng thái quyền (§7.2).
class NotificationPermissionBanner extends StatelessWidget {
  const NotificationPermissionBanner({
    super.key,
    required this.store,
    this.openSettings = openAppSettings,
  });

  final NotificationStore store;

  /// Inject được để test nhánh "mở Cài đặt" (review #48 M3).
  final Future<bool> Function() openSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final (String? message, String? action, VoidCallback? onAction) =
          switch (store.permissionStatus) {
        NotificationPermissionStatus.granted => (null, null, null),
        NotificationPermissionStatus.notDetermined => (
            l10n.notificationPermissionNotDeterminedBanner,
            l10n.notificationPermissionEnable,
            store.requestPermission,
          ),
        NotificationPermissionStatus.denied => (
            l10n.notificationPermissionDeniedBanner,
            l10n.notificationPermissionEnable,
            () async {
              await store.requestPermission();
              // Vẫn `denied` = OS không hiện dialog (Android < 13) → mở Cài
              // đặt. `permanentlyDenied` = người dùng vừa bấm "Không cho
              // phép" → KHÔNG đẩy ngay vào Cài đặt (review v2 N-LOW-1).
              if (store.permissionStatus == NotificationPermissionStatus.denied) {
                await openSettings();
              }
            },
          ),
        NotificationPermissionStatus.permanentlyDenied => (
            l10n.notificationPermissionDeniedBanner,
            l10n.notificationOpenSettings,
            openSettings,
          ),
        NotificationPermissionStatus.unsupported => (
            l10n.notificationPermissionUnsupported,
            null,
            null,
          ),
      };
      if (message == null) return const SizedBox.shrink();
      final colors = context.appColors;
      return Container(
        key: ValueKey<String>('notifications-permission-${store.permissionStatus.name}'),
        margin: const EdgeInsets.fromLTRB(AppDimens.md, AppDimens.md, AppDimens.md, 0),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md, vertical: AppDimens.sm),
        decoration: BoxDecoration(
          color: colors.warningSurface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.textPrimary)),
            ),
            if (action != null)
              TextButton(
                key: const ValueKey<String>('notifications-permission-action'),
                onPressed: store.isLoading ? null : onAction,
                child: Text(action),
              ),
          ],
        ),
      );
    });
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon => switch (notification.target) {
        NotificationTarget.inventory => Icons.kitchen_outlined,
        NotificationTarget.mealPlan => Icons.restaurant_menu_rounded,
        NotificationTarget.shopping => Icons.shopping_cart_outlined,
        NotificationTarget.notifications => Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final unread = !notification.read;
    return AppCard(
      onTap: onTap,
      highlighted: unread,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(_icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  notification.title ?? l10n.notificationUntitled,
                  style: textTheme.bodyLarge?.copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
                ),
                if (notification.body != null)
                  Text(notification.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium),
                Text(relativeTime(context, notification.receivedAt),
                    style: textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Vừa xong" / "x phút trước" / "x giờ trước" / ngày.
String relativeTime(BuildContext context, DateTime at, {DateTime? now}) {
  final l10n = context.l10n;
  final diff = (now ?? DateTime.now()).difference(at);
  if (diff.inMinutes < 1) return l10n.notificationJustNow;
  if (diff.inHours < 1) return l10n.notificationMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.notificationHoursAgo(diff.inHours);
  return MaterialLocalizations.of(context).formatShortDate(at);
}
