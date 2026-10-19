import '../../../l10n/app_localizations.dart';
import '../domain/meal_type.dart';

/// Nhãn hiển thị của [MealType] — 1 chỗ duy nhất cho card + bottom sheet.
/// `MealType.label` (domain) là DỮ LIỆU ghép vào description gửi BE, không
/// dùng để hiển thị.
String mealTypeLabel(AppLocalizations l10n, MealType t) => switch (t) {
      MealType.breakfast => l10n.mealLogBreakfast,
      MealType.lunch => l10n.mealLogLunch,
      MealType.dinner => l10n.mealLogDinner,
      MealType.snack => l10n.mealLogSnack,
    };
