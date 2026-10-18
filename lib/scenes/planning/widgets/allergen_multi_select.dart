import 'package:flutter/material.dart';

import '../../../constants/app_dimens.dart';
import '../../profile/domain/allergen.dart';

/// Chọn nhiều allergen từ catalog — widget thuần, không gắn store (thiết kế
/// D4). Chỉ hiển thị allergen có trong [catalog] (I9: không cho chọn ngoài
/// catalog).
class AllergenMultiSelect extends StatelessWidget {
  const AllergenMultiSelect({
    super.key,
    required this.catalog,
    required this.selectedIds,
    required this.onChanged,
    this.enabled = true,
  });

  final List<Allergen> catalog;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimens.sm,
      runSpacing: AppDimens.xs,
      children: <Widget>[
        for (final allergen in catalog)
          FilterChip(
            key: ValueKey<String>('allergen-chip-${allergen.id}'),
            label: Text(allergen.name),
            selected: selectedIds.contains(allergen.id),
            onSelected: enabled
                ? (bool selected) {
                    final next = <int>{...selectedIds};
                    selected ? next.add(allergen.id) : next.remove(allergen.id);
                    onChanged(next);
                  }
                : null,
          ),
      ],
    );
  }
}
