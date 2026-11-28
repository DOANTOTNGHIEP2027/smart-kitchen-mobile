import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/notification/app_notification.dart';
import 'package:smart_kitchen_mobile/stores/notification_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import '../data/notification/notification_fakes.dart';

/// Hộp thư đọc từ server (#201): tải, phân trang, đọc/đọc tất cả, lỗi, bỏ
/// trùng push foreground.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeNotificationApi api;
  late SessionStore session;
  late NotificationStore store;

  NotificationStore build() => store = NotificationStore(
        gateway: FakePushGateway(),
        deviceApi: FakeDeviceApi(),
        prefs: FakeNotificationPrefs(asked: true),
        session: session,
        api: api,
      );

  Future<void> signedInStore() async {
    await signIn(session);
    await build().init();
    await settle();
  }

  List<String> ids() => store.notifications.map((n) => n.id).toList();

  setUp(() {
    api = FakeNotificationApi(items: <AppNotification>[
      serverNotification('s1'),
      serverNotification('s2', read: true),
      serverNotification('s3'),
      serverNotification('s4'),
      serverNotification('s5'),
    ]);
    session = newSession();
  });

  tearDown(() => store.dispose());

  group('tải', () {
    test('đã đăng nhập → init tải trang đầu + số chưa đọc từ server', () async {
      api.unread = 7;
      await signedInStore();
      expect(api.listedPages, <int>[0]);
      expect(ids(), <String>['s1', 's2']);
      expect(store.hasMore, isTrue);
      expect(store.unreadCount, 7, reason: 'lấy từ API, không đếm list');
      expect(store.listState, isA<SuccessState<List<AppNotification>>>());
    });

    test('chưa đăng nhập → không gọi API; đăng nhập → tải', () async {
      await build().init();
      await store.refresh();
      expect(api.listedPages, isEmpty);
      await signIn(session);
      await settle();
      expect(api.listedPages, <int>[0]);
    });

    test('đang tải lần đầu → LoadingState; xong → Success; rỗng → Empty',
        () async {
      api.holdList = Completer<void>();
      await signIn(session);
      await build().init();
      await settle();
      expect(store.listState, isA<LoadingState<List<AppNotification>>>());
      api.holdList!.complete();
      await settle();
      expect(store.listState, isA<SuccessState<List<AppNotification>>>());

      api
        ..holdList = null
        ..items = <AppNotification>[];
      await store.refresh();
      expect(store.listState, isA<EmptyState<List<AppNotification>>>());
      expect(store.unreadCount, 0);
    });

    test('lỗi → ErrorState (không quay mãi); thử lại thành công → Success',
        () async {
      api.listError = NetworkException();
      await signedInStore();
      expect(store.isInboxLoading, isFalse);
      final state = store.listState;
      expect(state, isA<ErrorState<List<AppNotification>>>());
      expect((state as ErrorState<List<AppNotification>>).error,
          isA<NetworkException>());

      api.listError = null;
      await store.refresh();
      expect(store.listState, isA<SuccessState<List<AppNotification>>>());
      expect(store.inboxError, isNull);
    });

    test('tải lại lỗi khi đã có dữ liệu → giữ list, chỉ đặt inboxError',
        () async {
      await signedInStore();
      api.listError = ServerException('ERR_INTERNAL', 'x');
      await store.refresh();
      expect(ids(), <String>['s1', 's2']);
      expect(store.listState, isA<SuccessState<List<AppNotification>>>());
      expect(store.inboxError, isA<ServerException>());
    });

    test('gọi refresh khi đang tải → chạy thêm đúng 1 lượt sau đó', () async {
      await signedInStore();
      api
        ..listedPages.clear()
        ..holdList = Completer<void>();
      final a = store.refresh();
      final b = store.refresh();
      final c = store.refresh();
      api.holdList!.complete();
      await Future.wait(<Future<void>>[a, b, c]);
      expect(api.listedPages, <int>[0, 0]);
    });

    test('đăng xuất → xoá hộp thư + số chưa đọc server', () async {
      api.unread = 3;
      await signedInStore();
      await session.clear();
      await settle();
      expect(store.notifications, isEmpty);
      expect(store.unreadCount, 0);
      expect(store.hasMore, isFalse);
      expect(store.listState, isA<EmptyState<List<AppNotification>>>());
    });
  });

  group('phân trang', () {
    test('loadMore nối trang kế tới hết; hết trang thì không gọi nữa',
        () async {
      await signedInStore();
      await store.loadMore();
      expect(ids(), <String>['s1', 's2', 's3', 's4']);
      await store.loadMore();
      expect(ids(), <String>['s1', 's2', 's3', 's4', 's5']);
      expect(store.hasMore, isFalse);
      await store.loadMore();
      expect(api.listedPages, <int>[0, 1, 2]);
    });

    test('trang bị dịch do thông báo mới → bỏ trùng theo id', () async {
      await signedInStore();
      // Server có thêm 1 bản ghi mới ở đầu → trang 1 bắt đầu bằng s2 (đã có).
      api.items.insert(0, serverNotification('s0'));
      await store.loadMore();
      expect(ids(), <String>['s1', 's2', 's3']);
    });

    test('loadMore lỗi → loadMoreError, giữ list; thử lại được', () async {
      await signedInStore();
      api.listError = NetworkException();
      await store.loadMore();
      expect(store.loadMoreError, isA<NetworkException>());
      expect(store.isLoadingMore, isFalse);
      expect(ids(), <String>['s1', 's2']);
      api.listError = null;
      await store.loadMore();
      expect(store.loadMoreError, isNull);
      expect(ids(), hasLength(4));
    });
  });

  group('đánh dấu đã đọc', () {
    test('markRead thành công → THAY phần tử bằng bản server, giảm số chưa đọc',
        () async {
      await signedInStore();
      expect(store.unreadCount, 4, reason: 's1, s3, s4, s5');
      final pending = store.markRead('s1');
      // Lạc quan: đổi ngay, trước khi server trả về.
      expect(store.notifications.first.read, isTrue);
      expect(store.unreadCount, 3);
      await pending;
      expect(api.markedRead, <String>['s1']);
      expect(store.notifications.first.read, isTrue);
      expect(store.notifications.first.readAt, DateTime(2026, 11, 21));
      expect(store.unreadCount, 3);
      expect(store.actionError, isNull);
    });

    test('markRead lỗi → hoàn lại chưa đọc + số chưa đọc + actionError',
        () async {
      await signedInStore();
      api.markReadError = NetworkException();
      await store.markRead('s1');
      expect(store.notifications.first.read, isFalse);
      expect(store.notifications.first.readAt, isNull);
      expect(store.unreadCount, 4);
      expect(store.actionError, isA<NetworkException>());
    });

    test('markRead mục đã đọc → không gọi API', () async {
      await signedInStore();
      await store.markRead('s2');
      expect(api.markedRead, isEmpty);
    });

    test(
        'markAllRead thành công → mọi mục đã đọc, số chưa đọc lấy lại từ server',
        () async {
      await signedInStore();
      await store.markAllRead();
      expect(api.markAllCalls, 1);
      expect(store.notifications.every((n) => n.read), isTrue);
      expect(store.notifications.first.readAt, isNotNull);
      expect(store.unreadCount, 0);
    });

    test('markAllRead lỗi → hoàn lại đúng các mục chưa đọc + số chưa đọc',
        () async {
      await signedInStore();
      api.markAllError = ServerException('ERR_INTERNAL', 'x');
      await store.markAllRead();
      expect(store.notifications.map((n) => n.read), <bool>[false, true]);
      expect(store.notifications.first.readAt, isNull);
      expect(store.unreadCount, 4);
      expect(store.actionError, isA<ServerException>());
    });
  });

  group('push foreground', () {
    test('hiện ngay (lạc quan) rồi thay bằng bản server — không trùng',
        () async {
      api.items = <AppNotification>[serverNotification('s1')];
      await signedInStore();
      expect(store.unreadCount, 1);

      // Server đã lưu bản ghi trước khi gửi push.
      api.items
          .insert(0, serverNotification('srv-new', type: 'SHOPPING_ASSIGNED'));
      store.addNotification(AppNotification.fromPush(
          <String, dynamic>{'type': 'SHOPPING_ASSIGNED'},
          title: 'Bạn được giao món', messageId: 'fcm-1'));
      expect(ids().first, 'fcm-1', reason: 'hiện ngay, chưa chờ API');
      expect(store.unreadCount, 2);

      await settle();
      expect(ids(), <String>['srv-new', 's1']);
      expect(store.notifications.every((n) => n.fromServer), isTrue);
      expect(store.unreadCount, 2);
    });

    test('tải lại lỗi (offline) → push lạc quan vẫn còn trong list', () async {
      await signedInStore();
      api.listError = NetworkException();
      store.addNotification(AppNotification.fromPush(const <String, dynamic>{},
          messageId: 'fcm-2'));
      await settle();
      expect(ids().first, 'fcm-2');
      expect(store.inboxError, isA<NetworkException>());
    });

    test('push đã tap có notificationId → báo server đã đọc trước khi tải lại',
        () async {
      await signedInStore();
      store.addNotification(AppNotification.fromPush(<String, dynamic>{
        'type': 'INVENTORY_EXPIRY_ALERT',
        'notificationId': 's3'
      }, messageId: 'fcm-3', read: true));
      await settle();
      expect(api.markedRead, <String>['s3']);
      expect(ids(), <String>['s1', 's2']);
    });
  });
}
