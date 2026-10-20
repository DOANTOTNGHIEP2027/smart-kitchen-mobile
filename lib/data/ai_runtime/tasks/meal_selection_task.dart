import 'dart:convert';
import 'dart:typed_data';

import '../../../domain/shared/allergen_derivation.dart';
import '../ai_result.dart';
import '../engine/ai_task.dart';
import '../engine/on_device_inference_engine.dart';
import '../hybrid_ai_runner.dart';

/// 1 món ứng viên cho chọn món on-device (§6.4).
class MealCandidate {
  const MealCandidate({
    required this.dishId,
    required this.name,
    this.allergenTags,
    this.allergenDerivation = AllergenDerivation.unknown,
    this.repetitionScore,
    this.expiringIngredientMatch,
  });

  final String dishId;
  final String name;

  /// Tag dị ứng của món. `null` = CHƯA KIỂM CHỨNG — KHÔNG phải "an toàn"
  /// (AGENTS.md "An toàn dị ứng — không được im lặng"). Thêm vào shape
  /// placeholder của thiết kế vì thiếu nó thì không lọc cứng dị ứng được.
  final Set<String>? allergenTags;

  /// Tag rỗng chỉ là "an toàn" khi derivation == `ingredientRule` — khác đi là
  /// "chưa kiểm được" (cùng luật `MealSuggestion.isAllergenCleared`).
  final AllergenDerivation allergenDerivation;

  /// 0..1 — 1 = lặp gần như y hệt trong cửa sổ (task 3). `null` = chưa tính.
  final double? repetitionScore;

  /// 0..1 — tỉ lệ nguyên liệu trùng inventory sắp hết hạn. `null` = chưa tính.
  final double? expiringIngredientMatch;
}

/// Ràng buộc cứng của household. Trọng số mềm đọc từ `rules_config.json`
/// (placeholder — chờ product chốt, open-questions Q1).
class HouseholdConstraints {
  const HouseholdConstraints({required this.hardAllergenExclusions});

  final Set<String> hardAllergenExclusions;
}

class MealSelectionResult {
  const MealSelectionResult({required this.selectedDishId, required this.ruleTrace});

  /// `null` khi MỌI ứng viên bị loại bởi ràng buộc cứng.
  final String? selectedDishId;

  /// Log đọc được của từng rule đã áp (kiểm chứng/giải thích được).
  final List<String> ruleTrace;
}

class MealSelectionInput implements InferenceInput {
  const MealSelectionInput(this.candidates, this.constraints);

  final List<MealCandidate> candidates;
  final HouseholdConstraints constraints;
}

class MealSelectionOutput implements InferenceOutput {
  const MealSelectionOutput(this.result);

  final MealSelectionResult result;

  /// Tất định — không có khái niệm confidence.
  @override
  double? get confidence => null;
}

/// Thuật toán chọn món tường minh, Dart thuần, FE-local (§4.1, D2/D9) — KHÔNG
/// đi qua runtime NN (Guard #3). Cấu trúc: lọc cứng dị ứng TRƯỚC, xếp hạng mềm
/// SAU. Feature thiếu dữ liệu → bỏ khỏi tổng và TÁI CHUẨN HOÁ trọng số còn lại
/// (§6.4 AMEND 2026-08-26).
class OnDeviceMealSelectionRuleEngine {
  const OnDeviceMealSelectionRuleEngine(this.weights);

  /// `expiringPriority` (cộng điểm) và `repetitionPenalty` (trừ điểm).
  final Map<String, double> weights;

  factory OnDeviceMealSelectionRuleEngine.fromConfig(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final raw = json['weights'] as Map<String, dynamic>;
    final weights = <String, double>{
      for (final e in raw.entries) e.key: (e.value as num).toDouble(),
    };
    // Trọng số âm/thiếu làm đảo dấu hoặc triệt tiêu tổng khi tái chuẩn hoá —
    // từ chối config (→ ERR_ONDEVICE_MODEL_UNAVAILABLE) thay vì xếp hạng sai.
    for (final key in const <String>['expiringPriority', 'repetitionPenalty']) {
      final w = weights[key];
      if (w == null || !w.isFinite || w < 0) {
        throw FormatException('weight $key invalid: $w');
      }
    }
    return OnDeviceMealSelectionRuleEngine(weights);
  }

  static String _normAllergen(String tag) => tag.trim().toUpperCase();

  /// NaN → coi như thiếu tín hiệu; ngoài 0..1 → kẹp lại (tránh đảo dấu điểm).
  static double? _signal(double? v) =>
      v == null || v.isNaN ? null : v.clamp(0.0, 1.0).toDouble();

  MealSelectionResult select(List<MealCandidate> candidates, HouseholdConstraints constraints) {
    final trace = <String>[];
    // Không phân biệt hoa/thường (người duyệt chốt 2026-10-20, OD-26): 'gluten'
    // và 'GLUTEN' phải là CÙNG một dị ứng — lệch chữ mà lọt là mất an toàn.
    final exclusions = constraints.hardAllergenExclusions.map(_normAllergen).toSet();
    final eligible = <MealCandidate>[];
    for (final c in candidates) {
      final tags = c.allergenTags?.map(_normAllergen).toSet();
      final hit = tags?.intersection(exclusions) ?? const <String>{};
      if (hit.isNotEmpty) {
        trace.add('loại ${c.name}: dị ứng ${hit.join(', ')} (hard)');
        continue;
      }
      if (exclusions.isNotEmpty &&
          (tags == null || c.allergenDerivation != AllergenDerivation.ingredientRule)) {
        trace.add('loại ${c.name}: chưa kiểm chứng dị ứng (hard)');
        continue;
      }
      eligible.add(c);
    }
    if (eligible.isEmpty) {
      trace.add('không còn món nào qua ràng buộc dị ứng');
      return MealSelectionResult(selectedDishId: null, ruleTrace: trace);
    }

    MealCandidate? best;
    var bestScore = double.negativeInfinity;
    for (final c in eligible) {
      final expiring = _signal(c.expiringIngredientMatch);
      final repetition = _signal(c.repetitionScore);
      final parts = <(String, double, double)>[
        if (expiring != null)
          ('expiringPriority', weights['expiringPriority']!, expiring),
        if (repetition != null)
          ('repetitionPenalty', weights['repetitionPenalty']!, 1 - repetition),
      ];
      final totalWeight = parts.fold<double>(0, (s, p) => s + p.$2);
      final score = totalWeight <= 0
          ? 0.0
          : parts.fold<double>(0, (s, p) => s + p.$2 * p.$3) / totalWeight;
      trace.add('${c.name}: ${score.toStringAsFixed(2)}'
          '${parts.isEmpty ? ' (không có tín hiệu mềm)' : ''}');
      // Hoà điểm → giữ món đứng trước (ổn định, tất định).
      if (score > bestScore) {
        best = c;
        bestScore = score;
      }
    }
    trace.add('chọn ${best!.name}');
    return MealSelectionResult(selectedDishId: best.dishId, ruleTrace: trace);
  }
}

abstract class MealSelectionRepository {
  /// [cloud] = đường chọn món của BE (do feature tiêu thụ cung cấp); `null` →
  /// luôn chạy cục bộ.
  Future<AIResult<MealSelectionResult>> select(
    List<MealCandidate> candidates,
    HouseholdConstraints constraints, {
    Future<MealSelectionResult> Function()? cloud,
  });
}

class MealSelectionRepositoryImpl implements MealSelectionRepository {
  MealSelectionRepositoryImpl(this._runner);

  final HybridAIRunner _runner;

  @override
  Future<AIResult<MealSelectionResult>> select(
    List<MealCandidate> candidates,
    HouseholdConstraints constraints, {
    Future<MealSelectionResult> Function()? cloud,
  }) =>
      _runner.run<MealSelectionResult>(
        task: AITask.ruleBasedSelection,
        cloud: cloud,
        cloudModelUsed: 'cloud:meal-recommendation-engine',
        input: MealSelectionInput(candidates, constraints),
        fromOutput: (o) => (o as MealSelectionOutput).result,
      );
}
