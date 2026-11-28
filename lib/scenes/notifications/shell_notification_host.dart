import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';

import '../../constants/app_dimens.dart';
import '../../data/notification/notification_routing.dart';
import '../../stores/notification_store.dart';
import '../../utils/l10n_x.dart';
import '../../widgets/buttons/app_button.dart';
import '../mealplan/widgets/daily_attendance_sheet.dart';
import 'notifications_routes.dart';

/// Bọc body của shell (fcm-notification-flow.md §14.1, §14.5):
/// - điều hướng theo `store.pendingTarget` CHỈ khi shell đã lên (Splash đã
///   `offAllNamed`), nên màn đích không bị xoá lúc cold start;
/// - hiện sheet giải thích xin quyền một lần sau lần đăng nhập đầu.
class ShellNotificationHost extends StatefulWidget {
  const ShellNotificationHost({super.key, required this.child});

  final Widget child;

  @override
  State<ShellNotificationHost> createState() => _ShellNotificationHostState();
}

class _ShellNotificationHostState extends State<ShellNotificationHost> {
  final List<ReactionDisposer> _disposers = <ReactionDisposer>[];

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<NotificationStore>()) return;
    final store = Get.find<NotificationStore>();
    _disposers
      ..add(reaction<Object?>(
        (_) => store.pendingTarget,
        (target) {
          if (target == null) return;
          // Lấy-và-xoá ĐỒNG BỘ (chỉ 1 host xử lý dù đang có 2 host trong lúc
          // offAllNamed chuyển cảnh), rồi điều hướng ở post-frame vì Navigator
          // có thể đang khoá (review v2 N-MEDIUM-1).
          final pending = store.consumePendingTarget();
          if (pending == null) return;
          final data = store.consumePendingData();
          final invite = pending == NotificationTarget.attendanceInvite
              ? attendanceInviteOf(data)
              : null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Mời vote bữa ngày mai → popup ngay trên màn hiện tại.
            if (invite != null && mounted) {
              unawaited(showDailyAttendanceSheet(context,
                  planId: invite.planId, date: invite.date));
              return;
            }
            Get.toNamed<void>(NotificationsRoutes.routeFor(pending));
          });
          // Màn đang đứng yên thì không có frame nào tới — chủ động xin 1
          // frame để callback chắc chắn chạy.
          WidgetsBinding.instance.scheduleFrame();
        },
        fireImmediately: true,
      ))
      ..add(reaction<bool>(
        (_) => store.shouldShowRationale,
        (show) {
          if (!show) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Đánh dấu SAU khi chắc host còn sống — host bị huỷ trước frame
            // thì host mới vẫn hiện được sheet (review #48 L2).
            if (!mounted || !store.shouldShowRationale) return;
            store.markRationaleShown();
            _showRationale(store);
          });
          WidgetsBinding.instance.scheduleFrame();
        },
        fireImmediately: true,
      ));
  }

  Future<void> _showRationale(NotificationStore store) async {
    final enable = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      // Màn thấp / chữ to: không giới hạn 9/16 chiều cao, nội dung tự cuộn.
      isScrollControlled: true,
      builder: (_) => const NotificationPermissionSheet(),
    );
    if (enable == true) {
      await store.requestPermission();
    } else if (enable == null &&
        (!mounted || !(ModalRoute.of(context)?.isActive ?? false))) {
      // Sheet bị gỡ cùng shell (vd. phiên hết hạn → offAllNamed login), không
      // phải người dùng chọn — không đặt cờ (review #48 L1).
      return;
    } else {
      // "Để sau" hoặc vuốt đóng — đặt cờ, không hỏi lại tự động (§7.1).
      await store.dismissRationale();
    }
  }

  @override
  void dispose() {
    for (final dispose in _disposers) {
      dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Sheet giải thích trước dialog quyền của hệ điều hành (§7.1).
/// Trả `true` khi người dùng bấm "Bật thông báo".
class NotificationPermissionSheet extends StatelessWidget {
  const NotificationPermissionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, 0, AppDimens.lg, AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.notifications_active_outlined,
                size: AppDimens.stateIcon,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppDimens.sm),
            Text(l10n.notificationPermissionTitle,
                style: textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.sm),
            Text(l10n.notificationPermissionBody,
                style: textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              key: const ValueKey<String>('notification-permission-enable'),
              label: l10n.notificationPermissionEnable,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            AppButton(
              key: const ValueKey<String>('notification-permission-later'),
              label: l10n.notificationPermissionLater,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
