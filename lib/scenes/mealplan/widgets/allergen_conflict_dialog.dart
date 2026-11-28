import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/recipe_check.dart';

/// Cảnh báo dị ứng TRƯỚC khi gán món tay: liệt kê từng người ăn bữa này
/// (thành viên/người phụ thuộc/khách) và chất họ dị ứng có trong công thức.
///
/// `true` = người dùng chọn "Tiếp tục"; Huỷ/back/chạm ngoài = `false`.
Future<bool> showAllergenConflictDialog(
  BuildContext context, {
  required List<RecipeAllergenConflict> conflicts,
  required bool verified,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) =>
        AllergenConflictDialog(conflicts: conflicts, verified: verified),
  );
  return result ?? false;
}

class AllergenConflictDialog extends StatelessWidget {
  const AllergenConflictDialog({
    super.key,
    required this.conflicts,
    required this.verified,
  });

  final List<RecipeAllergenConflict> conflicts;

  /// `false` ⇒ dữ liệu dị ứng của công thức chưa kiểm chứng — ghi chú thêm.
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      key: const ValueKey<String>('allergen-conflict-dialog'),
      icon: const Icon(Icons.dangerous_outlined, color: AppColors.error),
      title: Text(l10n.mealPlanAllergyWarningTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.mealPlanAllergyWarningMessage),
            const SizedBox(height: AppDimens.sm),
            for (final person in conflicts)
              Container(
                margin: const EdgeInsets.only(bottom: AppDimens.xs),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.md, vertical: AppDimens.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Text(
                  l10n.mealPlanAllergyPersonLine(
                    _personName(context, person),
                    person.allergens.map((a) => a.name).join(', '),
                  ),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            if (!verified) ...<Widget>[
              const SizedBox(height: AppDimens.xs),
              Text(
                l10n.mealPlanAllergyUnverifiedNote,
                key: const ValueKey<String>('allergen-conflict-unverified'),
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('allergen-conflict-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('allergen-conflict-continue'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.mealPlanAllergyContinue),
        ),
      ],
    );
  }

  static String _personName(
      BuildContext context, RecipeAllergenConflict person) {
    if (person.name.isNotEmpty) return person.name;
    return switch (person.personType) {
      'GUEST' => context.l10n.mealPlanAllergyGuest,
      _ => context.l10n.mealPlanAllergyMember,
    };
  }
}
