import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/notification/device_api.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_prefs.dart';
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
