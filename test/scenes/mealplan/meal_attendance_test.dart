import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/data/meal_attendance_api.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/domain/meal_attendance.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/stores/meal_attendance_store.dart';
import 'package:smart_kitchen_mobile/scenes/mealplan/widgets/meal_attendance_panel.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import '../../helpers/pump_app.dart';

Map<String, dynamic> attendanceJson(
        {String status = 'UNKNOWN', bool editable = true}) =>
    {
      'slotId': 's',
      'members': [
        {'userId': 'u', 'fullName': 'An', 'status': status}
      ],
      'attendingCount': status == 'ATTENDING' ? 1 : 0,
      'notAttendingCount': status == 'NOT_ATTENDING' ? 1 : 0,
      'unknownCount': status == 'UNKNOWN' ? 1 : 0,
      'myStatus': status,
      'editable': editable,
    };

class FakeAttendanceApi implements MealAttendanceApi {
  Future<MealAttendance> Function()? onGet;
  Future<MealAttendance> Function(AttendanceStatus)? onUpdate;
  @override
  Future<MealAttendance> get(String pid, String sid) async =>
      onGet == null ? MealAttendance.fromJson(attendanceJson()) : onGet!();
  @override
  Future<MealAttendance> update(
          String pid, String sid, AttendanceStatus s) async =>
      onUpdate!(s);
  @override
  Future<List<MealAttendance>> list(String pid) async => [await get(pid, 's')];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUpAll(storage.install);
  tearDownAll(storage.uninstall);
  tearDown(Get.reset);
  test('UNKNOWN remains unknown; failed save retains persisted value',
      () async {
    final api = FakeAttendanceApi();
    final store = MealAttendanceStore(api, 'p', 's');
    await store.load();
    expect(store.value?.myStatus, AttendanceStatus.unknown);
    api.onUpdate = (_) async =>
        throw BusinessException('ERR_PLAN_ATTENDANCE_CLOSED', 'closed');
    await store.update(AttendanceStatus.attending);
    expect(store.value?.myStatus, AttendanceStatus.unknown);
    expect(store.error?.code, 'ERR_PLAN_ATTENDANCE_CLOSED');
    expect(store.saving, false);
  });
  test('no optimistic success and duplicate tap is ignored while saving',
      () async {
    final gate = Completer<MealAttendance>();
    var calls = 0;
    final api = FakeAttendanceApi()
      ..onUpdate = (_) {
        calls++;
        return gate.future;
      };
    final store = MealAttendanceStore(api, 'p', 's');
    await store.load();
    final pending = store.update(AttendanceStatus.attending);
    await store.update(AttendanceStatus.notAttending);
    expect(calls, 1);
    expect(store.value?.myStatus, AttendanceStatus.unknown);
    expect(store.saving, true);
    gate.complete(MealAttendance.fromJson(attendanceJson(status: 'ATTENDING')));
    await pending;
    expect(store.value?.myStatus, AttendanceStatus.attending);
  });
  test('read-only response prevents writes', () async {
    final api = FakeAttendanceApi()
      ..onGet =
          () async => MealAttendance.fromJson(attendanceJson(editable: false));
    final store = MealAttendanceStore(api, 'p', 's');
    await store.load();
    await store.update(AttendanceStatus.attending);
    expect(store.value?.myStatus, AttendanceStatus.unknown);
  });
  test(
      'API sends camelCase status using PUT and clears using DELETE, maps errors',
      () async {
    final adapter = FakeHttpAdapter((options) async {
      if (options.method == 'PUT') {
        expect(options.data, {'status': 'ATTENDING'});
        return jsonResponse(
            200, successEnvelope(attendanceJson(status: 'ATTENDING')));
      }
      if (options.method == 'DELETE') {
        return jsonResponse(200, successEnvelope(attendanceJson()));
      }
      return jsonResponse(
          409, errorEnvelope('ERR_PLAN_ATTENDANCE_CLOSED', 'closed'));
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    final api = MealAttendanceApi(
        DioClient.build(tokenStorage: TokenStorage(), dio: dio));
    expect((await api.update('p', 's', AttendanceStatus.attending)).myStatus,
        AttendanceStatus.attending);
    expect(
        (await api.update('p', 's', AttendanceStatus.unknown)).unknownCount, 1);
    expect(adapter.requests[1].method, 'DELETE');
    await expectLater(api.get('p', 's'), throwsA(isA<BusinessException>()));
  });
  testWidgets(
      'panel renders unanswered and saved attending state without a vote session',
      (tester) async {
    final api = FakeAttendanceApi()
      ..onUpdate = (_) async =>
          MealAttendance.fromJson(attendanceJson(status: 'ATTENDING'));
    Get.put<MealAttendanceApi>(api);
    await tester
        .pumpAppWidget(const MealAttendancePanel(planId: 'p', slotId: 's'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa phản hồi'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Có ăn'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 thành viên có ăn'), findsOneWidget);
  });
}
