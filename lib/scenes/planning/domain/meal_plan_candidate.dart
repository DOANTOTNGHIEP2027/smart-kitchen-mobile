/// Kết quả hard filter của Selection Engine (I1).
enum HardConstraintStatus { passed, blocked }

/// 1 feature trong `softScoreBreakdown` của engine — giá trị, trọng số, đóng
/// góp đều đọc từ response, KHÔNG hardcode ở FE (thiết kế §5.3).
class SoftScoreFeature {
  const SoftScoreFeature({
    required this.key,
    this.value,
    this.weight,
    this.contribution,
  });

  /// Key gốc của engine (snake_case, vd. `expiry_urgency`) — map BE truyền
  /// nguyên `feature_breakdown` của AI, không đổi tên.
  final String key;
  final double? value;
  final double? weight;
  final double? contribution;
}

/// 1 ứng viên trong `GET /meal-plans/{mealPlanId}/candidates`
/// (`MealPlanCandidateResponse` thật của BE). Khác thiết kế §5.3: không có
/// `dishId`/`slotId`; gắn với vote session qua [sessionId] (OD-08).
class MealPlanCandidate {
  const MealPlanCandidate({
    required this.id,
    required this.sessionId,
    required this.recipeId,
    required this.recipeName,
    required this.hardConstraintStatus,
    this.blockedReason,
    required this.isAlgorithmRecommended,
    this.softScore,
    this.features = const <SoftScoreFeature>[],
    this.profileVersion,
    this.repetitionPenalty,
    this.allergenTags = const <String>[],
    this.evaluatedAt,
  });

  final String id;
  final String sessionId;
  final String recipeId;
  final String recipeName;
  final HardConstraintStatus hardConstraintStatus;
  final String? blockedReason;

  /// Tối đa 1 ứng viên `true` trong 1 phiên (I8).
  final bool isAlgorithmRecommended;
  final double? softScore;
  final List<SoftScoreFeature> features;
  final String? profileVersion;
  final double? repetitionPenalty;
  final List<String> allergenTags;
  final DateTime? evaluatedAt;

  bool get isBlocked => hardConstraintStatus == HardConstraintStatus.blocked;

  /// Dòng legacy chưa từng qua engine: migration đặt DEFAULT 'PASSED' và
  /// `evaluatedAt = null`. KHÔNG được hiện là "đã qua kiểm tra an toàn".
  bool get isUnverified => !isBlocked && evaluatedAt == null;

  static const Set<String> _breakdownMetaKeys = <String>{
    'weights',
    'contributions',
    'profile_version',
  };

  factory MealPlanCandidate.fromJson(Map<String, dynamic> json) {
    final breakdown = json['softScoreBreakdown'] is Map
        ? Map<String, dynamic>.from(json['softScoreBreakdown'] as Map)
        : const <String, dynamic>{};
    final weights = _numMap(breakdown['weights']);
    final contributions = _numMap(breakdown['contributions']);
    // AI đánh dấu feature không có đầu vào, KHÔNG tính vào score → không vẽ.
    final inactive = breakdown['inactive_features'] is List
        ? (breakdown['inactive_features'] as List).whereType<String>().toSet()
        : const <String>{};
    final features = <SoftScoreFeature>[
      for (final entry in breakdown.entries)
        if (!_breakdownMetaKeys.contains(entry.key) &&
            !inactive.contains(entry.key) &&
            (entry.value == null || entry.value is num))
          SoftScoreFeature(
            key: entry.key,
            value: (entry.value as num?)?.toDouble(),
            weight: weights[entry.key],
            contribution: contributions[entry.key],
          ),
    ];
    return MealPlanCandidate(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      recipeId: json['recipeId'] as String,
      recipeName: json['recipeName'] as String,
      // Fail-safe: chỉ đúng `PASSED` mới là đã qua kiểm tra; null/giá trị lạ
      // coi như bị chặn (lý do "chưa kiểm chứng"), không hiện nhãn an toàn.
      hardConstraintStatus: json['hardConstraintStatus'] == 'PASSED'
          ? HardConstraintStatus.passed
          : HardConstraintStatus.blocked,
      blockedReason: json['blockedReason'] as String?,
      // Record Java `boolean algorithmRecommended` → JSON không có tiền tố `is`.
      isAlgorithmRecommended: json['algorithmRecommended'] as bool? ?? false,
      softScore: (json['softScore'] as num?)?.toDouble(),
      features: features,
      profileVersion: breakdown['profile_version'] as String?,
      repetitionPenalty: (json['repetitionPenalty'] as num?)?.toDouble(),
      allergenTags: ((json['allergenTags'] as List?) ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      evaluatedAt: json['evaluatedAt'] == null
          ? null
          : DateTime.parse(json['evaluatedAt'] as String),
    );
  }

  static Map<String, double> _numMap(Object? raw) {
    if (raw is! Map) return const <String, double>{};
    return <String, double>{
      for (final entry in raw.entries)
        if (entry.value is num)
          entry.key as String: (entry.value as num).toDouble(),
    };
  }
}

/// Ứng viên của 1 vote session (1 món), đã sắp đúng thứ tự hiển thị §8.3.
class CandidateGroup {
  const CandidateGroup({required this.sessionId, required this.candidates});

  final String sessionId;
  final List<MealPlanCandidate> candidates;

  /// `[]` KHÔNG tính là "toàn bộ bị chặn" — tránh banner sai khi rỗng.
  bool get allBlocked =>
      candidates.isNotEmpty && candidates.every((c) => c.isBlocked);

  DateTime? get evaluatedAt => candidates
      .map((c) => c.evaluatedAt)
      .whereType<DateTime>()
      .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

  /// `isAlgorithmRecommended` trước → PASSED trước BLOCKED → softScore giảm
  /// dần (null coi như nhỏ nhất, không throw).
  static List<MealPlanCandidate> sortForDisplay(
      Iterable<MealPlanCandidate> candidates) {
    final list = <MealPlanCandidate>[...candidates];
    list.sort((a, b) {
      if (a.isAlgorithmRecommended != b.isAlgorithmRecommended) {
        return a.isAlgorithmRecommended ? -1 : 1;
      }
      if (a.isBlocked != b.isBlocked) return a.isBlocked ? 1 : -1;
      if (a.isUnverified != b.isUnverified) return a.isUnverified ? 1 : -1;
      return (b.softScore ?? -1).compareTo(a.softScore ?? -1);
    });
    return list;
  }
}
