import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_dimens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/states/app_error_view.dart';
import '../../../widgets/states/app_loading_view.dart';
import '../../../widgets/states/view_state.dart';
import '../../profile/stores/form_status.dart';
import '../domain/meal_slot_template_item.dart';
import '../stores/meal_slot_store.dart';
import '../widgets/planning_banner.dart';
import '../widgets/slot_form_sheet.dart';

/// Household tự định nghĩa khung bữa trong ngày (flexible-meal-planning-screens.md
/// §8.1). Sửa trên bản nháp, chỉ gọi API khi bấm "Lưu".
class MealSlotConfigScene extends StatefulWidget {
  const MealSlotConfigScene({super.key});

  @override
  State<MealSlotConfigScene> createState() => _MealSlotConfigSceneState();
}

class _MealSlotConfigSceneState extends State<MealSlotConfigScene> {
  late final MealSlotStore _store;
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _store = Get.find<MealSlotStore>();
    _store.load();
  }

  Future<void> _addSlot(int? dayOfWeek) async {
    final result = await showSlotFormSheet(context);
    if (result == null) return;
    _store.addSlot(MealSlotTemplateItem(
      dayOfWeek: dayOfWeek,
      slotKey: result.slotKey ?? _store.nextCustomKey(dayOfWeek),
      label: result.label,
      hour: result.hour,
      minute: result.minute,
      sortOrder: 0,
    ));
  }

  Future<void> _editSlot(MealSlotTemplateItem slot) async {
    final result = await showSlotFormSheet(context, initial: slot);
    if (result == null) return;
    _store.replaceSlot(
      slot,
      slot.copyWith(
        slotKey: result.slotKey ?? _store.nextCustomKey(slot.dayOfWeek),
        label: result.label,
        hour: result.hour,
        minute: result.minute,
      ),
    );
  }

  Future<void> _save() async {
    final ok = await _store.save();
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.planningSlotSaved)),
    );
    _store.clearSaveStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.planningSlotConfigTitle,
      body: Observer(builder: (_) {
        final state = _store.templateState;
        return switch (state) {
          LoadingState<List<MealSlotTemplateItem>>() ||
          EmptyState<List<MealSlotTemplateItem>>() =>
            const AppLoadingView(),
          ErrorState<List<MealSlotTemplateItem>>(:final error) => AppErrorView(
              message: error.message,
              onRetry: _store.load,
            ),
          SuccessState<List<MealSlotTemplateItem>>() => _buildEditor(l10n),
        };
      }),
    );
  }

  Widget _buildEditor(AppLocalizations l10n) {
    final saving = _store.isSaving;
    final draftError = _store.draftError;
    final saveFailed = _store.saveStatus == FormStatus.failure;
    return ListView(
      padding: const EdgeInsets.all(AppDimens.md),
      children: <Widget>[
        if (_store.isUsingDefaults)
          PlanningBanner(
            key: const ValueKey<String>('slot-default-banner'),
            text: l10n.planningSlotDefaultBanner,
            color: AppColors.sageLight,
          ),
        if (draftError != null)
          PlanningBanner(
            key: const ValueKey<String>('slot-draft-error'),
            text: _draftErrorText(l10n, draftError),
            color: AppColors.primaryLight,
            textColor: AppColors.error,
          ),
        if (saveFailed)
          PlanningBanner(
            key: const ValueKey<String>('slot-save-error'),
            text: _store.saveError?.message ?? l10n.planningSlotSaveFailed,
            color: AppColors.primaryLight,
            textColor: AppColors.error,
          ),
        _SectionTitle(l10n.planningSlotEveryDay),
        ..._store.draftEveryDay.map((s) => _slotRow(s, saving)),
        _AddButton(
          key: const ValueKey<String>('slot-add-every-day'),
          label: l10n.planningSlotAdd,
          onPressed: saving ? null : () => _addSlot(null),
        ),
        const SizedBox(height: AppDimens.lg),
        _SectionTitle(l10n.planningSlotByDay),
        Text(
          l10n.planningSlotByDayHint,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimens.sm),
        Wrap(
          spacing: AppDimens.xs,
          children: <Widget>[
            for (var day = 0; day < 7; day++)
              ChoiceChip(
                key: ValueKey<String>('slot-day-$day'),
                label: Text(_weekdayLabel(l10n, day)),
                selected: _selectedDay == day,
                onSelected: (_) => setState(() => _selectedDay = day),
              ),
          ],
        ),
        const SizedBox(height: AppDimens.sm),
        ..._dayRows(l10n, saving),
        _AddButton(
          key: const ValueKey<String>('slot-add-day'),
          label: l10n.planningSlotAdd,
          onPressed: saving ? null : () => _addSlot(_selectedDay),
        ),
        const SizedBox(height: AppDimens.lg),
        PlanningBanner(
          text: l10n.planningSlotNotRetroactive,
          color: AppColors.secondaryFill,
        ),
        const SizedBox(height: AppDimens.md),
        AppButton(
          key: const ValueKey<String>('slot-save'),
          label: l10n.planningSlotSave,
          isLoading: saving,
          onPressed: _save,
        ),
      ],
    );
  }

  List<Widget> _dayRows(AppLocalizations l10n, bool saving) {
    final rows = _store.slotsOfDay(_selectedDay);
    if (rows.isEmpty) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
          child: Text(
            l10n.planningSlotEmptyDay,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ];
    }
    return rows.map((s) => _slotRow(s, saving)).toList();
  }

  Widget _slotRow(MealSlotTemplateItem slot, bool saving) {
    final l10n = context.l10n;
    return ListTile(
      key: ValueKey<String>('slot-row-${slot.dayOfWeek}-${slot.slotKey}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule, color: AppColors.primary),
      title: Text(slot.label),
      subtitle: Text(slot.timeText),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: l10n.planningSlotEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: saving ? null : () => _editSlot(slot),
          ),
          IconButton(
            key: ValueKey<String>(
                'slot-delete-${slot.dayOfWeek}-${slot.slotKey}'),
            tooltip: l10n.planningSlotDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: saving ? null : () => _store.removeSlot(slot),
          ),
        ],
      ),
    );
  }

  static String _draftErrorText(AppLocalizations l10n, MealSlotDraftError e) =>
      switch (e) {
        MealSlotDraftError.empty => l10n.planningSlotErrorEmpty,
        MealSlotDraftError.tooMany => l10n.planningSlotErrorTooMany,
        MealSlotDraftError.duplicateKey => l10n.planningSlotErrorDuplicate,
        MealSlotDraftError.blankLabel => l10n.planningSlotErrorBlankLabel,
      };

  static String _weekdayLabel(AppLocalizations l10n, int day) => switch (day) {
        0 => l10n.mealPlanWeekdayMonday,
        1 => l10n.mealPlanWeekdayTuesday,
        2 => l10n.mealPlanWeekdayWednesday,
        3 => l10n.mealPlanWeekdayThursday,
        4 => l10n.mealPlanWeekdayFriday,
        5 => l10n.mealPlanWeekdaySaturday,
        _ => l10n.mealPlanWeekdaySunday,
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.xs),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _AddButton extends StatelessWidget {
  const _AddButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: Text(label),
        ),
      );
}
