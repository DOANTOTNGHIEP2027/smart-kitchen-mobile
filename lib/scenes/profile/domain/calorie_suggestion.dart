import 'calorie_target.dart';

/// Giới tính dùng cho công thức gợi ý calo (#201, health-profile OAS `Gender`).
enum Gender { male, female }

/// Mức vận động (#201, health-profile OAS `ActivityLevel`) + hệ số TDEE.
enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  const ActivityLevel(this.multiplier);

  final double multiplier;
}

String genderToWire(Gender g) => switch (g) {
      Gender.male => 'MALE',
      Gender.female => 'FEMALE',
    };

/// Giá trị lạ (BE mới hơn) → `null` = "chưa set", không crash.
Gender? genderFromWire(String? raw) => switch (raw) {
      'MALE' => Gender.male,
      'FEMALE' => Gender.female,
      _ => null,
    };

String activityLevelToWire(ActivityLevel a) => switch (a) {
      ActivityLevel.sedentary => 'SEDENTARY',
      ActivityLevel.light => 'LIGHT',
      ActivityLevel.moderate => 'MODERATE',
      ActivityLevel.active => 'ACTIVE',
      ActivityLevel.veryActive => 'VERY_ACTIVE',
    };

ActivityLevel? activityLevelFromWire(String? raw) => switch (raw) {
      'SEDENTARY' => ActivityLevel.sedentary,
      'LIGHT' => ActivityLevel.light,
      'MODERATE' => ActivityLevel.moderate,
      'ACTIVE' => ActivityLevel.active,
      'VERY_ACTIVE' => ActivityLevel.veryActive,
      _ => null,
    };

/// Tuổi tròn năm tại [today] (chưa tới sinh nhật năm nay thì trừ 1).
int ageInYears(DateTime birthDate, DateTime today) {
  var age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age;
}

/// Gợi ý mục tiêu calo/ngày (#201) — hàm thuần, BE chỉ lưu dữ liệu đầu vào.
///
/// Mifflin-St Jeor: BMR = 10·kg + 6.25·cm − 5·tuổi + (5 nam / −161 nữ);
/// TDEE = BMR × hệ số [ActivityLevel]; làm tròn tới bội 50 gần nhất rồi kẹp
/// trong [CalorieTarget.min]–[CalorieTarget.max] của slider.
///
/// Thiếu bất kỳ đầu vào nào (hoặc số đo/tuổi không hợp lệ) → `null`.
int? suggestDailyCalories({
  required double? weightKg,
  required double? heightCm,
  required Gender? gender,
  required DateTime? birthDate,
  required ActivityLevel? activityLevel,
  DateTime? today,
}) {
  if (weightKg == null ||
      heightCm == null ||
      gender == null ||
      birthDate == null ||
      activityLevel == null) {
    return null;
  }
  if (weightKg <= 0 || heightCm <= 0) return null;
  final age = ageInYears(birthDate, today ?? DateTime.now());
  if (age < 0) return null;
  final bmr = 10 * weightKg +
      6.25 * heightCm -
      5 * age +
      (gender == Gender.male ? 5 : -161);
  final tdee = bmr * activityLevel.multiplier;
  final rounded = (tdee / CalorieTarget.step).round() * CalorieTarget.step;
  return rounded.clamp(CalorieTarget.min, CalorieTarget.max);
}
