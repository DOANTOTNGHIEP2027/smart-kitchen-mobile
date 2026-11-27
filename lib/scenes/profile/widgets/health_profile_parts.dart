import 'package:flutter/material.dart';

import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/cards/app_card.dart';
import '../domain/allergen.dart';
import '../domain/calorie_suggestion.dart';
import 'allergen_label.dart';

/// #201: phần dùng chung giữa hồ sơ sức khoẻ của tôi và của người phụ thuộc.

String genderLabel(AppLocalizations l, Gender g) => switch (g) {
      Gender.male => l.healthProfileGenderMale,
      Gender.female => l.healthProfileGenderFemale,
    };

String activityLevelLabel(AppLocalizations l, ActivityLevel a) => switch (a) {
      ActivityLevel.sedentary => l.activityLevelSedentary,
      ActivityLevel.light => l.activityLevelLight,
      ActivityLevel.moderate => l.activityLevelModerate,
      ActivityLevel.active => l.activityLevelActive,
      ActivityLevel.veryActive => l.activityLevelVeryActive,
    };

/// `dd/MM/yyyy` để hiển thị.
String formatDisplayDate(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

/// Thẻ "Dị ứng": icon + tiêu đề, chip từng dị ứng hoặc [emptyText], nút sửa.
class AllergensSummaryCard extends StatelessWidget {
  const AllergensSummaryCard({
    super.key,
    required this.allergens,
    required this.onEdit,
    required this.emptyText,
    required this.editKey,
    this.emptyKey,
  });

  final List<Allergen> allergens;
  final VoidCallback? onEdit;

  /// Câu hiển thị khi danh sách rỗng — KHÔNG ẩn khối dị ứng.
  final String emptyText;
  final String editKey;
  final String? emptyKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.health_and_safety_outlined),
              const SizedBox(width: AppDimens.sm),
              Text(l.healthProfileAllergensSection,
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          if (allergens.isEmpty)
            Text(
              emptyText,
              key: emptyKey == null ? null : ValueKey<String>(emptyKey!),
            )
          else
            Wrap(
              spacing: AppDimens.sm,
              runSpacing: AppDimens.xs,
              children: <Widget>[
                for (final a in allergens) Chip(label: Text(a.label(l))),
              ],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey<String>(editKey),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l.healthProfileAllergensEdit),
            ),
          ),
        ],
      ),
    );
  }
}
