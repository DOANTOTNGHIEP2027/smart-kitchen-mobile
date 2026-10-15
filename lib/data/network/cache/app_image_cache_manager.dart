import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cấu hình disk-cache ảnh mạng DUY NHẤT toàn app (image-caching-strategy §5.2).
///
/// ⚠️ Guard #1: KHÔNG tạo `CacheManager` với `key` khác ở bất kỳ đâu khác — mỗi
/// key khác nhau tạo 1 database SQLite cache riêng của `flutter_cache_manager`,
/// phá vỡ giới hạn "≈100MB toàn app" thành N giới hạn cộng dồn vượt mức.
///
/// "100MB" là XẤP XỈ (≤500 object × ~200KB), không phải cam kết byte chính xác:
/// `flutter_cache_manager`'s `Config` chỉ nhận `stalePeriod` + `maxNrOfCacheObjects`
/// (LRU-evict object cũ nhất-ít-dùng-nhất khi vượt số) — không có tham số byte-cap.
class AppImageCacheManager {
  AppImageCacheManager._();

  static const String _key = 'smartKitchenImageCache';

  /// 1 instance DUY NHẤT toàn app — mọi `AppCachedImage` dùng chung.
  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 7), // "max age 7 ngày" — issue gốc
      maxNrOfCacheObjects: 500, // XẤP XỈ 100MB (500 × ~200KB) — xem §5.2.1
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
    ),
  );
}