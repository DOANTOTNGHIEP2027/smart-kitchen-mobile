import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get/get.dart';
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
  @override
  Widget build(BuildContext context) => Observer(builder: (_) {
        final data = store.value;
        return Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(context.l10n.attendanceTitle,
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                        IconButton(
                            onPressed: store.saving || store.loading
                                ? null
                                : store.load,
                            icon: const Icon(Icons.refresh),
                            tooltip: context.l10n.refresh)
                      ]),
                      if (store.loading) const LinearProgressIndicator(),
                      if (store.error != null)
                        Text(
                            store.value == null
                                ? context.l10n.attendanceLoadFailed
                                : context.l10n.attendanceSaveFailed,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      if (data != null) ...[
                        Text(context.l10n.attendanceSummary(
                            data.attendingCount, data.unknownCount)),
                        Wrap(spacing: 8, children: [
                          for (final status in [
                            AttendanceStatus.attending,
                            AttendanceStatus.notAttending
                          ])
                            ChoiceChip(
                                label: Text(label(context, status)),
                                selected: data.myStatus == status,
                                onSelected: !data.editable ||
                                        store.saving ||
                                        store.loading
                                    ? null
                                    : (_) => store.update(status))
                        ]),
                        TextButton(
                            onPressed: !data.editable ||
                                    store.saving ||
                                    store.loading
                                ? null
                                : () => store.update(AttendanceStatus.unknown),
                            child: Text(context.l10n.attendanceClear)),
                        if (!data.editable) Text(context.l10n.attendanceClosed),
                        for (final member in data.members)
                          ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(member.fullName ??
                                  context.l10n.attendanceMember),
                              trailing: Text(label(context, member.status))),
                      ],
                    ])));
      });
}
