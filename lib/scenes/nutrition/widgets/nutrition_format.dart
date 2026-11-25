import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../utils/l10n_x.dart';

/// Định dạng số/ngày dùng chung cho widget dinh dưỡng (theo locale hiện tại).
extension NutritionFormatX on BuildContext {
  String get _locale => Localizations.localeOf(this).toString();

  String kcalNumber(num value) =>
      NumberFormat.decimalPattern(_locale).format(value.round());

  String grams(num value) => value.round().toString();

  String percent(double value) =>
      NumberFormat('#0.0', _locale).format(value);

  /// "Thứ Tư 18/11" / "Wednesday 18/11".
  String fullDay(DateTime date) => DateFormat('EEEE d/M', _locale).format(date);

  String shortWeekday(DateTime date) => DateFormat.E(_locale).format(date);

  String mealLabel(String mealTime) => switch (mealTime) {
        'BREAKFAST' => l10n.nutritionMealBreakfast,
        'LUNCH' => l10n.nutritionMealLunch,
        'DINNER' => l10n.nutritionMealDinner,
        'SNACK' => l10n.nutritionMealSnack,
        _ => l10n.nutritionMealOther,
      };
}
