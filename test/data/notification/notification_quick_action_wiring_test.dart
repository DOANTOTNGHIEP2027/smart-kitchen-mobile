import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_service.dart';
import 'package:smart_kitchen_mobile/data/notification/quick_action_api.dart';

import 'quick_action_test_support.dart';

class _NoopQuickActionApi implements QuickActionApi {
  @override
  Future<InventoryQuickActionResult> apply(
          {required String itemId, required String action}) =>
      throw UnimplementedError();
}

/// Wiring plugin local-notification cho quick-action nền (inventory-
/// management.md §20.3 Amendment #134 A9; Guard 24, 25, 26; E1).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];

  late NotificationService service;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'initialize' => true,
        _ => null,
      };
    });
    service = NotificationService(
      quickActionApi: _NoopQuickActionApi(),
      onInventoryChanged: () async {},
      onNavigate: (_) {},
      firebaseAvailable: false,
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  const message = RemoteMessage(messageId: 'm-qa', data: <String, dynamic>{});
  RemoteMessage alertMessage() => RemoteMessage(
        messageId: message.messageId,
        data: notificationFixture('capable_android_3items.json'),
      );

  Iterable<MethodCall> named(String method) =>
      calls.where((c) => c.method == method);

  Map<String, bool> showsUserInterfaceOf(MethodCall show) {
    final specifics = (show.arguments as Map)['platformSpecifics'] as Map;
    final actions =
        (specifics['actions'] as List).cast<Map<dynamic, dynamic>>();
    return <String, bool>{
      for (final a in actions)
        a['id'] as String: a['showsUserInterface'] as bool,
    };
  }

  test(
      'foreground render=LOCAL: MARK_USED/DISCARD showsUserInterface:false, '
      'COOK_TODAY true; KHÔNG initialize lần 2 (Guard 26)', () async {
    await service.init();
    expect(named('initialize'), hasLength(1));

    await service.handleForegroundMessage(alertMessage());

    expect(named('initialize'), hasLength(1));
    expect(showsUserInterfaceOf(named('show').single), <String, bool>{
      'COOK_TODAY': true,
      'MARK_USED': false,
      'DISCARD': false,
    });
  });

  test(
      'MỌI initialize (UI isolate + FCM nền) có callback handle nền (Guard 25)',
      () async {
    await service.init();
    await firebaseMessagingBackgroundHandler(alertMessage());

    final inits = named('initialize').toList();
    expect(inits, hasLength(2));
    for (final init in inits) {
      final args = init.arguments as Map;
      expect(args['callback_handle'], isA<int>());
      expect(args['dispatcher_handle'], isA<int>());
    }
    expect(showsUserInterfaceOf(named('show').single)['MARK_USED'], isFalse);
  });

  test('partition DEFAULT (không render) ⇒ không dựng local notification',
      () async {
    await firebaseMessagingBackgroundHandler(RemoteMessage(
      data: notificationFixture('default_partition.json'),
    ));
    expect(calls, isEmpty);
  });

  test('iOS (hoãn theo E1): category vẫn giữ .foreground cho MARK_USED/DISCARD',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    final ios = NotificationService(
      quickActionApi: _NoopQuickActionApi(),
      onInventoryChanged: () async {},
      onNavigate: (_) {},
      firebaseAvailable: false,
    );
    await ios.init();

    final args = named('initialize').single.arguments as Map;
    final categories =
        (args['notificationCategories'] as List).cast<Map<dynamic, dynamic>>();
    final actions =
        (categories.single['actions'] as List).cast<Map<dynamic, dynamic>>();
    final foreground = DarwinNotificationActionOption.foreground.value;
    for (final id in <String>['MARK_USED', 'DISCARD', 'COOK_TODAY']) {
      final action = actions.singleWhere((a) => a['identifier'] == id);
      expect(action['options'] as List, contains(foreground), reason: id);
    }
  });
}
