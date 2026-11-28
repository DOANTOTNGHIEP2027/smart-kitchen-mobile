import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';

/// Loại toast — quyết định icon/màu nhấn.
enum AppToastType { info, success, error }

/// Toast nhỏ dùng chung cho phản hồi ngắn, hiện ở góc TRÊN-TRÁI.
///
/// Chèn vào Overlay gốc (trên cả bottom sheet và dialog — thay cho SnackBar
/// vốn bị sheet che), không cần `BuildContext`. Toast mới THAY toast đang
/// hiện, không xếp chồng; tự mờ dần sau [show.duration].
abstract final class AppToast {
  static const Duration defaultDuration = Duration(milliseconds: 2500);

  /// Key của toast đang hiện — cho test tìm widget.
  static const Key toastKey = ValueKey<String>('app-toast');

  static OverlayEntry? _entry;

  static void show(
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = defaultDuration,
  }) {
    // Đang build/layout thì chèn Overlay sẽ lỗi → dời sang sau frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance
          .addPostFrameCallback((_) => _insert(message, type, duration));
      return;
    }
    _insert(message, type, duration);
  }

  /// Đóng ngay toast đang hiện (nếu có).
  static void hide() {
    final entry = _entry;
    _entry = null;
    if (entry == null) return;
    entry.remove();
    entry.dispose();
  }

  static void _insert(String message, AppToastType type, Duration duration) {
    final overlay = _rootOverlay();
    if (overlay == null) return;
    hide();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppToastView(
        key: toastKey,
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          if (identical(_entry, entry)) hide();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// Overlay của navigator gốc (GetMaterialApp); không có (vd. test dựng
  /// MaterialApp thường) thì lấy Overlay đầu tiên từ gốc cây widget.
  static OverlayState? _rootOverlay() {
    final fromGet = Get.key.currentState?.overlay;
    if (fromGet != null && fromGet.mounted) return fromGet;
    OverlayState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is OverlayState) {
        found = element.state as OverlayState;
        return;
      }
      element.visitChildElements(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root != null) visit(root);
    return found;
  }
}

class _AppToastView extends StatefulWidget {
  const _AppToastView({
    super.key,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_AppToastView> createState() => _AppToastViewState();
}

class _AppToastViewState extends State<_AppToastView>
    with SingleTickerProviderStateMixin {
  static const Duration _fade = Duration(milliseconds: 200);
  static const double _maxWidth = 320;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _fade)..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  (IconData, Color) get _style => switch (widget.type) {
        AppToastType.info => (Icons.info_outline_rounded, AppColors.darkInfo),
        AppToastType.success => (
            Icons.check_circle_outline_rounded,
            AppColors.darkSuccess
          ),
        AppToastType.error => (
            Icons.error_outline_rounded,
            AppColors.darkError
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, accent) = _style;
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _controller,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Material(
                  color: AppColors.textPrimary,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  child: Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.md,
                        vertical: AppDimens.sm + AppDimens.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 18, color: accent),
                          const SizedBox(width: AppDimens.sm),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textOnPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
