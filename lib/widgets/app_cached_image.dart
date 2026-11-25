import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/network/cache/app_image_cache_manager.dart';
import '../data/network/cache/connectivity_signal.dart';

enum AppCachedImageShape { rectangle, circle }

/// Widget hiển thị ảnh mạng DUY NHẤT toàn app (image-caching-strategy §5.1).
///
/// 2 trạng thái "không phải ảnh":
/// - [`url`] `null`/rỗng → `placeholderIcon` tĩnh (data-absence) — KHÔNG dựng
///   `CachedNetworkImage` (package yêu cầu `imageUrl` non-null, Guard #3).
/// - [`url`] hợp lệ nhưng tải lỗi/offline → `errorIcon` (`errorWidget`,
///   network-level). PHÂN BIỆT với `placeholderIcon` (Guard #4).
///
/// `memCacheWidth` bắt buộc (Guard #5, chỉ chiều rộng — app-performance-audit
/// §7.2 D21) — chống decode full-resolution vào `ImageCache` RAM.
/// Cache width = `max(w, h × [kAppCachedImageMaxAspect]) × dpr` (HIGH-1 review
/// #93): ảnh ngang trong ô vuông/dọc bị `BoxFit.cover` co theo chiều cao, chỉ
/// lấy `w` sẽ decode thiếu pixel rồi phóng to → mờ.
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.shape = AppCachedImageShape.rectangle,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
    this.errorIcon = Icons.wifi_off_rounded,
  });

  final String? url;
  final double width;
  final double height;
  final AppCachedImageShape shape;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final IconData errorIcon;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _wrapShape(
        _IconBox(icon: placeholderIcon, width: width, height: height),
      );
    }
    // #93 F4 (app-performance-audit §7.2): luôn có chiều rộng hữu hạn để
    // giới hạn decode — caller truyền `double.infinity` thì lấy chiều rộng
    // thật của ô qua LayoutBuilder. Ô không giới hạn → null như cũ (không crash).
    if (width.isFinite) return _buildImage(context, width, height);
    return LayoutBuilder(
      builder: (context, constraints) => _buildImage(
        context,
        constraints.hasBoundedWidth ? constraints.maxWidth : null,
        height.isFinite
            ? height
            : (constraints.hasBoundedHeight ? constraints.maxHeight : null),
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    double? logicalWidth,
    double? logicalHeight,
  ) {
    // `devicePixelRatioOf` — chỉ phụ thuộc DPR, không rebuild khi viewInsets đổi.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    int? cacheWidth;
    if (logicalWidth != null && logicalWidth.isFinite && logicalWidth > 0) {
      // Ô không giới hạn chiều rộng → null như cũ; chiều cao vô hạn/không có
      // thì chỉ dùng `w`.
      final coverByHeight =
          (logicalHeight != null && logicalHeight.isFinite && logicalHeight > 0)
              ? logicalHeight * kAppCachedImageMaxAspect
              : 0.0;
      cacheWidth = (math.max(logicalWidth, coverByHeight) * dpr).round();
    }
    return _wrapShape(
      CachedNetworkImage(
        imageUrl: url!,
        cacheManager: AppImageCacheManager.instance,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Chỉ set chiều rộng (D21): set cả memCacheHeight thì ResizeImage
        // policy `exact` ép ảnh đúng tỉ lệ ô trước BoxFit.cover → méo hình.
        memCacheWidth: cacheWidth,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, _) {
          // Tuỳ chọn nâng cao (§5.3) — bỏ qua nếu ConnectivitySignal chưa đăng ký.
          final online = Get.isRegistered<ConnectivitySignal>()
              ? Get.find<ConnectivitySignal>().isOnline
              : true; // mặc định lạc quan — không có tín hiệu thì thử tải như bình thường
          if (!online) {
            // Đang offline: bỏ spinner chờ-timeout vô ích (Guard #7 ref),
            // nhưng KHÔNG ép errorIcon ngay — nếu ảnh đã có trong disk-cache thì
            // `flutter_cache_manager` serve luôn, còn cache-miss chính errorWidget
            // mới hiển thị errorIcon (LOW fix review Task 4 — tránh flash lỗi
            // khi vẫn có ảnh cached).
            return _IconBox(
              icon: placeholderIcon,
              width: width,
              height: height,
            );
          }
          return _IconBox(
            icon: placeholderIcon,
            width: width,
            height: height,
            showSpinner: true,
          );
        },
        errorWidget: (context, _, error) =>
            _IconBox(icon: errorIcon, width: width, height: height),
      ),
    );
  }

  Widget _wrapShape(Widget child) => shape == AppCachedImageShape.circle
      ? ClipOval(child: child)
      : ClipRRect(
          borderRadius: borderRadius ??
              const BorderRadius.all(Radius.circular(kAppCachedImageRadius)),
          child: child,
        );
}

const double kAppCachedImageRadius = 8;

/// Tỉ lệ ngang (w/h) tối đa của ảnh nguồn mà cache width còn đủ nét khi
/// `BoxFit.cover` co theo chiều cao (HIGH-1 review #93, amend D21).
const double kAppCachedImageMaxAspect = 2.0;

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    required this.width,
    required this.height,
    this.showSpinner = false,
  });

  final IconData icon;
  final double width;
  final double height;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: showSpinner
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(
                icon,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.6),
              ),
      );
}