import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/cards/app_card.dart';
import '../domain/allergen.dart';
import '../domain/dependent_age.dart';
import '../domain/dependent_summary.dart';
import '../domain/diet_type.dart';
import 'allergen_label.dart';
import 'diet_type_label.dart';

/// Dòng ngày sinh (§16.11 MEDIUM-4): tuổi tính được → `dependentAgeAndBirth`;
/// ngày tương lai (OD-18) → `dependentBornOn`; `null` → `null` (caller tự quyết
/// hiện `dependentDobNotSet` hay không).
String? dependentBirthText(BuildContext context, DateTime? dob) {
  if (dob == null) return null;
  final l10n = context.l10n;
  final date =
      DateFormat.yMd(Localizations.localeOf(context).toString()).format(dob);
  final age = ageOn(dob, DateTime.now());
  return age < 0
      ? l10n.dependentBornOn(date)
      : l10n.dependentAgeAndBirth(age, date);
}

/// Chữ cái đầu của tối đa 2 từ đầu — avatar placeholder (BE không trả avatar).
String dependentInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  return words
      .take(2)
      .map((String w) => w.characters.first.toUpperCase())
      .join();
}

class DependentAvatar extends StatelessWidget {
  const DependentAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.sageLight,
        shape: BoxShape.circle,
      ),
      child: Text(
        dependentInitials(name),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.sageDark,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Chip nhỏ dùng chung cho row/summary. [muted] = chip mờ (chưa thiết lập /
/// chưa ghi nhận).
class DependentChip extends StatelessWidget {
  const DependentChip({
    super.key,
    required this.label,
    this.muted = false,
    this.warning = false,
    this.icon,
  });

  final String label;
  final bool muted;
  final bool warning;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color fg = warning
        ? AppColors.error
        : (muted ? AppColors.textDisabled : AppColors.textSecondary);
    final Color bg = warning
        ? AppColors.error.withValues(alpha: 0.1)
        : (muted ? AppColors.surfaceSubtle : AppColors.secondaryFill);
    final iconData = icon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (iconData != null) ...<Widget>[
            Icon(iconData, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge "Cần đổi giám hộ" (§16.3) cho `guardianActive:false`.
class GuardianInactiveTag extends StatelessWidget {
  const GuardianInactiveTag({super.key});

  @override
  Widget build(BuildContext context) => DependentChip(
        label: context.l10n.dependentGuardianInactiveTag,
        icon: Icons.warning_amber_rounded,
        warning: true,
      );
}

/// Chip chế độ ăn (§16.10): `null` → chip mờ "Chưa chọn chế độ ăn"; `NONE` →
/// không chip ([showNone] = false, list) hoặc nhãn "Không chọn…" (detail).
Widget? dependentDietChip(AppLocalizations l10n, DietType? diet,
    {bool showNone = false}) {
  if (diet == null) {
    return DependentChip(
      key: const ValueKey<String>('dependent-diet-unset'),
      label: l10n.healthProfileDietUnset,
      muted: true,
    );
  }
  if (diet == DietType.none && !showNone) return null;
  return DependentChip(label: diet.label(l10n));
}

/// Chip dị ứng: tối đa [max] chip + "+N"; rỗng → chip mờ "Chưa ghi nhận dị
/// ứng" — KHÔNG BAO GIỜ ẩn khối dị ứng (§16.10 MEDIUM-1, an toàn dị ứng).
List<Widget> dependentAllergenChips(
  AppLocalizations l10n,
  List<Allergen> allergens, {
  int? max,
}) {
  if (allergens.isEmpty) {
    return <Widget>[
      DependentChip(
        key: const ValueKey<String>('dependent-no-allergens'),
        label: l10n.dependentNoAllergens,
        muted: true,
      ),
    ];
  }
  final shown = max == null ? allergens : allergens.take(max).toList();
  return <Widget>[
    for (final a in shown)
      DependentChip(
        label: l10n.dependentAllergenChip(a.label(l10n)),
        icon: Icons.warning_amber_rounded,
        warning: true,
      ),
    if (shown.length < allergens.length)
      DependentChip(
          label: l10n.dependentMoreChip(allergens.length - shown.length)),
  ];
}

/// Một dòng trong DependentListScreen (§9.1): avatar initials, tên, tuổi,
/// chip diet/dị ứng, badge `!guardianActive`.
class DependentRow extends StatelessWidget {
  const DependentRow({super.key, required this.dependent, this.onTap});

  final DependentSummary dependent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = dependent;
    final birth = dependentBirthText(context, d.dateOfBirth);
    final diet = dependentDietChip(l10n, d.dietType);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.sm),
      child: AppCard(
        key: ValueKey<String>('dependent-row-${d.id}'),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DependentAvatar(name: d.displayName),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    d.displayName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (birth != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(birth,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: AppDimens.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      if (!d.guardianActive)
                        GuardianInactiveTag(
                            key: ValueKey<String>(
                                'dependent-inactive-tag-${d.id}')),
                      if (diet != null) diet,
                      ...dependentAllergenChips(l10n, d.allergens, max: 2),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
