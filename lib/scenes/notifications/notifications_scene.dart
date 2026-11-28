import 'dart:async';

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
import '../../widgets/states/app_state_view.dart';
import '../../widgets/states/view_state.dart';
import 'notifications_routes.dart';

/// Hộp thư thông báo (fcm-notification-flow.md §8, N4; #201 đọc từ server).
class NotificationsScene extends StatefulWidget {
  const NotificationsScene({super.key});

  @override
  State<NotificationsScene> createState() => _NotificationsSceneState();
}

class _NotificationsSceneState extends State<NotificationsScene> {
  late final NotificationStore _store = Get.find<NotificationStore>();

  @override
  void initState() {
    super.initState();
    unawaited(_store.refresh());
  }

  void _open(AppNotification notification) {
    unawaited(_store.markRead(notification.id));
    if (notification.target != NotificationTarget.notifications) {
      Get.toNamed<void>(NotificationsRoutes.routeFor(notification.target));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.notificationsTitle,
      actions: <Widget>[
        Observer(
          builder: (_) => TextButton(
            key: const ValueKey<String>('notifications-mark-all-read'),
            onPressed: store.unreadCount == 0
                ? null
                : () => unawaited(store.markAllRead()),
            child: Text(l10n.notificationsMarkAllRead),
          ),
        ),
      ],
      body: Observer(builder: (_) {
        final state = store.listState;
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
            // Có dữ liệu cũ/lạc quan mà tải lại lỗi → banner, không thay list.
            if (state is SuccessState<List<AppNotification>> &&
                store.inboxError != null)
              FeatureBanner(
                key: const ValueKey<String>('notifications-load-error'),
                message: l10n.notificationsLoadFailed,
                margin: const EdgeInsets.fromLTRB(
                    AppDimens.md, AppDimens.sm, AppDimens.md, 0),
              ),
            if (store.actionError != null)
              FeatureBanner(
                key: const ValueKey<String>('notifications-action-error'),
                message: l10n.notificationsMarkReadFailed,
                margin: const EdgeInsets.fromLTRB(
                    AppDimens.md, AppDimens.sm, AppDimens.md, 0),
              ),
            Expanded(
              child: AppStateView<List<AppNotification>>(
                state: state,
                onRetry: () => unawaited(store.refresh()),
                emptyIcon: Icons.notifications_none_rounded,
                emptyMessage: l10n.notificationsEmpty,
                successBuilder: (_, items) => RefreshIndicator(
                  onRefresh: store.refresh,
                  child: ListView.separated(
                      key: const ValueKey<String>('notifications-list'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppDimens.md),
                      itemCount: items.length + (store.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimens.sm),
                      itemBuilder: (_, i) => i == items.length
                          ? _LoadMoreFooter(store: store)
                          : _NotificationTile(
                              notification: items[i],
                              onTap: () => _open(items[i]),
                            ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Cuối danh sách: đang tải trang kế / lỗi + thử lại.
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.store});

  final NotificationStore store;

  @override
  Widget build(BuildContext context) => Observer(builder: (_) {
        if (store.loadMoreError == null) {
          // Footer chỉ được dựng khi cuộn gần cuối (ListView lười) → tải trang
          // kế ngay khi nó xuất hiện.
          if (!store.isLoadingMore) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => unawaited(store.loadMore()));
          }
          return const Padding(
            padding: EdgeInsets.all(AppDimens.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Column(
          key: const ValueKey<String>('notifications-load-more-error'),
          children: <Widget>[
            Text(context.l10n.notificationsLoadMoreFailed,
                textAlign: TextAlign.center),
            TextButton(
              onPressed: () => unawaited(store.loadMore()),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        );
      });
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
        NotificationTarget.household => Icons.group_outlined,
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
          Icon(_icon,
              color: unread
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant),
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
          // Chấm chưa đọc — kèm chữ đậm + thẻ nổi để không chỉ dựa vào màu.
          if (unread)
            Container(
              key: ValueKey<String>('notification-unread-${notification.id}'),
              width: AppDimens.sm,
              height: AppDimens.sm,
              margin: const EdgeInsets.only(left: AppDimens.sm, top: AppDimens.xs),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
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
