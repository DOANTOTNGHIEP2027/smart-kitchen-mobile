import '../ai_result.dart';
import '../engine/ai_task.dart';
import '../engine/on_device_inference_engine.dart';
import '../hybrid_ai_runner.dart';

// Task 3 — chấm điểm lặp món (on-device-ai-runtime.md §6.3, §6.6). Port 1:1
// `MealRepetitionScorer` của BE (`meal-planning-core.md` §4), runtime
// `rules-only` — không có model NN (Guard #3).

/// Hằng số công thức — MỘT nguồn sự thật (§6.6.1). `repetition_rules.json`
/// chỉ được kiểm là khớp các hằng này, không bao giờ là nguồn thứ hai. Đổi
/// ngưỡng ⇒ sửa ở đây + khớp BE + tạo `repetition_score/v3`.
abstract final class RepetitionRules {
  /// = `MealRepetitionScorer.DEFAULT_WINDOW_DAYS` (BE): `[ref−14, ref−1]`.
  static const int windowDays = 14;

  /// Lần nấu gần nhất ≤ [recentDays] ngày → [recentScore].
  static const int recentDays = 7;
  static const double recentScore = 1.0;

  /// Lần nấu gần nhất trong (recentDays, windowDays] → [olderScore].
  static const double olderScore = 0.5;

  /// `version` của schema `repetition_rules.json`.
  static const int payloadVersion = 1;

  /// Kiểm payload đã decode khớp ĐÚNG các hằng Dart (§6.6.4). Ném
  /// [FormatException] khi sai — engine đổi thành `modelUnavailable`.
  static void verifyPayload(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('repetition rules must be an object');
    }
    // Key thừa (vd `similarScore`) bị từ chối: sửa asset để "bật" luật mới mà
    // không sửa hằng Dart sẽ lệch BE âm thầm (§6.6.1).
    const allowedKeys = <String>{
      'version',
      'windowDays',
      'recentDays',
      'recentScore',
      'olderScore',
    };
    final unknown = json.keys.where((k) => !allowedKeys.contains(k)).toList();
    if (unknown.isNotEmpty) {
      throw FormatException('unknown keys: $unknown');
    }
    final version = json['version'];
    if (version is! int || version != payloadVersion) {
      throw const FormatException('version must be int 1');
    }
    void intEquals(String key, int expected) {
      final v = json[key];
      if (v is! int || v != expected) {
        throw FormatException('$key must be int $expected, got $v');
      }
    }

    void numEquals(String key, double expected) {
      final v = json[key];
      if (v is! num || v != expected) {
        throw FormatException('$key must be $expected, got $v');
      }
    }

    intEquals('windowDays', windowDays);
    intEquals('recentDays', recentDays);
    numEquals('recentScore', recentScore);
    numEquals('olderScore', olderScore);
  }
}

/// Quy đổi về NGÀY LỊCH Việt Nam (Asia/Ho_Chi_Minh), dạng `DateTime.utc(y,m,d)`
/// (§6.6.2). Áp cho ngày tham chiếu, đồng hồ và mọi `cookedAt`:
/// - `isUtc` (thời điểm) → +7h cố định (VN không có DST) rồi lấy y/m/d;
/// - local (ngày lịch, vd `DateTime(2026, 11, 20)`) → lấy NGUYÊN y/m/d.
DateTime vnDay(DateTime t) {
  if (t.isUtc) {
    final v = t.add(const Duration(hours: 7));
    return DateTime.utc(v.year, v.month, v.day);
  }
  return DateTime.utc(t.year, t.month, t.day);
}

/// Lịch sử món đã nấu gần đây của household — nguồn cache/local-persistence
/// thuộc feature tiêu thụ task này, không thuộc thiết kế runtime. Để khớp BE
/// (`MealRepetitionScorer.loadWindow`), consumer truyền các slot đã CONFIRMED
/// theo `slotDate` trong window (`cookedAt = slotDate`), không chỉ món đã nấu
/// thật.
class CookedDishRecord {
  const CookedDishRecord({required this.dishId, required this.cookedAt});

  /// Khoá nhận diện MÓN ĂN (recipe identity), dựng CÙNG cách với
  /// `candidateDishIds` — để parity với BE thì dùng tên công thức. KHÔNG dùng
  /// `meal_plan_dishes.id` (id vị trí món trong slot): cùng một món ở hai ngày
  /// có hai id khác nhau ⇒ không bao giờ phát hiện lặp (§6.6.3).
  final String dishId;

  /// Thời điểm → truyền UTC; nguồn chỉ có ngày → `DateTime(y, m, d)` local,
  /// không tự cộng/trừ múi giờ (§6.6.2).
  final DateTime cookedAt;
}

class DishRepetitionScore {
  const DishRepetitionScore({
    required this.dishId,
    required this.score,
    required this.withinWindowDays,
  });

  /// Chuỗi NGUYÊN VĂN của phần tử input tương ứng (không phải khoá đã chuẩn hoá).
  final String dishId;

  /// Mức phạt lặp theo lần nấu gần nhất — rời rạc {0.0, 0.5, 1.0} (§6.6.1).
  final double score;

  /// Luôn = [RepetitionRules.windowDays] (khớp `meal-planning-core.md`).
  final int withinWindowDays;
}

class RepetitionScoreResult {
  const RepetitionScoreResult({required this.scores});

  /// 1:1 với `candidateDishIds`: giữ thứ tự, giữ cả phần tử trùng.
  final List<DishRepetitionScore> scores;
}

class RepetitionScoreInput implements InferenceInput {
  const RepetitionScoreInput(this.candidates, this.history, this.referenceDay);
  final List<String> candidates;
  final List<CookedDishRecord> history;

  /// Ngày tham chiếu (= `mealDate` BE) — repository đã tính, engine/hàm chấm
  /// điểm KHÔNG đọc đồng hồ.
  final DateTime referenceDay;
}

class RepetitionScoreOutput implements InferenceOutput {
  const RepetitionScoreOutput(this.result);
  final RepetitionScoreResult result;

  /// Tất định — không có khái niệm confidence (như Task 4).
  @override
  double? get confidence => null;
}

/// Hàm chấm điểm thuần (§6.6.1, ca biên §6.6.5).
abstract final class RepetitionScorer {
  /// `trim + toLowerCase`, GIỮ dấu (`'phở'` ≠ `'pho'`) — = BE `normalize`.
  static String key(String s) => s.trim().toLowerCase();

  static RepetitionScoreResult score(
    List<String> candidates,
    List<CookedDishRecord> history,
    DateTime referenceDay,
  ) {
    final ref = vnDay(referenceDay);
    // Khoảng cách gần nhất trong [1, windowDays] theo từng khoá. Bản ghi cùng
    // ngày (0), tương lai (<0) hoặc cũ hơn window bị bỏ qua.
    final nearest = <String, int>{};
    for (final r in history) {
      final days = ref.difference(vnDay(r.cookedAt)).inDays;
      if (days < 1 || days > RepetitionRules.windowDays) continue;
      final k = key(r.dishId);
      final current = nearest[k];
      if (current == null || days < current) nearest[k] = days;
    }
    return RepetitionScoreResult(scores: <DishRepetitionScore>[
      for (final c in candidates)
        DishRepetitionScore(
          dishId: c,
          score: _penalty(nearest[key(c)]),
          withinWindowDays: RepetitionRules.windowDays,
        ),
    ]);
  }

  static double _penalty(int? days) {
    if (days == null) return 0.0;
    return days <= RepetitionRules.recentDays
        ? RepetitionRules.recentScore
        : RepetitionRules.olderScore;
  }
}

abstract class RepetitionScoreRepository {
  /// [candidateDishIds]: khoá nhận diện món ăn, dựng CÙNG cách với
  /// [CookedDishRecord.dishId] (§6.6.3) — không dùng id vị trí món trong slot.
  /// [recentHistory]: các slot đã CONFIRMED trong window (`cookedAt =
  /// slotDate`) để khớp BE — xem [CookedDishRecord].
  /// [referenceDate]: ngày của bữa đang lên kế hoạch (= `mealDate` BE);
  /// `null` → hôm nay theo Asia/Ho_Chi_Minh. [cloud] `null` → chạy cục bộ
  /// (chưa có endpoint).
  Future<AIResult<RepetitionScoreResult>> score(
    List<String> candidateDishIds,
    List<CookedDishRecord> recentHistory, {
    DateTime? referenceDate,
    Future<RepetitionScoreResult> Function()? cloud,
  });
}

class RepetitionScoreRepositoryImpl implements RepetitionScoreRepository {
  RepetitionScoreRepositoryImpl(this._runner, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final HybridAIRunner _runner;
  final DateTime Function() _clock;

  @override
  Future<AIResult<RepetitionScoreResult>> score(
    List<String> candidateDishIds,
    List<CookedDishRecord> recentHistory, {
    DateTime? referenceDate,
    Future<RepetitionScoreResult> Function()? cloud,
  }) =>
      _runner.run<RepetitionScoreResult>(
        task: AITask.repetitionScore,
        // Hàm cloud tự lo ngày tham chiếu của nó (closure).
        cloud: cloud,
        cloudModelUsed: 'cloud:repetition-score',
        input: RepetitionScoreInput(
          candidateDishIds,
          recentHistory,
          vnDay(referenceDate ?? _clock().toUtc()),
        ),
        fromOutput: (o) => (o as RepetitionScoreOutput).result,
      );
}
