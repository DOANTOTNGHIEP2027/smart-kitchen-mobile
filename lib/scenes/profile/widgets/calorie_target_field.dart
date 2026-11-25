import 'package:flutter/material.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/calorie_target.dart';

/// Slider mục tiêu calo 800–5000 bước 50 + toggle "Chưa đặt mục tiêu"
/// (§10.3 S10.4/S10.4b/S10.4c, Guard 14). Không giữ state — màn cha sở hữu
/// `sliderValue` / `notSet` / `touched` và tính payload bằng
/// [CalorieTarget.resolveForSave].
class CalorieTargetField extends StatelessWidget {
  const CalorieTargetField({
    super.key,
    required this.stored,
    required this.touched,
    required this.notSet,
    required this.sliderValue,
    required this.enabled,
    required this.onSliderChanged,
    required this.onNotSetChanged,
    this.errorText,
  });

  /// Giá trị đang lưu trên server (có thể ngoài khoảng slider).
  final int? stored;
  final bool touched;
  final bool notSet;
  final int sliderValue;
  final bool enabled;
  final ValueChanged<int> onSliderChanged;
  final ValueChanged<bool> onNotSetChanged;

  /// Lỗi từ `fieldErrors.targetDailyCalories` của BE (S10.5).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final legacyOutOfRange = !touched &&
        !notSet &&
        stored != null &&
        !CalorieTarget.isInSliderRange(stored);
    final valueText = notSet
        ? l.healthProfileCaloriesNotSet
        : legacyOutOfRange
            ? l.healthProfileCaloriesCurrent(stored!)
            : l.healthProfileKcalValue(sliderValue);
    final error = errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l.healthProfileTargetCalories, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppDimens.xs),
        Text(
          valueText,
          key: const ValueKey<String>('health-calorie-label'),
          style: theme.textTheme.titleLarge,
        ),
        if (legacyOutOfRange)
          Text(
            l.healthProfileCaloriesOutOfRange(
                CalorieTarget.min, CalorieTarget.max),
            key: const ValueKey<String>('health-calorie-legacy-note'),
            style: theme.textTheme.bodySmall,
          ),
        Slider(
          key: const ValueKey<String>('health-calorie-slider'),
          min: CalorieTarget.min.toDouble(),
          max: CalorieTarget.max.toDouble(),
          divisions: CalorieTarget.divisions,
          value: sliderValue.toDouble(),
          label: l.healthProfileKcalValue(sliderValue),
          onChanged: enabled && !notSet
              ? (double v) => onSliderChanged(CalorieTarget.snap(v))
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('${CalorieTarget.min}', style: theme.textTheme.bodySmall),
            Text('${CalorieTarget.max}', style: theme.textTheme.bodySmall),
          ],
        ),
        SwitchListTile(
          key: const ValueKey<String>('health-calorie-notset'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.healthProfileCaloriesNotSetToggle),
          value: notSet,
          onChanged: enabled ? onNotSetChanged : null,
        ),
        if (error != null)
          Text(
            error,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
      ],
    );
  }
}
