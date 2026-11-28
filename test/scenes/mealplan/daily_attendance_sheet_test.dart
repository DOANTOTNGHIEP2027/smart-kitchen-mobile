import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_attendance_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_plan_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_attendance.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_plan_slot.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/widgets/daily_attendance_sheet.dart';

import '../../helpers/pump_app.dart';

class _MockMealPlanApi extends Mock implements MealPlanApi {}

class _MockAttendanceApi extends Mock implements MealAttendanceApi {}

final DateTime _day = DateTime(2026, 11, 29);

MealPlanSlot _slot(String id, String mealTime, String time, {DateTime? date}) =>
    MealPlanSlot(
      id: id,
      slotDate: date ?? _day,
      mealTime: mealTime,
      dishes: const <MealPlanDish>[],
      scheduledTime: time,
    );

MealAttendance _attendance(String slotId,
        {AttendanceStatus status = AttendanceStatus.unknown,
        bool editable = true}) =>
    MealAttendance(
      slotId: slotId,
      members: const <AttendanceMember>[],
      attendingCount: 0,
      notAttendingCount: 0,
      unknownCount: 1,
      myStatus: status,
      editable: editable,
    );

/// Popup vote 20:00: chỉ bữa của ngày được mời, chưa vote hiện "mặc định có
/// ăn", Lưu chỉ gửi bữa đã đổi, đã chốt thì chỉ xem.
void main() {
  late _MockMealPlanApi planApi;
  late _MockAttendanceApi attendanceApi;

  setUpAll(() => registerFallbackValue(<String, AttendanceStatus>{}));

  setUp(() {
    planApi = _MockMealPlanApi();
    attendanceApi = _MockAttendanceApi();
    Get.put<MealPlanApi>(planApi);
    Get.put<MealAttendanceApi>(attendanceApi);
    when(() => planApi.getById('p')).thenAnswer((_) async => MealPlanDto(
          id: 'p',
          householdId: 'h',
          weekStart: DateTime(2026, 11, 23),
          slots: <MealPlanSlot>[
            _slot('other-day', 'LUNCH', '12:00:00',
                date: DateTime(2026, 11, 28)),
            _slot('b', 'BREAKFAST', '07:00:00'),
            _slot('d', 'DINNER', '18:00:00'),
          ],
        ));
  });

  tearDown(Get.reset);

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpAppWidget(DailyAttendanceSheet(planId: 'p', date: _day));
    await tester.pumpAndSettle();
  }

  testWidgets('chưa vote hiện mặc định có ăn; Lưu chỉ gửi bữa đã đổi',
      (tester) async {
    when(() => attendanceApi.list('p'))
        .thenAnswer((_) async => <MealAttendance>[
              _attendance('other-day'),
              _attendance('b'),
              _attendance('d', status: AttendanceStatus.attending),
            ]);
    when(() => attendanceApi.updateMine('p', any()))
        .thenAnswer((_) async => <MealAttendance>[]);
    await pumpSheet(tester);

    expect(find.byKey(const ValueKey<String>('daily-attendance-b')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('daily-attendance-d')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('daily-attendance-other-day')),
        findsNothing);
    expect(find.text('Có ăn (mặc định)'), findsOneWidget);

    await tester.tap(find.descendant(
        of: find.byKey(const ValueKey<String>('daily-attendance-b')),
        matching: find.text('Không ăn')));
    await tester.pump();
    await tester
        .tap(find.byKey(const ValueKey<String>('daily-attendance-save')));
    await tester.pumpAndSettle();

    final sent = verify(() => attendanceApi.updateMine('p', captureAny()))
        .captured
        .single as Map<String, AttendanceStatus>;
    expect(
        sent, <String, AttendanceStatus>{'b': AttendanceStatus.notAttending});
  });

  testWidgets('đã chốt (editable=false) → chỉ xem, nút Lưu tắt',
      (tester) async {
    when(() => attendanceApi.list('p'))
        .thenAnswer((_) async => <MealAttendance>[
              _attendance('b', editable: false),
              _attendance('d', editable: false),
            ]);
    await pumpSheet(tester);

    expect(find.byKey(const ValueKey<String>('daily-attendance-closed')),
        findsOneWidget);
    final save = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('daily-attendance-save')));
    expect(save.onPressed, isNull);
  });

  testWidgets('BE trả 409 lúc lưu → báo đã chốt và khoá popup', (tester) async {
    when(() => attendanceApi.list('p'))
        .thenAnswer((_) async => <MealAttendance>[
              _attendance('b'),
              _attendance('d'),
            ]);
    when(() => attendanceApi.updateMine('p', any()))
        .thenThrow(BusinessException('ERR_PLAN_ATTENDANCE_CLOSED', 'closed'));
    await pumpSheet(tester);

    await tester.tap(find.descendant(
        of: find.byKey(const ValueKey<String>('daily-attendance-d')),
        matching: find.text('Không ăn')));
    await tester.pump();
    await tester
        .tap(find.byKey(const ValueKey<String>('daily-attendance-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('daily-attendance-error')),
        findsOneWidget);
    final save = tester.widget<FilledButton>(
        find.byKey(const ValueKey<String>('daily-attendance-save')));
    expect(save.onPressed, isNull);
  });
}
