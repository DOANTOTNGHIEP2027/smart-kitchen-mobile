import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
import '../../../utils/api_error_l10n.dart';
import '../../../utils/l10n_x.dart';
import '../data/meal_attendance_api.dart';
import '../domain/meal_attendance.dart';
import '../stores/meal_attendance_store.dart';

class MealAttendancePanel extends StatefulWidget {
  const MealAttendancePanel(
      {super.key, required this.planId, required this.slotId});
  final String planId, slotId;
  @override
  State<MealAttendancePanel> createState() => _MealAttendancePanelState();
}

class _MealAttendancePanelState extends State<MealAttendancePanel>
    with WidgetsBindingObserver {
  late final MealAttendanceStore store;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store = MealAttendanceStore(
        Get.find<MealAttendanceApi>(), widget.planId, widget.slotId);
    store.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    store.dispose();
    super.dispose();
  }

  String label(BuildContext context, AttendanceStatus status) =>
      switch (status) {
        AttendanceStatus.attending => context.l10n.attendanceYes,
        AttendanceStatus.notAttending => context.l10n.attendanceNo,
        AttendanceStatus.unknown => context.l10n.attendanceUnknown
      };

  /// Nhãn trên nút chọn — "Chưa rõ" (bấm = xoá phản hồi).
  String segmentLabel(BuildContext context, AttendanceStatus status) =>
      status == AttendanceStatus.unknown
          ? context.l10n.attendanceUnsure
          : label(context, status);

  String? errorText(BuildContext context) {
    final error = store.error;
    if (error == null) return null;
    if (store.isClosedError) {
      // Đã có dòng khoá "không đổi được" bên dưới thì không lặp lại.
      return store.value?.editable == false
          ? null
          : context.l10n.attendanceClosed;
    }
    if (store.value == null) return context.l10n.attendanceLoadFailed;
    return apiErrorMessage(context.l10n, error,
        fallback: context.l10n.attendanceSaveFailed);
  }

  @override
  Widget build(BuildContext context) => Observer(builder: (_) {
        final data = store.value;
        final theme = Theme.of(context);
        final err = errorText(context);
        return Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(context.l10n.attendanceTitle,
                                style: theme.textTheme.titleMedium)),
                        IconButton(
                            onPressed: store.saving || store.loading
                                ? null
                                : store.load,
                            icon: const Icon(Icons.refresh),
                            tooltip: context.l10n.refresh)
                      ]),
                      if (store.loading || store.saving)
                        const LinearProgressIndicator(),
                      if (err != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(err,
                              key: const ValueKey<String>('attendance-error'),
                              style:
                                  TextStyle(color: theme.colorScheme.error)),
                        ),
                      if (data != null) ...[
                        Text(context.l10n.attendanceSummary(
                            data.attendingCount, data.unknownCount)),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n
                              .attendanceYou(label(context, data.myStatus)),
                          key: const ValueKey<String>('attendance-my-status'),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        // #201: 3 trạng thái rõ ràng, đổi được bất cứ lúc
                        // nào khi bữa còn mở; "Chưa rõ" = xoá phản hồi.
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<AttendanceStatus>(
                            key: const ValueKey<String>('attendance-segments'),
                            showSelectedIcon: false,
                            segments: [
                              for (final status in AttendanceStatus.values)
                                ButtonSegment<AttendanceStatus>(
                                  value: status,
                                  label: Text(
                                    segmentLabel(context, status),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            selected: <AttendanceStatus>{data.myStatus},
                            onSelectionChanged: !data.editable || store.saving
                                ? null
                                : (selection) {
                                    if (selection.isEmpty) return;
                                    store.update(selection.first);
                                  },
                          ),
                        ),
                        if (!data.editable)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    context.l10n.attendanceClosed,
                                    key: const ValueKey<String>(
                                        'attendance-closed'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        for (final member in data.members)
                          ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                  (member.fullName?.trim().isNotEmpty ?? false)
                                      ? member.fullName!.trim()
                                      : context.l10n.attendanceMember),
                              trailing: Text(label(context, member.status))),
                      ],
                    ])));
      });
}
