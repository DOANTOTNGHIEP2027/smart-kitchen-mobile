/// Dữ liệu demo cho harness đo hiệu năng #93 (app-performance-audit §6.3).
///
/// Chỉ có hiệu lực trong `DemoBackendAdapter` (tức `EnvConfig.isDemoMode`);
/// không chạm code production. Mọi giá trị mặc định giữ nguyên hành vi demo
/// cũ (không seed, 9 item kho, 8 recipe, độ trễ 450ms).
library;

class DemoPerfSeed {
  const DemoPerfSeed._();

  /// `true` → adapter khởi tạo sẵn household để `/auth/refresh` trả claim có
  /// Nhà → Splash đi thẳng vào shell.
  static const bool seedSession = bool.fromEnvironment('PERF_SEED');

  /// > 0 → kho demo có đúng N item.
  static const int inventoryCount = int.fromEnvironment('PERF_INVENTORY_COUNT');

  /// > 0 → danh sách recipe demo có đúng N id `perf-recipe-<i>`.
  static const int recipeCount = int.fromEnvironment('PERF_RECIPE_COUNT');

  /// Độ trễ giả lập mỗi response (ms).
  static const int latencyMs =
      int.fromEnvironment('PERF_DEMO_LATENCY_MS', defaultValue: 450);

  static const String seededHouseholdId = 'demo-household-0001';
  static const String recipeIdPrefix = 'perf-recipe-';
}

/// Lặp [base] cho đủ [count] item (id hậu tố `-p<i>` an toàn cho URL, tên
/// hiển thị hậu tố `#i`; hạn dùng rải đều
/// 0..13 ngày tới để có cả item sắp hết hạn). `count <= 0` → trả [base].
List<Map<String, dynamic>> expandPerfInventory(
  List<Map<String, dynamic>> base,
  int count, {
  DateTime? now,
}) {
  if (count <= 0 || base.isEmpty) return base;
  final today = (now ?? DateTime.now()).toUtc();
  return List<Map<String, dynamic>>.generate(count, (i) {
    final src = base[i % base.length];
    final days = i % 14;
    final expiry = DateTime.utc(today.year, today.month, today.day + days);
    return <String, dynamic>{
      ...src,
      'id': '${src['id']}-p$i', // không dùng `#` — thành fragment trong URL
      'name': '${src['name']} #$i',
      'expiryDate': expiry.toIso8601String().substring(0, 10),
      'isExpiringSoon': days <= 3,
    };
  }, growable: true);
}

/// Danh sách id recipe demo. `count <= 0` → [base]; ngược lại N id
/// `perf-recipe-<i>` ánh xạ về `base[i % base.length]` (xem
/// [perfRecipeBaseId]).
List<String> perfRecipeIds(List<String> base, int count) {
  if (count <= 0 || base.isEmpty) return base;
  return List<String>.generate(
    count,
    (i) => '${DemoPerfSeed.recipeIdPrefix}$i',
    growable: false,
  );
}

/// Id recipe gốc cho [id]: id perf → `base[i % len]`; id khác → giữ nguyên.
String perfRecipeBaseId(String id, List<String> base) {
  if (!id.startsWith(DemoPerfSeed.recipeIdPrefix) || base.isEmpty) return id;
  final index = int.tryParse(id.substring(DemoPerfSeed.recipeIdPrefix.length));
  if (index == null || index < 0) return id;
  return base[index % base.length];
}
