import 'food_item_detected.dart';
import 'meal_nutrition_macros.dart';
import 'meal_type.dart';

/// Trạng thái client-only của 1 entry — dùng cho optimistic UI và reconciliation.
enum MealEntryStatus { saved, pending, failed }

/// Badge nhị phân — KHÔNG PHẢI 3 mức theo % confidence (Decision D1, meal-log'.
/// screen §2). `noEstimate` tách biệt khỏi `needsReview` vì trải nghiệm sửa
/// khác hẳn nhau (CalorieConfirmSheet §10): `needsReview` pre-fill số AI,
/// `noEstimate` bắt buộc nhập tay.
enum MealConfidenceBadge { confident, needsReview, noEstimate }

/// Nhật ký 1 bữa ăn (#77 `MealLogResponse`).
class MealLogEntry {
  const MealLogEntry({
    required this.id,
    required this.householdId,
    required this.memberId,
    required this.loggedBy,
    this.sessionId,
    this.description,
    this.caloriesKcal,
    this.nutrition,
    this.foodItemsDetected,
    required this.requiresConfirmation,
    required this.confirmedByUser,
    required this.loggedAt,
    this.confirmedAt,
    required this.status,
  });

  /// `local-<counter>` khi `status == pending/failed`, id UUID thật của BE khi `saved`.
  final String id;
  final String householdId;
  final String memberId;
  final String loggedBy;
  final String? sessionId;
  final String? description;
  final double? caloriesKcal;
  final MealNutritionMacros? nutrition;
  final List<FoodItemDetected>? foodItemsDetected;

  /// Cột `requiresConfirmation` thật (boolean) — KHÔNG có field confidence số.
  final bool requiresConfirmation;
  final bool confirmedByUser;
  final DateTime loggedAt;
  final DateTime? confirmedAt;
  final MealEntryStatus status;

  MealType? get mealType => parseMealTypeFromDescription(description);

  MealConfidenceBadge get confidenceBadge {
    if (caloriesKcal == null) return MealConfidenceBadge.noEstimate;
    return requiresConfirmation
        ? MealConfidenceBadge.needsReview
        : MealConfidenceBadge.confident;
  }

  /// Mirror CHÍNH XÁC predicate SQL của `meal-log-nutrition.md` Guard #4
  /// (`calories_kcal IS NOT NULL AND (confirmed_by_user = TRUE OR
  /// requires_confirmation = FALSE)`). Là bản mirror phía client cho 1 rule
  /// chỉ tồn tại ở BE cho `GET .../nutrition/weekly` — nếu BE Guard #4 đổi,
  /// cập nhật lại đây (Implementation Guard #4).
  bool get countsTowardDailyTotal =>
      caloriesKcal != null && (confirmedByUser || !requiresConfirmation);

  MealLogEntry copyWith({
    String? id,
    double? caloriesKcal,
    MealNutritionMacros? nutrition,
    List<FoodItemDetected>? foodItemsDetected,
    bool? requiresConfirmation,
    bool? confirmedByUser,
    DateTime? confirmedAt,
    MealEntryStatus? status,
  }) {
    return MealLogEntry(
      id: id ?? this.id,
      householdId: householdId,
      memberId: memberId,
      loggedBy: loggedBy,
      sessionId: sessionId,
      description: description,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      nutrition: nutrition ?? this.nutrition,
      foodItemsDetected: foodItemsDetected ?? this.foodItemsDetected,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      confirmedByUser: confirmedByUser ?? this.confirmedByUser,
      loggedAt: loggedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      status: status ?? this.status,
    );
  }
}

/// Ảnh vẫn còn quá lớn sau khi nén — hiển thị banner cục bộ trong bottom
/// sheet, không tạo request (Guard mismatch với #79 §2.1 `MAX_IMAGE_BYTES`).
class MealPhotoTooLargeLocalException implements Exception {
  const MealPhotoTooLargeLocalException();
}