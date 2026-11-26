import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/interceptors/error_mapping_interceptor.dart';
import 'package:smart_kitchen_mobile/data/notification/bg_files.dart';
import 'package:smart_kitchen_mobile/data/notification/cross_isolate_lock.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_routing.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_service.dart';
import 'package:smart_kitchen_mobile/data/notification/quick_action_background.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';

import '../../helpers/fake_http_adapter.dart';
import 'quick_action_test_support.dart';

/// QuickActionBackgroundRunner — ma trận A10 (inventory-management.md §20.3
/// Amendment #134 A4, A6, A7; Guard 18, 20, 27).
void main() {
  const refreshPath = '/api/v1/auth/refresh';
  final l10n = lookupAppLocalizations(const Locale('vi'));
  final alert = notificationFixture('capable_android_3items.json');
  final itemId = alert['actionItemId'] as String;
  final quickPath = '/api/v1/inventory-items/$itemId/quick-action';

  late Directory dir;
  late BgFiles files;
  late ScriptedTokenStorage storage;
  late FakeQuickActionPresenter presenter;
  late int pings;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sk_qa_');
    files = BgFiles(baseDirectory: () async => dir);
    storage = ScriptedTokenStorage(refreshToken: 'refresh-1');
    presenter = FakeQuickActionPresenter();
    pings = 0;
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  /// Server giả: refresh trả [refresh] (mặc định fixture 200), quick-action
  /// trả [quick]. `null` ⇒ treo vô hạn.
  FakeHttpAdapter server({
    Future<ResponseBody> Function()? refresh,
    Future<ResponseBody> Function()? quick,
  }) =>
      FakeHttpAdapter((options) {
        if (options.path == refreshPath) {
          return refresh?.call() ??
              Future<ResponseBody>.value(
                  jsonResponse(200, notificationFixture('refresh_200.json')));
        }
        return quick?.call() ??
            Future<ResponseBody>.value(
                jsonResponse(200, notificationFixture('qa_applied_true.json')));
      });

  QuickActionBackgroundRunner runner(
    FakeHttpAdapter adapter, {
    CrossIsolateLock? lock,
    Duration deadline = const Duration(seconds: 9),
    Duration stepBudget = const Duration(seconds: 3),
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter
      ..interceptors.add(ErrorMappingInterceptor());
    return QuickActionBackgroundRunner(
      dio: dio,
      tokenStorage: storage,
      lock: lock ?? InProcessLock(),
      files: files,
      presenter: presenter,
      l10n: l10n,
      pingCatchUp: () => pings++,
      deadline: deadline,
      lockWait: const Duration(milliseconds: 100),
      stepBudget: stepBudget,
    );
  }

  NotificationResponse tap(
    String actionId, {
    Map<String, dynamic>? data,
  }) =>
      NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        actionId: actionId,
        payload: encodeNotificationInteraction(
          data ?? alert,
          42,
          messageId: 'm1',
          title: alert['title'] as String,
          body: alert['body'] as String,
        ),
      );

  Future<bool> flagSet() => files.hasInventoryPendingSync();

  QuickActionNotification last() => presenter.shown.last;

  test(
      'S0 "Đang cập nhật kho…" không nút hiện TRƯỚC request đầu; '
      'refresh-first rồi mới POST quick-action', () async {
    final adapter = server();
    int? requestsAtS0;
    presenter.onShow = (n) => requestsAtS0 ??= adapter.requests.length;

    await runner(adapter).handle(tap('MARK_USED'));

    final s0 = presenter.shown.first;
    expect(requestsAtS0, 0);
    expect(s0.id, 42);
    expect(s0.body, l10n.notificationQuickActionProcessing);
    expect(s0.actions, isEmpty);
    expect(s0.timeoutAfterMs, isNull);
    expect(
        adapter.requests.map((r) => r.path), <String>[refreshPath, quickPath]);
    final post = adapter.requests.last;
    expect(post.headers['Authorization'],
        'Bearer ${notificationFixture('refresh_200.json')['data']['accessToken']}');
    expect(jsonDecode(jsonEncode(post.data)),
        <String, dynamic>{'action': 'MARK_USED'});
    expect(storage.refreshToken, 'refresh-2',
        reason: 'RT mới ghi xuống storage');
  });

  test(
      'S1 applied=true ⇒ "Đã cập nhật kho", không nút, tự ẩn 4 s, đặt cờ + ping',
      () async {
    await runner(server()).handle(tap('DISCARD'));

    expect(last().body, l10n.notificationInventoryUpdated);
    expect(last().actions, isEmpty);
    expect(last().timeoutAfterMs, 4000);
    expect(last().id, 42);
    expect(await flagSet(), isTrue);
    expect(pings, 1);
  });

  group('S2 applied=false — copy thể bị động, nhánh mặc định bắt buộc', () {
    final cases = <String, String Function()>{
      'qa_noop_cooked.json': () => l10n.notificationInventoryAlreadyUsed,
      'qa_noop_waste.json': () => l10n.notificationInventoryAlreadyDiscarded,
      'qa_noop_corrected.json': () =>
          l10n.notificationInventoryAlreadyProcessed,
      'qa_noop_unknown_reason.json': () =>
          l10n.notificationInventoryAlreadyProcessed,
      'qa_noop_null.json': () => l10n.notificationInventoryAlreadyProcessed,
    };
    cases.forEach((fixture, expected) {
      test(fixture, () async {
        await runner(server(
          quick: () async => jsonResponse(200, notificationFixture(fixture)),
        )).handle(tap('MARK_USED'));

        expect(last().body, expected());
        expect(last().body, isNot(contains('Ai đó')));
        expect(last().actions, isEmpty);
        expect(last().timeoutAfterMs, 4000);
        expect(await flagSet(), isTrue);
      });
    });
  });

  test('S3 404 ⇒ "không còn trong kho", tự ẩn, đặt cờ', () async {
    await runner(server(
      quick: () async => jsonResponse(404, notificationFixture('qa_404.json')),
    )).handle(tap('MARK_USED'));

    expect(last().body, l10n.notificationInventoryGone);
    expect(last().timeoutAfterMs, 4000);
    expect(await flagSet(), isTrue);
  });

  test('S4 403 readonly ⇒ giữ notification, không nút, KHÔNG đặt cờ', () async {
    await runner(server(
      quick: () async =>
          jsonResponse(403, notificationFixture('qa_403_readonly.json')),
    )).handle(tap('MARK_USED'));

    expect(last().body, l10n.notificationInventoryReadonly);
    expect(last().actions, isEmpty);
    expect(last().timeoutAfterMs, isNull);
    expect(await flagSet(), isFalse);
    expect(pings, 0);
  });

  test('S5 403 no-household ⇒ "Chạm để mở ứng dụng", deep link Tồn kho',
      () async {
    await runner(server(
      quick: () async =>
          jsonResponse(403, notificationFixture('qa_403_no_household.json')),
    )).handle(tap('MARK_USED'));

    expect(last().body, l10n.notificationQuickActionOpenApp);
    expect(last().actions, isEmpty);
    final data = decodeNotificationInteraction(last().payload)!.data;
    expect(data['deepLink'], 'smartkitchen://inventory?item=$itemId');
    expect(resolveNotificationTarget(data), NotificationTarget.inventory);
    expect(await flagSet(), isFalse);
  });

  test(
      'S6 refresh ERR_AUTH_005 ⇒ "Phiên đăng nhập đã hết", 0 POST quick-action',
      () async {
    final adapter = server(
      refresh: () async =>
          jsonResponse(401, notificationFixture('refresh_401_auth005.json')),
    );
    await runner(adapter).handle(tap('MARK_USED'));

    expect(last().body, l10n.notificationQuickActionSessionExpired);
    expect(last().actions, isEmpty);
    expect(adapter.countPath(quickPath), 0);
    final data = decodeNotificationInteraction(last().payload)!.data;
    expect(resolveNotificationTarget(data), NotificationTarget.inventory);
    expect(await flagSet(), isFalse);
    expect(storage.cleared, isFalse, reason: 'isolate nền không tự logout');
  });

  test('S6 401 SAU refresh ⇒ auth-fail, đúng 1 lần refresh', () async {
    final adapter = server(
      quick: () async => jsonResponse(
          401, errorEnvelope('ERR_AUTH_001', 'Access token expired')),
    );
    await runner(adapter).handle(tap('DISCARD'));

    expect(last().body, l10n.notificationQuickActionSessionExpired);
    expect(adapter.countPath(refreshPath), 1);
    expect(adapter.countPath(quickPath), 1);
  });

  test('S6 không đọc được token (storage lỗi) ⇒ auth-fail, 0 request',
      () async {
    storage.readError = PlatformException(code: 'keystore');
    final adapter = server();
    await runner(adapter).handle(tap('MARK_USED'));

    expect(last().body, l10n.notificationQuickActionSessionExpired);
    expect(adapter.requests, isEmpty);
  });

  test('S6 RT bị xoá (logout) trong lúc refresh ⇒ KHÔNG ghi token mới',
      () async {
    final adapter = server(refresh: () async {
      storage.refreshToken = null;
      return jsonResponse(200, notificationFixture('refresh_200.json'));
    });
    await runner(adapter).handle(tap('MARK_USED'));

    expect(storage.saveCalls, 0);
    expect(storage.refreshToken, isNull);
    expect(last().body, l10n.notificationQuickActionSessionExpired);
    expect(adapter.countPath(quickPath), 0);
  });

  test(
      'S7 mất mạng ⇒ nội dung gốc + dòng "Không có mạng", GIỮ nút gốc, '
      'không cờ, không queue', () async {
    final adapter = FakeHttpAdapter((options) async =>
        throw DioException.connectionError(
            requestOptions: options, reason: 'offline'));
    await runner(adapter).handle(tap('MARK_USED'));

    expect(last().body, contains(alert['body'] as String));
    expect(last().body, contains(l10n.notificationNoNetwork));
    expect(last().actions.map((a) => a.id),
        <String>['COOK_TODAY', 'MARK_USED', 'DISCARD']);
    expect(last().timeoutAfterMs, isNull);
    expect(await flagSet(), isFalse);
    expect(adapter.requests, hasLength(1), reason: 'không retry/queue');
  });

  test('S7 lockTimeout ⇒ mạng (KHÔNG phải auth-fail), 0 request', () async {
    final adapter = server();
    await runner(adapter, lock: TimeoutLock()).handle(tap('MARK_USED'));

    expect(last().body, contains(l10n.notificationNoNetwork));
    expect(last().body,
        isNot(contains(l10n.notificationQuickActionSessionExpired)));
    expect(adapter.requests, isEmpty);
  });

  test('S7 5xx ở quick-action ⇒ nhánh mạng', () async {
    await runner(server(
      quick: () async =>
          jsonResponse(503, errorEnvelope('ERR_INTERNAL', 'down')),
    )).handle(tap('MARK_USED'));
    expect(last().body, contains(l10n.notificationNoNetwork));
  });

  test('S7 hết ngân sách ở bước refresh (treo) ⇒ nhánh mạng', () async {
    final adapter = server(refresh: () => Completer<ResponseBody>().future);
    await runner(
      adapter,
      deadline: const Duration(seconds: 2),
      stepBudget: const Duration(milliseconds: 150),
    ).handle(tap('MARK_USED'));

    expect(last().body, contains(l10n.notificationNoNetwork));
    expect(adapter.countPath(quickPath), 0);
  });

  test('S7 hết ngân sách ở bước quick-action (treo) ⇒ nhánh mạng', () async {
    final adapter = server(quick: () => Completer<ResponseBody>().future);
    final watch = Stopwatch()..start();
    await runner(
      adapter,
      deadline: const Duration(seconds: 2),
      stepBudget: const Duration(milliseconds: 150),
    ).handle(tap('MARK_USED'));

    expect(last().body, contains(l10n.notificationNoNetwork));
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(await flagSet(), isFalse);
  });

  test('S7 deadline đã hết trước khi gọi ⇒ nhánh mạng, 0 request', () async {
    final adapter = server();
    await runner(adapter, deadline: Duration.zero).handle(tap('MARK_USED'));
    expect(last().body, contains(l10n.notificationNoNetwork));
    expect(adapter.requests, isEmpty);
  });

  test('S8 400 ⇒ "Không thực hiện được — thử lại", giữ nút gốc', () async {
    await runner(server(
      quick: () async =>
          jsonResponse(400, errorEnvelope('ERR_VALIDATION', 'bad action')),
    )).handle(tap('MARK_USED'));

    expect(last().body, contains(l10n.notificationQuickActionRetry));
    expect(last().actions, hasLength(3));
    expect(await flagSet(), isFalse);
  });

  test('S8 response lệch shape (parse) ⇒ lỗi khác', () async {
    await runner(server(
      quick: () async =>
          jsonResponse(200, successEnvelope(<String, dynamic>{})),
    )).handle(tap('MARK_USED'));
    expect(last().body, contains(l10n.notificationQuickActionRetry));
  });

  test('payload thiếu actionItemId ⇒ S8, 0 request', () async {
    final adapter = server();
    final data = Map<String, dynamic>.from(alert)..remove('actionItemId');
    await runner(adapter).handle(tap('MARK_USED', data: data));
    expect(last().body, contains(l10n.notificationQuickActionRetry));
    expect(adapter.requests, isEmpty);
  });

  test('COOK_TODAY / chạm thân không đi runner nền', () async {
    final adapter = server();
    await runner(adapter).handle(tap('COOK_TODAY'));
    expect(adapter.requests, isEmpty);
    expect(presenter.shown, isEmpty);
  });

  group('chống double-fire (Guard 27)', () {
    test(
        'guard in-flight cùng pid đang giữ ⇒ 0 request, notification không đổi',
        () async {
      final held =
          await files.tryAcquireInFlight(itemId: itemId, action: 'DISCARD');
      expect(held, isNotNull);
      final adapter = server();

      await runner(adapter).handle(tap('MARK_USED'));

      expect(adapter.requests, isEmpty);
      expect(presenter.shown, isEmpty);
    });

    test('guard pid khác (process cũ đã chết) ⇒ runner chạy bình thường',
        () async {
      final stale =
          BgFiles(baseDirectory: () async => dir, currentPid: () => -7);
      await stale.tryAcquireInFlight(itemId: itemId, action: 'DISCARD');
      final adapter = server();

      await runner(adapter).handle(tap('MARK_USED'));

      expect(adapter.countPath(quickPath), 1);
      expect(last().body, l10n.notificationInventoryUpdated);
    });

    test('bấm 2 lần thật nhanh ⇒ đúng 1 refresh + 1 quick-action', () async {
      final adapter = server();
      final r = runner(adapter);
      await Future.wait(<Future<void>>[
        r.handle(tap('MARK_USED')),
        r.handle(tap('MARK_USED')),
      ]);
      expect(adapter.countPath(refreshPath), 1);
      expect(adapter.countPath(quickPath), 1);
    });

    test(
        'guard được xoá sau khi xong ⇒ bấm lại về sau vẫn chạy (applied=false)',
        () async {
      await runner(server()).handle(tap('MARK_USED'));
      final adapter = server(
        quick: () async =>
            jsonResponse(200, notificationFixture('qa_noop_cooked.json')),
      );
      await runner(adapter).handle(tap('MARK_USED'));
      expect(adapter.countPath(quickPath), 1);
      expect(last().body, l10n.notificationInventoryAlreadyUsed);
    });
  });
}
