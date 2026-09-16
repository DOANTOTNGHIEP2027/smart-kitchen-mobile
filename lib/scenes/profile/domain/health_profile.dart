import 'allergen.dart';
import 'diet_type.dart';

/// Health profile của chính caller (GET/PUT `/users/me/health-profile`).
///
/// `updatedAt == null` = "row profile chưa được tạo" — BE luôn 200 không 404
/// (OAS Implementation Guard 2). `allergens` luôn có mặt (embedded), [] nếu chưa
/// chọn — là nguồn duy nhất cho "đang chọn allergen nào" (Implementation
/// Guard 10 của FE-3, Fix HIGH-1).
class HealthProfile {
  const HealthProfile({
    required this.userId,
    this.targetDailyCalories,
    this.dietType,
    this.heightCm,
    this.weightKg,
    this.updatedAt,
    required this.allergens,
  });

  final String userId;
  final int? targetDailyCalories;
  final DietType? dietType;
  final double? heightCm;
  final double? weightKg;
  final DateTime? updatedAt;
  final List<Allergen> allergens;

  bool get isEmpty => updatedAt == null;

  HealthProfile copyWith({List<Allergen>? allergens}) => HealthProfile(
        userId: userId,
        targetDailyCalories: targetDailyCalories,
        dietType: dietType,
        heightCm: heightCm,
        weightKg: weightKg,
        updatedAt: updatedAt,
        allergens: allergens ?? this.allergens,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'targetDailyCalories': targetDailyCalories,
        'dietType': dietType == null ? null : dietTypeToWire(dietType!),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'updatedAt': updatedAt?.toUtc().toIso8601String(),
        'allergens': allergens
            .map((Allergen a) => a.toJson())
            .toList(growable: false),
      };

  static HealthProfile fromJson(Map<String, dynamic> json) {
    final dietRaw = json['dietType'] as String?;
    return HealthProfile(
      userId: json['userId'] as String,
      targetDailyCalories: (json['targetDailyCalories'] as num?)?.toInt(),
      dietType: dietRaw == null ? null : dietTypeFromWire(dietRaw),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      allergens: (json['allergens'] as List<dynamic>)
          .map((Object? e) => Allergen.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
