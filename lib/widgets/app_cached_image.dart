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
/// `memCacheWidth`/`memCacheHeight` bắt buộc (Guard #5) — chống decode
/// full-resolution vào `ImageCache` RAM (đóng MỘT PHẦN app-performance-audit §7.3).
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
    // Chỉ ép memCache size khi cả hai kích thước hữu hạn — `double.infinity`
    // (caller truyền "full") không thể `.round()` làm crash decode (Guard #5).
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final hasFiniteSize = width.isFinite && height.isFinite;
    return _wrapShape(
      CachedNetworkImage(
        imageUrl: url!,
        cacheManager: AppImageCacheManager.instance,
        width: width,
        height: height,
        fit: BoxFit.cover,
        memCacheWidth: hasFiniteSize ? (width * dpr).round() : null,
        memCacheHeight: hasFiniteSize ? (height * dpr).round() : null,
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