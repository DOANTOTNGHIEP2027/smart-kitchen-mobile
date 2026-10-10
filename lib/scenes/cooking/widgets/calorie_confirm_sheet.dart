import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../profile/stores/form_status.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../stores/meal_log_store.dart';
import '../domain/meal_log_entry.dart';

/// Bottom sheet xác nhận/sửa calo của 1 meal log (meal-log-screen §10).
///
/// 3 nhánh chính:
/// - Sửa ước tính low-confidence: pre-fill `entry.caloriesKcal`, editable;
///   "Xác nhận" gửi body rỗng nếu không sửa (chấp nhận as-is) hoặc giá trị mới.
/// - Nhập tay bắt buộc (`caloriesKcal == null`): field RỖNG, phải nhập đúng
///   [0, 10000] trước khi enable (Guard #10).
/// - Submitting: nút is-loading, field khoá.
class CalorieConfirmSheet extends StatefulWidget {
  const CalorieConfirmSheet({
    super.key,
    required this.entry,
    required this.store,
  });

  final MealLogEntry entry;
  final MealLogStore store;

  @override
  State<CalorieConfirmSheet> createState() => _CalorieConfirmSheetState();
}

class _CalorieConfirmSheetState extends State<CalorieConfirmSheet> {
  late final TextEditingController _controller;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    final kcal = widget.entry.caloriesKcal;
    _controller = TextEditingController(
      text: kcal == null ? '' : _trimDouble(kcal),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _trimDouble(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  bool get _needsManualInput => widget.entry.caloriesKcal == null;

  double? get _enteredValue {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _confirm() async {
    final entered = _enteredValue;
    if (_needsManualInput) {
      if (entered == null || entered < 0 || entered > 10000) {
        setState(() => _fieldError = context.l10n.mealLogCaloriesInvalid);
        return;
      }
    }
    setState(() => _fieldError = null);
    final ok = _needsManualInput
        ? await widget.store
            .confirmCalories(widget.entry.id, caloriesKcal: entered)
        : entered == null
            ? await widget.store.confirmCalories(widget.entry.id)
            : await widget.store
                .confirmCalories(widget.entry.id, caloriesKcal: entered);
    if (ok) {
      widget.store.clearConfirmError();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submitting =
        widget.store.confirmStatus == FormStatus.submitting;
    final confirmError = widget.store.confirmError;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.mealLogConfirmTitle,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimens.md),
            TextField(
              controller: _controller,
              enabled: !submitting,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.mealLogEnterCalories,
                hintText: _needsManualInput ? 'kcal' : null,
                errorText: _fieldError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
            ),
            if (_fieldError != null) ...<Widget>[
              const SizedBox(height: AppDimens.sm),
              Text(_fieldError!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error)),
            ],
            if (!_needsManualInput) ...<Widget>[
              const SizedBox(height: AppDimens.xs),
              TextButton(
                onPressed: submitting ? null : _confirm,
                child: Text(l10n.mealLogConfirmAsIs),
              ),
            ],
            if (confirmError != null) ...<Widget>[
              const SizedBox(height: AppDimens.sm),
              Text(confirmError.message,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.error)),
            ],
            const SizedBox(height: AppDimens.md),
            AppButton(
              label: l10n.mealLogConfirm,
              isLoading: submitting,
              onPressed: _needsManualInput
                  ? (_enteredValue != null ? _confirm : null)
                  : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}