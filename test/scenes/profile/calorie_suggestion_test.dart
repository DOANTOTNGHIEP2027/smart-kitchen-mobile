import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/calorie_suggestion.dart';

void main() {
  final today = DateTime(2026, 11, 28);

  int? suggest({
    double? weight = 70,
    double? height = 175,
    Gender? gender = Gender.male,
    DateTime? birth,
    ActivityLevel? activity = ActivityLevel.moderate,
  }) =>
      suggestDailyCalories(
        weightKg: weight,
        heightCm: height,
        gender: gender,
        birthDate: birth ?? DateTime(1996, 1, 1), // 30 tuổi
        activityLevel: activity,
        today: today,
      );

  test('nam 70kg 175cm 30 tuổi vận động vừa → BMR 1648.75 ×1.55 → 2550', () {
    expect(suggest(), 2550);
  });

  test('nữ: −161 thay vì +5', () {
    // BMR = 700 + 1093.75 − 150 − 161 = 1482.75; ×1.2 = 1779.3 → 1800.
    expect(suggest(gender: Gender.female, activity: ActivityLevel.sedentary),
        1800);
  });

  test('tuổi chưa tới sinh nhật năm nay thì trừ 1', () {
    expect(ageInYears(DateTime(1996, 12, 1), today), 29);
    expect(ageInYears(DateTime(1996, 11, 28), today), 30);
  });

  test('kẹp trong 800–5000', () {
    expect(suggest(weight: 20, height: 60, gender: Gender.female,
            activity: ActivityLevel.sedentary),
        800);
    expect(suggest(weight: 300, height: 250, activity: ActivityLevel.veryActive),
        5000);
  });

  test('thiếu bất kỳ đầu vào nào → null', () {
    expect(suggest(weight: null), isNull);
    expect(suggest(height: null), isNull);
    expect(suggest(gender: null), isNull);
    expect(suggest(activity: null), isNull);
    expect(
        suggestDailyCalories(
            weightKg: 70,
            heightCm: 175,
            gender: Gender.male,
            birthDate: null,
            activityLevel: ActivityLevel.moderate),
        isNull);
  });

  test('wire map 2 chiều, giá trị lạ → null', () {
    for (final a in ActivityLevel.values) {
      expect(activityLevelFromWire(activityLevelToWire(a)), a);
    }
    for (final g in Gender.values) {
      expect(genderFromWire(genderToWire(g)), g);
    }
    expect(activityLevelFromWire('X'), isNull);
    expect(genderFromWire(null), isNull);
  });
}
