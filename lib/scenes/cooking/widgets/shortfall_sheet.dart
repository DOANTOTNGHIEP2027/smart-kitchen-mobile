import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../utils/quantity_format.dart';
import '../../../widgets/buttons/app_button.dart';
import '../domain/missing_ingredient.dart';
import '../../../utils/unit_label.dart';

/// Kết quả người dùng chọn trên [ShortfallSheet]. `null` (vuốt/back đóng
/// sheet) được xử lý như [back].
enum ShortfallChoice { completeAnyway, back }

/// Mở sheet "Kho không đủ nguyên liệu" sau 409
/// `ERR_INSUFFICIENT_STOCK_FOR_RECIPE` (OD-36). Kho CHƯA bị trừ gì.
///
/// Sheet chỉ trả lựa chọn qua `pop` — người gọi xử lý store SAU khi sheet đã
/// đóng. [onSheetContext] trao context của sheet để người gọi tự đóng nó khi
/// store không còn `shortfall` (vd. session kết thúc ở máy khác).
Future<ShortfallChoice?> showShortfallSheet(
  BuildContext context, {
  required List<MissingIngredient> missing,
  void Function(BuildContext sheetContext)? onSheetContext,
}) {
  return showModalBottomSheet<ShortfallChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      onSheetContext?.call(sheetContext);
      return ShortfallSheet(missing: missing);
    },
  );
}

class ShortfallSheet extends StatelessWidget {
  const ShortfallSheet({super.key, required this.missing});

  final List<MissingIngredient> missing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.lg, 0, AppDimens.lg, AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning),
                const SizedBox(width: AppDimens.sm),
                Expanded(
                  child: Text(l10n.cookingShortfallTitle,
                      style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.sm),
            Text(
              l10n.cookingShortfallMessage,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimens.md),
            Flexible(
              child: missing.isEmpty
                  ? Text(l10n.cookingShortfallNoDetail,
                      style: theme.textTheme.bodyMedium)
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: missing.length,
                      itemBuilder: (_, i) =>
                          _MissingRow(ingredient: missing[i]),
                    ),
            ),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              label: l10n.cookingShortfallConfirm,
              icon: Icons.check_circle_outline,
              onPressed: () =>
                  Navigator.of(context).pop(ShortfallChoice.completeAnyway),
            ),
            const SizedBox(height: AppDimens.sm),
            AppButton(
              label: l10n.cookingShortfallBack,
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(ShortfallChoice.back),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingRow extends StatelessWidget {
  const _MissingRow({required this.ingredient});

  final MissingIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Đọc cả dòng một lần cho trình đọc màn hình; "Thiếu" có chữ, không chỉ
    // dựa vào màu.
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(ingredient.ingredientName,
                style: theme.textTheme.titleMedium),
            Text(
              context.l10n.cookingShortfallLine(
                formatQuantity(ingredient.requiredQuantity),
                formatQuantity(ingredient.availableQuantity),
                formatQuantity(ingredient.shortfallQuantity),
                unitLabel(context, ingredient.unit),
              ),
              style:
                  theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
