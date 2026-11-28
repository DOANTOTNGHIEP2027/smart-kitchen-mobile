import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/network/api_exception.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../../../widgets/feedback/app_toast.dart';
import '../data/meal_attendance_api.dart';
import '../data/meal_plan_api.dart';
import '../domain/meal_attendance.dart';
import '../domain/meal_plan_slot.dart';
import '../scenes/weekly_meal_plan_scene.dart' show mealSlotLabel;
import '../stores/meal_plan_store.dart';

/// Mở popup vote tham gia các bữa của [date] (thông báo batch 20:00).
Future<void> showDailyAttendanceSheet(
  BuildContext context, {
  required String planId,
  required DateTime date,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => DailyAttendanceSheet(planId: planId, date: date),
);

/// Vote Có/Không cho từng bữa của một ngày rồi Lưu một lượt.
///
/// Chưa vote hiển thị "Có ăn (mặc định)" — BE tính chưa vote là có ăn. Chỉ gửi
/// những bữa người dùng đổi so với lúc mở. Từ 00:00 ngày của bữa BE trả
/// `editable=false` / 409 `ERR_PLAN_ATTENDANCE_CLOSED` → popup chỉ xem.
class DailyAttendanceSheet extends StatefulWidget {
  const DailyAttendanceSheet({
    super.key,
    required this.planId,
    required this.date,
  });

  final String planId;
  final DateTime date;

  @override
  State<DailyAttendanceSheet> createState() => _DailyAttendanceSheetState();
}

class _DailyAttendanceSheetState extends State<DailyAttendanceSheet> {
  late final MealAttendanceApi _attendanceApi = Get.find<MealAttendanceApi>();
  late final MealPlanApi _planApi = Get.find<MealPlanApi>();

  List<MealPlanSlot> _meals = const <MealPlanSlot>[];
  final Map<String, AttendanceStatus> _initial = <String, AttendanceStatus>{};
  final Map<String, AttendanceStatus> _choices = <String, AttendanceStatus>{};
  bool _editable = false;
  bool _loading = true;
  bool _saving = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await _planApi.getById(widget.planId);
      final attendance = await _attendanceApi.list(widget.planId);
      final bySlot = {for (final a in attendance) a.slotId: a};
      final meals =
          plan.slots
              .where(
                (s) =>
                    _sameDay(s.slotDate, widget.date) &&
                    s.scheduledTime != null &&
                    bySlot.containsKey(s.id),
              )
              .toList()
            ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
      if (!mounted) return;
      setState(() {
        _meals = meals;
        _initial
          ..clear()
          ..addAll({for (final m in meals) m.id: bySlot[m.id]!.myStatus});
        _choices
          ..clear()
          ..addAll(_initial);
        _editable = meals.any((m) => bySlot[m.id]!.editable);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, AttendanceStatus> get _changed => {
    for (final entry in _choices.entries)
      if (_initial[entry.key] != entry.value) entry.key: entry.value,
  };

  Future<void> _save() async {
    final changed = _changed;
    if (changed.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _attendanceApi.updateMine(widget.planId, changed);
      if (Get.isRegistered<MealPlanStore>()) {
        unawaited(Get.find<MealPlanStore>().refreshAttendance());
      }
      if (!mounted) return;
      AppToast.show(context.l10n.attendanceInviteSaved);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        if (e.code == 'ERR_PLAN_ATTENDANCE_CLOSED') _editable = false;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final error = _error;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.attendanceInviteTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.attendanceInviteHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  error.code == 'ERR_PLAN_ATTENDANCE_CLOSED'
                      ? l10n.attendanceInviteClosed
                      : apiErrorMessage(
                          l10n,
                          error,
                          fallback: _meals.isEmpty
                              ? l10n.attendanceLoadFailed
                              : l10n.attendanceSaveFailed,
                        ),
                  key: const ValueKey<String>('daily-attendance-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (!_loading && error == null && _meals.isEmpty)
              Text(l10n.attendanceInviteEmpty),
            for (final meal in _meals) _mealRow(context, meal),
            if (!_loading && _meals.isNotEmpty && !_editable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.attendanceInviteClosed,
                  key: const ValueKey<String>('daily-attendance-closed'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey<String>('daily-attendance-save'),
              onPressed: _loading || _saving || !_editable || _meals.isEmpty
                  ? null
                  : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.attendanceInviteSave),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealRow(BuildContext context, MealPlanSlot meal) {
    final l10n = context.l10n;
    final status = _choices[meal.id] ?? AttendanceStatus.unknown;
    final attending = status != AttendanceStatus.notAttending;
    final time = meal.scheduledTime ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${mealSlotLabel(context, meal)} · ${time.length >= 5 ? time.substring(0, 5) : time}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              key: ValueKey<String>('daily-attendance-${meal.id}'),
              showSelectedIcon: false,
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: true,
                  label: Text(
                    status == AttendanceStatus.unknown
                        ? l10n.attendanceDefaultYes
                        : l10n.attendanceYes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text(
                    l10n.attendanceNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: <bool>{attending},
              onSelectionChanged: !_editable || _saving
                  ? null
                  : (selection) {
                      if (selection.isEmpty) return;
                      setState(
                        () => _choices[meal.id] = selection.first
                            ? AttendanceStatus.attending
                            : AttendanceStatus.notAttending,
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}
