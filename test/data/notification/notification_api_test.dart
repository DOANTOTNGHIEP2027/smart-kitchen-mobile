import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_api.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_mapper.dart';
import 'package:smart_kitchen_mobile/data/notification/notification_routing.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

Map<String, dynamic> responseJson({
  String id = '0b6f3c2e-1111-4a5b-9c8d-000000000001',
  String type = 'SHOPPING_ASSIGNED',
  bool read = false,
  String? readAt,
  Object? data = const <String, dynamic>{'householdId': 'h1', 'itemId': 'i9'},
}) =>
    <String, dynamic>{
      'id': id,
      'type': type,
      'title': 'Bạn được giao món',
      'body': 'Sữa tươi',
      'data': data,
      'read': read,
      'readAt': readAt,
      'createdAt': '2026-11-27T08:30:00Z',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('notificationFromJson', () {
    test('map đủ trường; fromServer; đích theo type top-level', () {
      final n = notificationFromJson(responseJson());
      expect(n.id, '0b6f3c2e-1111-4a5b-9c8d-000000000001');
      expect(n.type, 'SHOPPING_ASSIGNED');
      expect(n.title, 'Bạn được giao món');
      expect(n.body, 'Sữa tươi');
      expect(n.data, <String, String>{'householdId': 'h1', 'itemId': 'i9'});
      expect(n.read, isFalse);
      expect(n.readAt, isNull);
      expect(n.fromServer, isTrue);
      expect(n.target, NotificationTarget.shopping);
      expect(n.receivedAt, DateTime.utc(2026, 11, 27, 8, 30).toLocal());
    });

    test(
        'đã đọc: readAt parse; data null / giá trị không phải chuỗi không làm hỏng',
        () {
      final read = notificationFromJson(
          responseJson(read: true, readAt: '2026-11-27T09:00:00Z', data: null));
      expect(read.read, isTrue);
      expect(read.readAt, DateTime.utc(2026, 11, 27, 9).toLocal());
      expect(read.data, isEmpty);

      final odd = notificationFromJson(responseJson(
          type: 'MEAL_ATTENDANCE_REMINDER',
          data: <String, dynamic>{'planId': 12, 'slotId': null}));
      expect(odd.data, <String, String>{'planId': '12', 'slotId': ''});
      expect(odd.target, NotificationTarget.mealPlan);
    });

    test('title/body rỗng → null (UI dùng chữ mặc định)', () {
      final n = notificationFromJson(responseJson()
        ..['title'] = ''
        ..['body'] = null);
      expect(n.title, isNull);
      expect(n.body, isNull);
    });

    test('notificationPageFromJson + hasMore', () {
      final page = notificationPageFromJson(<String, dynamic>{
        'items': <dynamic>[responseJson()],
        'page': 0,
        'size': 20,
        'totalElements': 21,
        'totalPages': 2,
      });
      expect(page.items, hasLength(1));
      expect(page.hasMore, isTrue);
      final last = notificationPageFromJson(<String, dynamic>{
        'items': <dynamic>[],
        'page': 1,
        'size': 20,
        'totalElements': 21,
        'totalPages': 2,
      });
      expect(last.hasMore, isFalse);
    });
  });

  group('NotificationApiImpl', () {
    final storage = FakeSecureStorageChannel();
    setUp(storage.install);
    tearDown(storage.uninstall);

    NotificationApiImpl api(FakeHttpAdapter adapter) {
      final client = DioClient.build(
          tokenStorage: TokenStorage(),
          dio: Dio(BaseOptions(baseUrl: 'https://test.local')));
      client.dio.httpClientAdapter = adapter;
      return NotificationApiImpl(client);
    }

    test('GET /api/v1/notifications?page&size → trang', () async {
      final adapter = FakeHttpAdapter((_) async => jsonResponse(
          200,
          successEnvelope(<String, dynamic>{
            'items': <dynamic>[responseJson()],
            'page': 1,
            'size': 20,
            'totalElements': 21,
            'totalPages': 2,
          })));
      final page = await api(adapter).list(page: 1, size: 20);
      final req = adapter.requests.single;
      expect(req.method, 'GET');
      expect(req.path, '/api/v1/notifications');
      expect(req.queryParameters, <String, dynamic>{'page': 1, 'size': 20});
      expect(page.page, 1);
      expect(page.items.single.target, NotificationTarget.shopping);
    });

    test('unread-count, {id}/read, read-all', () async {
      final adapter = FakeHttpAdapter((options) async => jsonResponse(
          200,
          successEnvelope(switch (options.path) {
            '/api/v1/notifications/unread-count' => <String, dynamic>{
                'count': 4
              },
            '/api/v1/notifications/read-all' => <String, dynamic>{'updated': 3},
            _ => responseJson(
                id: 'n1', read: true, readAt: '2026-11-27T09:00:00Z'),
          })));
      final client = api(adapter);
      expect(await client.unreadCount(), 4);
      final read = await client.markRead('n1');
      expect(read.read, isTrue);
      expect(await client.markAllRead(), 3);
      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), <String>[
        'GET /api/v1/notifications/unread-count',
        'POST /api/v1/notifications/n1/read',
        'POST /api/v1/notifications/read-all',
      ]);
    });

    test('401 / 500 → ApiException (đã _unwrap)', () async {
      for (final status in <int>[401, 500]) {
        final adapter = FakeHttpAdapter(
            (_) async => jsonResponse(status, errorEnvelope('ERR_X', 'boom')));
        await expectLater(api(adapter).list(), throwsA(isA<ApiException>()),
            reason: '$status');
      }
    });
  });
}
