import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/notification/app_notification.dart';
import 'package:smart_kitchen_mobile/data/notification/device_api.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_api.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_mapper.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_prefs.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_routing.dart';
import 'package:smart_kitchen_mobile/data/notification/push_gateway.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

class FakePushGateway implements PushGateway {
  FakePushGateway({this.supported = true});

  bool supported;
  NotificationPermissionStatus current = NotificationPermissionStatus.notDetermined;
  NotificationPermissionStatus onRequest = NotificationPermissionStatus.granted;
  String? token = 'token-1';
  Object? getTokenError;
  Completer<void>? holdPermissionRead;
  Completer<void>? holdRequest;
  Completer<void>? holdDelete;
  int requestCalls = 0;
  int currentCalls = 0;
  int deleteCalls = 0;
  final StreamController<String> refreshController = StreamController<String>.broadcast();
  final List<String> log = <String>[];

  @override
  bool get isSupported => supported;

  @override
  Future<NotificationPermissionStatus> currentPermission() async {
    currentCalls++;
    final hold = holdPermissionRead;
    if (hold != null) await hold.future;
    return current;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestCalls++;
    final hold = holdRequest;
    if (hold != null) await hold.future;
    current = onRequest;
    return onRequest;
  }

  @override
  Future<String?> getToken() async {
    log.add('getToken');
    if (getTokenError != null) throw getTokenError!;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => refreshController.stream;

  @override
  Future<void> deleteToken() async {
    log.add('deleteToken');
    deleteCalls++;
    final hold = holdDelete;
    if (hold != null) await hold.future;
    token = 'token-${deleteCalls + 1}';
  }
}

class FakeDeviceApi implements DeviceApi {
  final List<String> registered = <String>[];
  Object? error;
  Completer<void>? hold;

  @override
  Future<void> registerDevice({required String fcmToken}) async {
    final pending = hold;
    if (pending != null) await pending.future;
    if (error != null) throw error!;
    registered.add(fcmToken);
  }
}

class FakeNotificationPrefs implements NotificationPrefs {
  FakeNotificationPrefs({this.asked = false});

  bool asked;

  @override
  Future<bool> hasAskedPermission() async => asked;

  @override
  Future<void> markPermissionAsked() async => asked = true;
}

class MemoryTokenStorage implements TokenStorage {
  @override
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readRefreshToken() async => refreshToken;
  @override
  Future<Map<String, dynamic>?> readUser() async => null;
  @override
  Future<void> saveTokens(String a, String r) async {
    accessToken = a;
    refreshToken = r;
  }

  @override
  Future<void> saveUser(Map<String, dynamic> json) async {}
}

SessionStore newSession() => SessionStore(MemoryTokenStorage(), AuthRefreshUseCase(Dio()));

String _jwt(Map<String, dynamic> claims) =>
    'h.${base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '')}.s';

Future<void> signIn(SessionStore session) => session.setSession(
      accessToken: _jwt(<String, dynamic>{'household_id': 'h1', 'role': 'OWNER'}),
      refreshToken: 'r',
      user: const UserSummary(id: 'u1', fullName: 'An'),
    );

/// Bản ghi server giả (`fromServer: true`) cho test hộp thư (#201).
AppNotification serverNotification(String id,
        {bool read = false, String type = 'INVENTORY_EXPIRY_ALERT', DateTime? at}) =>
    AppNotification(
      id: id,
      type: type,
      target: resolveNotificationTarget(<String, dynamic>{'type': type}),
      receivedAt: at ?? DateTime(2026, 11, 20),
      title: 'T-$id',
      read: read,
      fromServer: true,
    );

/// API hộp thư giả: dữ liệu theo trang trong bộ nhớ, lỗi/treo bơm được.
class FakeNotificationApi implements NotificationApi {
  FakeNotificationApi({List<AppNotification>? items, this.size = 2})
      : items = items ?? <AppNotification>[];

  List<AppNotification> items;
  final int size;
  int? unread;
  Object? listError;
  Object? markReadError;
  Object? markAllError;
  Completer<void>? holdList;
  final List<int> listedPages = <int>[];
  final List<String> markedRead = <String>[];
  int markAllCalls = 0;
  int unreadCalls = 0;

  int get _unread => unread ?? items.where((n) => !n.read).length;

  @override
  Future<NotificationPage> list({int page = 0, int size = 20}) async {
    listedPages.add(page);
    final hold = holdList;
    if (hold != null) await hold.future;
    if (listError != null) throw listError!;
    final from = page * this.size;
    final pageItems = items.skip(from).take(this.size).toList();
    return NotificationPage(
      items: pageItems,
      page: page,
      size: this.size,
      totalElements: items.length,
      totalPages: (items.length + this.size - 1) ~/ this.size,
    );
  }

  @override
  Future<int> unreadCount() async {
    unreadCalls++;
    if (listError != null) throw listError!;
    return _unread;
  }

  @override
  Future<AppNotification> markRead(String id) async {
    markedRead.add(id);
    if (markReadError != null) throw markReadError!;
    final i = items.indexWhere((n) => n.id == id);
    final updated = items[i].copyWith(read: true, readAt: DateTime(2026, 11, 21));
    items[i] = updated;
    return updated;
  }

  @override
  Future<int> markAllRead() async {
    markAllCalls++;
    if (markAllError != null) throw markAllError!;
    final count = items.where((n) => !n.read).length;
    items = items.map((n) => n.copyWith(read: true)).toList();
    return count;
  }
}
