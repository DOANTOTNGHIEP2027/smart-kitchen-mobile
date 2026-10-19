import 'package:flutter/material.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/buttons/app_button.dart';
import '../domain/meal_slot_template_item.dart';

/// Loại bữa có sẵn — `slotKey` khớp DEFAULT_SLOTS của BE; `custom` sinh key
/// `CUSTOM_<n>` ở store.
enum SlotPreset { breakfast, lunch, dinner, snack, custom }

extension SlotPresetX on SlotPreset {
  String? get slotKey => switch (this) {
        SlotPreset.breakfast => 'BREAKFAST',
        SlotPreset.lunch => 'LUNCH',
        SlotPreset.dinner => 'DINNER',
        SlotPreset.snack => 'SNACK',
        SlotPreset.custom => null,
      };

  static SlotPreset fromKey(String key) => SlotPreset.values.firstWhere(
        (SlotPreset p) => p.slotKey == key,
        orElse: () => SlotPreset.custom,
      );
}

/// Kết quả form — `slotKey == null` nghĩa là bữa tự đặt tên, caller tự cấp key.
class SlotFormResult {
  const SlotFormResult({
    required this.slotKey,
    required this.label,
    required this.hour,
    required this.minute,
  });

  final String? slotKey;
  final String label;
  final int hour;
  final int minute;
}

String slotPresetLabel(BuildContext context, SlotPreset preset) {
  final l10n = context.l10n;
  return switch (preset) {
    SlotPreset.breakfast => l10n.planningSlotTypeBreakfast,
    SlotPreset.lunch => l10n.planningSlotTypeLunch,
    SlotPreset.dinner => l10n.planningSlotTypeDinner,
    SlotPreset.snack => l10n.planningSlotTypeSnack,
    SlotPreset.custom => l10n.planningSlotTypeCustom,
  };
}

Future<SlotFormResult?> showSlotFormSheet(
  BuildContext context, {
  MealSlotTemplateItem? initial,
}) {
  return showModalBottomSheet<SlotFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SlotFormSheet(initial: initial),
  );
}

class SlotFormSheet extends StatefulWidget {
  const SlotFormSheet({super.key, this.initial});

  final MealSlotTemplateItem? initial;

  @override
  State<SlotFormSheet> createState() => _SlotFormSheetState();
}

class _SlotFormSheetState extends State<SlotFormSheet> {
  late SlotPreset _preset;
  late final TextEditingController _label;
  late TimeOfDay _time;
  bool _labelSeeded = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _preset =
        initial == null ? SlotPreset.breakfast : SlotPresetX.fromKey(initial.slotKey);
    _label = TextEditingController(text: initial?.label ?? '');
    _time = initial == null
        ? const TimeOfDay(hour: 7, minute: 0)
        : TimeOfDay(hour: initial.hour, minute: initial.minute);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed 1 lần — didChangeDependencies chạy lại mỗi khi viewInsets đổi
    // (bàn phím), không được ghi đè ô tên user vừa xoá.
    if (!_labelSeeded && widget.initial == null) {
      _label.text = slotPresetLabel(context, _preset);
    }
    _labelSeeded = true;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    Navigator.of(context).pop(SlotFormResult(
      // Sửa bữa custom giữ nguyên key cũ để BE match đúng row (D-SLOT-REPLACE).
      slotKey: _preset == SlotPreset.custom
          ? (widget.initial != null &&
                  SlotPresetX.fromKey(widget.initial!.slotKey) ==
                      SlotPreset.custom
              ? widget.initial!.slotKey
              : null)
          : _preset.slotKey,
      label: _label.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timeText = MealSlotTemplateItem.formatTime(_time.hour, _time.minute);
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.md,
        right: AppDimens.md,
        top: AppDimens.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.initial == null
                  ? l10n.planningSlotFormAddTitle
                  : l10n.planningSlotFormEditTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.md),
            DropdownButtonFormField<SlotPreset>(
              key: const ValueKey<String>('slot-form-type'),
              initialValue: _preset,
              decoration: InputDecoration(labelText: l10n.planningSlotFormType),
              items: <DropdownMenuItem<SlotPreset>>[
                for (final p in SlotPreset.values)
                  DropdownMenuItem<SlotPreset>(
                    value: p,
                    child: Text(slotPresetLabel(context, p)),
                  ),
              ],
              onChanged: (SlotPreset? p) {
                if (p == null) return;
                setState(() {
                  _preset = p;
                  if (p != SlotPreset.custom) {
                    _label.text = slotPresetLabel(context, p);
                  }
                });
              },
            ),
            const SizedBox(height: AppDimens.sm),
            TextField(
              key: const ValueKey<String>('slot-form-label'),
              controller: _label,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.planningSlotFormLabel),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(l10n.planningSlotFormTime),
              trailing: Text(timeText),
              onTap: _pickTime,
            ),
            const SizedBox(height: AppDimens.sm),
            AppButton(
              key: const ValueKey<String>('slot-form-submit'),
              label: l10n.planningConfirm,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
