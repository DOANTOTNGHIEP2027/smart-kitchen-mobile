import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../domain/shared/budget_period.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feature_banner.dart';
import '../stores/family_store.dart';
import '../stores/form_status.dart';

/// Đặt/sửa ngân sách household (tier-gate-screens.md §19.4, §19.7). Chỉ mở từ
/// P3/P4 (đã biết giá trị hiện tại). Không có ô currency (Guard #15).
class HouseholdBudgetSheet extends StatefulWidget {
  const HouseholdBudgetSheet({super.key, required this.store});

  final FamilyStore store;

  /// Đọc số tiền VND người dùng gõ (Guard #16): chấp nhận số thuần
  /// (`1500000`) hoặc có dấu phân cách nghìn ĐÚNG nhóm 3 (`1.500.000`,
  /// `1,500,000`), bỏ hậu tố `₫`/`đ`/`VND`. Mọi dạng khác — đặc biệt có phần
  /// thập phân như `1500000.50` — trả `null` để báo lỗi inline, KHÔNG được
  /// strip dấu rồi gửi lên số gấp 10/100 lần.
  static double? parseAmount(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'(vnd|₫|đ)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s'), '');
    final String digits;
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      digits = cleaned;
    } else if (RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(cleaned)) {
      digits = cleaned.replaceAll(RegExp(r'[.,]'), '');
    } else {
      return null;
    }
    // NUMERIC(14,2) của BE → tối đa 12 chữ số phần nguyên.
    if (digits.length > 12) return null;
    final value = double.parse(digits);
    return value <= 0 ? null : value;
  }

  @override
  State<HouseholdBudgetSheet> createState() => _HouseholdBudgetSheetState();
}

class _HouseholdBudgetSheetState extends State<HouseholdBudgetSheet> {
  late final FamilyStore _store = widget.store;
  late BudgetPeriod _period;
  late final TextEditingController _amount;
  bool _showAmountError = false;

  @override
  void initState() {
    super.initState();
    final b = _store.budget;
    _period = b != null && b.isSet && b.period != BudgetPeriod.unknown
        ? b.period
        : BudgetPeriod.weekly;
    _amount = TextEditingController(
        text: b?.amount == null ? '' : b!.amount!.round().toString());
  }

  @override
  void dispose() {
    _amount.dispose();
    _store.clearBudgetMutationStatus();
    super.dispose();
  }

  bool get _unchanged {
    final b = _store.budget;
    if (b == null || !b.isSet) return false;
    return b.period == _period &&
        // Ô nhập điền sẵn số đã làm tròn về đồng — so cùng đơn vị.
        HouseholdBudgetSheet.parseAmount(_amount.text) ==
            b.amount!.roundToDouble();
  }

  Future<void> _save() async {
    final amount = HouseholdBudgetSheet.parseAmount(_amount.text);
    if (amount == null) {
      setState(() => _showAmountError = true);
      return;
    }
    final ok = await _store.upsertBudget(_period, amount);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.budgetUpdated;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Observer(builder: (_) {
      final submitting = _store.isSubmittingBudget;
      final error = _store.budgetMutationStatus == FormStatus.failure
          ? _store.budgetMutationError
          : null;
      return PopScope(
        canPop: !submitting,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppDimens.md,
            right: AppDimens.md,
            top: AppDimens.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l10n.budgetSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppDimens.md),
              SegmentedButton<BudgetPeriod>(
                key: const ValueKey<String>('budget-period'),
                segments: <ButtonSegment<BudgetPeriod>>[
                  ButtonSegment<BudgetPeriod>(
                      value: BudgetPeriod.weekly,
                      label: Text(l10n.budgetPeriodWeek)),
                  ButtonSegment<BudgetPeriod>(
                      value: BudgetPeriod.monthly,
                      label: Text(l10n.budgetPeriodMonth)),
                ],
                selected: <BudgetPeriod>{_period},
                onSelectionChanged: submitting
                    ? null
                    : (s) => setState(() => _period = s.first),
              ),
              const SizedBox(height: AppDimens.md),
              TextField(
                key: const ValueKey<String>('budget-amount'),
                controller: _amount,
                enabled: !submitting,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.budgetAmountLabel,
                  errorText: _showAmountError ? l10n.budgetAmountInvalid : null,
                  // Chip tĩnh — không cho nhập currency (Guard #15).
                  suffix: Container(
                    key: const ValueKey<String>('budget-currency'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sageLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: const Text('VND',
                        style: TextStyle(
                            color: AppColors.sageDark,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                onChanged: (_) => setState(() => _showAmountError = false),
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                l10n.budgetNotRetroactive,
                key: const ValueKey<String>('budget-not-retroactive'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (error != null) ...<Widget>[
                const SizedBox(height: AppDimens.sm),
                FeatureBanner(
                  key: const ValueKey<String>('budget-save-error'),
                  message: error.code == 'ERR_HH_004'
                      ? l10n.budgetOwnerOnlyTooltip
                      : error.message,
                ),
              ],
              const SizedBox(height: AppDimens.md),
              AppButton(
                key: const ValueKey<String>('budget-save'),
                label: l10n.budgetSave,
                isLoading: submitting,
                // Rỗng hoặc không đổi gì → không cho gửi.
                onPressed:
                    _amount.text.trim().isEmpty || _unchanged ? null : _save,
              ),
            ],
          ),
        ),
      );
    });
  }
}
