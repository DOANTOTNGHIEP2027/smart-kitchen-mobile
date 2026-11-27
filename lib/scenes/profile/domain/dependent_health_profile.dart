import '../../../utils/date_format.dart';
import 'allergen.dart';
import 'calorie_suggestion.dart';
import 'dependent_summary.dart';
import 'diet_type.dart';

/// Health profile đầy đủ của một dependent (`GET/PUT
/// /dependents/{id}/health-profile`, OAS `DependentHealthProfileResponse`).
/// Dữ liệu hạn chế — chỉ guardian active hoặc OWNER đọc được (Guard 1/2).
class DependentHealthProfile {
  const DependentHealthProfile({
    required this.dependentId,
    this.targetDailyCalories,
    this.dietType,
    this.dietTypeRaw,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.activityLevel,
    this.dateOfBirth,
    this.updatedAt,
    required this.allergens,
  });

  final String dependentId;
  final int? targetDailyCalories;
  final DietType? dietType;

  /// Wire gốc của `dietType` ([v1.2 review-125] HIGH-1). `dietTypeRaw != null
  /// && dietType == null` = giá trị FE chưa biết → CHẶN lưu health (PUT
  /// full-replace sẽ gửi `dietType: null` = xoá dữ liệu thật, Guard 19).
  final String? dietTypeRaw;
  final double? heightCm;
  final double? weightKg;

  /// #201 — `null` = chưa set (hoặc giá trị BE mới FE chưa biết).
  final Gender? gender;
  final ActivityLevel? activityLevel;

  /// #201 — CHỈ ĐỌC, lấy từ `dependent_profiles.date_of_birth`; sửa qua
  /// `PATCH /dependents/{id}`, KHÔNG gửi trong PUT health.
  final DateTime? dateOfBirth;

  /// `null` = chưa từng PUT — tín hiệu "empty", không phải HTTP status.
  final DateTime? updatedAt;
  final List<Allergen> allergens;

  bool get isEmpty => updatedAt == null;

  bool get hasUnknownDiet => dietTypeRaw != null && dietType == null;

  factory DependentHealthProfile.fromJson(Map<String, dynamic> json) {
    final dietRaw = json['dietType'] as String?;
    return DependentHealthProfile(
      dependentId: json['dependentId'] as String,
      targetDailyCalories: (json['targetDailyCalories'] as num?)?.toInt(),
      dietType: dependentDietOrNull(dietRaw),
      dietTypeRaw: dietRaw,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      gender: genderFromWire(json['gender'] as String?),
      activityLevel: activityLevelFromWire(json['activityLevel'] as String?),
      dateOfBirth: parseApiDate(json['dateOfBirth']),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      allergens: (json['allergens'] as List<dynamic>? ?? const <dynamic>[])
          .map((Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Patch tại chỗ sau `PUT .../allergens` (Guard 4).
  DependentHealthProfile copyWith({List<Allergen>? allergens}) =>
      DependentHealthProfile(
        dependentId: dependentId,
        targetDailyCalories: targetDailyCalories,
        dietType: dietType,
        dietTypeRaw: dietTypeRaw,
        heightCm: heightCm,
        weightKg: weightKg,
        gender: gender,
        activityLevel: activityLevel,
        dateOfBirth: dateOfBirth,
        updatedAt: updatedAt,
        allergens: allergens ?? this.allergens,
      );
}
