import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:mobx/mobx.dart';

import '../data/network/api_exception.dart';
import '../data/notification/app_notification.dart';
import '../data/notification/device_api.dart';
import '../data/notification/notification_api.dart';
import '../data/notification/notification_mapper.dart';
import '../data/notification/notification_prefs.dart';
import '../data/notification/notification_routing.dart';
import '../data/notification/push_gateway.dart';
import '../scenes/auth/stores/store_error.dart';
import '../widgets/states/view_state.dart';
import 'session_store.dart';

/// Trạng thái thông báo của app (fcm-notification-flow.md §6, §14).
///
/// MobX thuần như `MealPlanStore`. `NotificationService` vẫn là adapter phía
/// platform (local notification, listener FCM, quick-action); store giữ quyền,
/// token, hộp thư và đích điều hướng đang chờ.
///
/// Hộp thư (#201): có [NotificationApi] thì danh sách đọc từ server (phân
/// trang, số chưa đọc, đánh dấu đã đọc); push foreground vẫn hiện ngay (lạc
/// quan) rồi tải lại trang đầu để thay bằng bản ghi server (không trùng).
/// `api == null` → chỉ danh sách trong phiên như trước (test cũ, legacy).
class NotificationStore {
  NotificationStore({
    required PushGateway gateway,
    required DeviceApi deviceApi,
    required NotificationPrefs prefs,
    required SessionStore session,
    NotificationApi? api,
  })  : _gateway = gateway,
        _deviceApi = deviceApi,
        _prefs = prefs,
        _session = session,
        _api = api;

  /// Giới hạn danh sách trong phiên — chỉ áp khi không có API hộp thư.
  static const int maxNotifications = 50;

  /// Cỡ trang `GET /api/v1/notifications`.
  static const int pageSize = 20;

  /// deleteToken khi offline không được chặn hàng đợi token mãi.
  static const Duration deleteTokenTimeout = Duration(seconds: 10);

  final PushGateway _gateway;
  final DeviceApi _deviceApi;
  final NotificationPrefs _prefs;
  final SessionStore _session;
  final NotificationApi? _api;

  final Observable<NotificationPermissionStatus> _permission =
      Observable(NotificationPermissionStatus.notDetermined);
  final Observable<String?> _token = Observable(null);
  final Observable<bool> _loading = Observable(false);
  final Observable<ApiException?> _registrationError = Observable(null);
  final Observable<bool> _hasAsked = Observable(false);
  final Observable<bool> _initialized = Observable(false);
  final Observable<bool> _rationaleShown = Observable(false);
  final Observable<NotificationTarget?> _pendingTarget = Observable(null);
  final ObservableList<AppNotification> notifications = ObservableList();

  // Hộp thư server (#201).
  final Observable<bool> _inboxLoading = Observable(false);
  final Observable<ApiException?> _inboxError = Observable(null);
  final Observable<bool> _loadingMore = Observable(false);
  final Observable<ApiException?> _loadMoreError = Observable(null);
  final Observable<bool> _hasMore = Observable(false);
  final Observable<ApiException?> _actionError = Observable(null);

  /// Số chưa đọc theo server; `null` = chưa tải được lần nào.
  final Observable<int?> _serverUnread = Observable(null);
  int _page = 0;
  Future<void>? _inboxOp;
  bool _refreshAgain = false;

  StreamSubscription<String>? _refreshSub;
  ReactionDisposer? _sessionDisposer;
  bool _wasAuthenticated = false;
  // Tăng mỗi lần đăng xuất: kết quả đăng ký của phiên cũ về muộn bị bỏ.
  int _sessionGeneration = 0;
  Future<void>? _tokenOp;
  Future<void>? _permissionCheck;

  NotificationPermissionStatus get permissionStatus => _permission.value;
  String? get fcmToken => _token.value;
  bool get isLoading => _loading.value;
  ApiException? get registrationError => _registrationError.value;
  bool get hasAskedPermission => _hasAsked.value;
  bool get isSupported => _gateway.isSupported;
  NotificationTarget? get pendingTarget => _pendingTarget.value;

  late final Computed<bool> _shouldShowRationale = Computed(() =>
      _initialized.value &&
      _gateway.isSupported &&
      _session.isAuthenticated &&
      !_hasAsked.value &&
      !_rationaleShown.value &&
      _permission.value == NotificationPermissionStatus.notDetermined);

  /// Sheet giải thích: một lần sau lần đăng nhập đầu (§7, N3).
  bool get shouldShowRationale => _shouldShowRationale.value;

  /// Số chưa đọc của server + push lạc quan chưa đồng bộ. Chưa tải được từ
  /// server thì đếm trên danh sách trong bộ nhớ.
  late final Computed<int> _unread = Computed(() {
    final server = _serverUnread.value;
    if (server == null) return notifications.where((n) => !n.read).length;
    return server +
        notifications.where((n) => !n.fromServer && !n.read).length;
  });
  int get unreadCount => _unread.value;

  bool get isInboxLoading => _inboxLoading.value;
  ApiException? get inboxError => _inboxError.value;
  bool get hasMore => _hasMore.value;
  bool get isLoadingMore => _loadingMore.value;
  ApiException? get loadMoreError => _loadMoreError.value;

  /// Lỗi đánh dấu đã đọc (trạng thái đã được hoàn lại).
  ApiException? get actionError => _actionError.value;

  /// Có dữ liệu thì luôn hiện danh sách (lỗi tải lại chỉ là banner); trống
  /// thì loading → error (retry) → empty — không bao giờ quay mãi.
  late final Computed<ViewState<List<AppNotification>>> _listState =
      Computed(() {
    final items = notifications.toList();
    if (items.isNotEmpty) return SuccessState<List<AppNotification>>(items);
    if (_inboxLoading.value) return const LoadingState<List<AppNotification>>();
    final error = _inboxError.value;
    if (error != null) return ErrorState<List<AppNotification>>(error);
    return const EmptyState<List<AppNotification>>();
  });
  ViewState<List<AppNotification>> get listState => _listState.value;

  /// Gọi TRƯỚC `NotificationService.init()` (§14.1).
  Future<void> init() async {
    if (!_gateway.isSupported) {
      runInAction(() {
        _permission.value = NotificationPermissionStatus.unsupported;
        _initialized.value = true;
      });
      return;
    }
    final asked = await _prefs.hasAskedPermission();
    NotificationPermissionStatus status;
    try {
      status = await _gateway.currentPermission();
    } catch (error) {
      developer.log('Read notification permission failed: $error',
          name: 'FCM');
      status = NotificationPermissionStatus.notDetermined;
    }
    runInAction(() {
      _hasAsked.value = asked;
      _permission.value = status;
      _initialized.value = true;
    });
    _refreshSub = _gateway.onTokenRefresh.listen(
      (token) => _enqueue(() => _register(token)),
    );
    _wasAuthenticated = _session.isAuthenticated;
    _sessionDisposer = reaction<bool>(
      (_) => _session.isAuthenticated,
      _onAuthChanged,
    );
    if (_wasAuthenticated) {
      unawaited(refreshToken());
      unawaited(refresh());
    }
  }

  void _onAuthChanged(bool authenticated) {
    final was = _wasAuthenticated;
    _wasAuthenticated = authenticated;
    if (authenticated && !was) {
      unawaited(refreshToken());
      unawaited(refresh());
    } else if (!authenticated && was) {
      // Chỉ khi CHUYỂN từ đăng nhập → đăng xuất (§14.3); cold start chưa đăng
      // nhập không đụng tới token. Xoá state của tài khoản cũ NGAY — không chờ
      // deleteToken (cần mạng) để người đăng nhập kế tiếp không thấy dữ liệu
      // cũ (review #48 M1).
      _sessionGeneration++;
      runInAction(() {
        _token.value = null;
        _registrationError.value = null;
        _pendingTarget.value = null;
        notifications.clear();
        _inboxLoading.value = false;
        _inboxError.value = null;
        _loadingMore.value = false;
        _loadMoreError.value = null;
        _hasMore.value = false;
        _actionError.value = null;
        _serverUnread.value = null;
      });
      _page = 0;
      _refreshAgain = false;
      _enqueue(() async {
        try {
          await _gateway.deleteToken().timeout(deleteTokenTimeout);
        } catch (error) {
          developer.log('FCM deleteToken failed: $error', name: 'FCM');
        }
      });
    }
  }

  /// Người dùng bấm "Bật thông báo".
  Future<void> requestPermission() async {
    if (!_gateway.isSupported || _loading.value) return;
    runInAction(() {
      _loading.value = true;
      _hasAsked.value = true;
    });
    await _prefs.markPermissionAsked();
    try {
      final status = await _gateway.requestPermission();
      runInAction(() => _permission.value = status);
    } catch (error) {
      developer.log('FCM requestPermission failed: $error', name: 'FCM');
    } finally {
      runInAction(() => _loading.value = false);
    }
    if (permissionStatus == NotificationPermissionStatus.granted) {
      await refreshToken();
    }
  }

  /// "Để sau" / vuốt đóng sheet: đặt cờ, không gọi dialog hệ điều hành.
  Future<void> dismissRationale() async {
    runInAction(() => _hasAsked.value = true);
    await _prefs.markPermissionAsked();
  }

  /// Đánh dấu sheet đã hiện trong phiên — shell dựng lại không hiện lần 2.
  void markRationaleShown() => runInAction(() => _rationaleShown.value = true);

  /// App resumed: đọc lại quyền (người dùng có thể đổi trong Cài đặt).
  /// Single-flight; bỏ qua khi đang chờ dialog quyền (§14.4).
  Future<void> refreshPermission() {
    if (!_gateway.isSupported || _loading.value) return Future<void>.value();
    return _permissionCheck ??= _checkPermission()
        .whenComplete(() => _permissionCheck = null);
  }

  Future<void> _checkPermission() async {
    final before = permissionStatus;
    try {
      final status = await _gateway.currentPermission();
      runInAction(() => _permission.value = status);
    } catch (error) {
      developer.log('Read notification permission failed: $error',
          name: 'FCM');
      return;
    }
    if (permissionStatus == NotificationPermissionStatus.granted &&
        (before != NotificationPermissionStatus.granted ||
            registrationError != null)) {
      await refreshToken();
    }
  }

  /// getToken → đăng ký nếu đã đăng nhập + có quyền.
  Future<void> refreshToken() => _enqueue(() async {
        if (!_canRegister) return;
        String? token;
        try {
          token = await _gateway.getToken();
        } catch (error) {
          developer.log('FCM getToken failed: $error', name: 'FCM');
          return;
        }
        if (token != null) await _register(token);
      });

  bool get _canRegister =>
      _gateway.isSupported &&
      _session.isAuthenticated &&
      permissionStatus == NotificationPermissionStatus.granted;

  Future<void> _register(String token) async {
    if (!_canRegister) return;
    final generation = _sessionGeneration;
    try {
      await _deviceApi.registerDevice(fcmToken: token);
      if (generation != _sessionGeneration) return; // đã đăng xuất (N1)
      runInAction(() {
        _token.value = token;
        _registrationError.value = null;
      });
    } catch (raw) {
      final error = storeApiException(raw);
      developer.log('FCM token registration failed: $error', name: 'FCM');
      if (generation != _sessionGeneration) return;
      runInAction(() => _registrationError.value = error);
    }
  }

  /// Tuần tự hoá mọi thao tác token (§14.3).
  Future<void> _enqueue(Future<void> Function() op) {
    // Khởi tạo lười: Future tạo sẵn ở zone khác (vd. lúc dựng store) sẽ không
    // chạy callback trong zone hiện tại.
    final previous = _tokenOp ?? Future<void>.value();
    final next = previous.then((_) => op()).catchError((Object error) {
      developer.log('FCM token op failed: $error', name: 'FCM');
    });
    _tokenOp = next;
    return next;
  }

  /// Thêm push vừa nhận (lạc quan; bỏ trùng theo id). Có API hộp thư thì
  /// tải lại trang đầu ngay sau đó để thay bằng bản ghi server.
  void addNotification(AppNotification notification) {
    runInAction(() {
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index >= 0) {
        // Cùng thông báo đến lần 2 (vd. hiện foreground rồi được tap) — chỉ
        // cập nhật trạng thái đã đọc.
        if (notification.read && !notifications[index].read) {
          notifications[index] = notifications[index].copyWith(read: true);
        }
        return;
      }
      notifications.insert(0, notification);
      if (_api == null && notifications.length > maxNotifications) {
        notifications.removeRange(maxNotifications, notifications.length);
      }
    });
    if (_api != null && _session.isAuthenticated) {
      unawaited(_syncAfterPush(notification));
    }
  }

  /// Push đã tap mang `notificationId` (nếu BE gửi) → báo server đã đọc
  /// trước khi tải lại, để badge không đếm lại thông báo vừa mở.
  Future<void> _syncAfterPush(AppNotification notification) async {
    final serverId = notification.data['notificationId'];
    if (notification.read && serverId != null && serverId.isNotEmpty) {
      try {
        await _api!.markRead(serverId);
      } catch (error) {
        developer.log('Mark pushed notification read failed: $error',
            name: 'FCM');
      }
    }
    await refresh();
  }

  /// Tải lại trang đầu + số chưa đọc (mở màn, kéo để tải lại, resume, đăng
  /// nhập). Single-flight: gọi trong lúc đang tải thì chạy thêm đúng 1 lượt
  /// sau lượt hiện tại (push mới đến giữa chừng không bị lượt cũ ghi đè).
  Future<void> refresh() {
    if (_api == null || !_session.isAuthenticated) return Future<void>.value();
    final running = _inboxOp;
    if (running != null) {
      _refreshAgain = true;
      return running;
    }
    return _inboxOp = _refreshLoop().whenComplete(() => _inboxOp = null);
  }

  Future<void> _refreshLoop() async {
    do {
      _refreshAgain = false;
      await _loadFirstPage();
    } while (_refreshAgain && _session.isAuthenticated);
  }

  Future<void> _loadFirstPage() async {
    final api = _api!;
    final generation = _sessionGeneration;
    final startedAt = DateTime.now();
    runInAction(() => _inboxLoading.value = true);
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        api.list(page: 0, size: pageSize),
        api.unreadCount(),
      ]);
      if (generation != _sessionGeneration) return; // đã đăng xuất
      final page = results[0] as NotificationPage;
      final count = results[1] as int;
      runInAction(() {
        final ids = page.items.map((n) => n.id).toSet();
        // Push lạc quan đến SAU lúc bắt đầu tải có thể chưa nằm trong trang
        // này → giữ lại tới lượt tải sau; còn lại thay bằng bản ghi server.
        final pending = notifications
            .where((n) =>
                !n.fromServer &&
                n.receivedAt.isAfter(startedAt) &&
                !ids.contains(n.id))
            .toList();
        notifications
          ..clear()
          ..addAll(<AppNotification>[...pending, ...page.items]);
        _page = page.page;
        _hasMore.value = page.hasMore;
        _serverUnread.value = count;
        _inboxError.value = null;
        _loadMoreError.value = null;
      });
    } catch (raw) {
      final error = storeApiException(raw);
      developer.log('Load notifications failed: $error', name: 'FCM');
      if (generation != _sessionGeneration) return;
      runInAction(() => _inboxError.value = error);
    } finally {
      if (generation == _sessionGeneration) {
        runInAction(() => _inboxLoading.value = false);
      }
    }
  }

  /// Tải trang kế (cuộn tới cuối). Bỏ trùng theo id: thông báo mới đến làm
  /// trang bị dịch nên trang sau có thể lặp mục cuối của trang trước.
  Future<void> loadMore() async {
    final api = _api;
    if (api == null ||
        !_session.isAuthenticated ||
        !_hasMore.value ||
        _loadingMore.value ||
        _inboxLoading.value) {
      return;
    }
    final generation = _sessionGeneration;
    final next = _page + 1;
    runInAction(() {
      _loadingMore.value = true;
      _loadMoreError.value = null;
    });
    try {
      final page = await api.list(page: next, size: pageSize);
      if (generation != _sessionGeneration) return;
      runInAction(() {
        final ids = notifications.map((n) => n.id).toSet();
        notifications.addAll(page.items.where((n) => !ids.contains(n.id)));
        _page = page.page;
        _hasMore.value = page.hasMore;
      });
    } catch (raw) {
      final error = storeApiException(raw);
      developer.log('Load more notifications failed: $error', name: 'FCM');
      if (generation != _sessionGeneration) return;
      runInAction(() => _loadMoreError.value = error);
    } finally {
      if (generation == _sessionGeneration) {
        runInAction(() => _loadingMore.value = false);
      }
    }
  }

  /// Đánh dấu đã đọc: thay phần tử ngay trên UI rồi gọi server; thành công
  /// thì thay bằng bản ghi server trả về, lỗi thì hoàn lại + [actionError].
  /// Push lạc quan chỉ gọi server khi `data` có `notificationId`.
  Future<void> markRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index < 0 || notifications[index].read) return;
    final before = notifications[index];
    runInAction(() {
      notifications[index] = before.copyWith(read: true, readAt: DateTime.now());
      _actionError.value = null;
      final count = _serverUnread.value;
      if (before.fromServer && count != null) {
        _serverUnread.value = math.max(0, count - 1);
      }
    });
    final api = _api;
    final serverId = before.fromServer ? id : before.data['notificationId'];
    if (api == null || serverId == null || serverId.isEmpty) return;
    final generation = _sessionGeneration;
    try {
      final updated = await api.markRead(serverId);
      if (generation != _sessionGeneration) return;
      runInAction(() {
        final i = notifications.indexWhere((n) => n.id == id);
        if (i < 0) return;
        // Bản ghi server đã có trong list (refresh về trước) → bỏ bản lạc quan.
        final dup = updated.id == id
            ? -1
            : notifications.indexWhere((n) => n.id == updated.id);
        if (dup >= 0) {
          notifications
            ..[dup] = updated
            ..removeAt(i);
        } else {
          notifications[i] = updated;
        }
      });
    } catch (raw) {
      final error = storeApiException(raw);
      developer.log('Mark notification read failed: $error', name: 'FCM');
      if (generation != _sessionGeneration) return;
      runInAction(() {
        final i = notifications.indexWhere((n) => n.id == id);
        if (i >= 0 && notifications[i].read) notifications[i] = before;
        final count = _serverUnread.value;
        if (before.fromServer && count != null) _serverUnread.value = count + 1;
        _actionError.value = error;
      });
    }
  }

  /// "Đánh dấu đã đọc tất cả": như [markRead] nhưng cho cả hộp thư.
  Future<void> markAllRead() async {
    // Bản gốc của các mục chưa đọc — hoàn lại nguyên vẹn nếu server lỗi.
    final originals = <String, AppNotification>{
      for (final n in notifications)
        if (!n.read) n.id: n,
    };
    final countBefore = _serverUnread.value;
    final now = DateTime.now();
    runInAction(() {
      for (var i = 0; i < notifications.length; i++) {
        if (!notifications[i].read) {
          notifications[i] = notifications[i].copyWith(read: true, readAt: now);
        }
      }
      _actionError.value = null;
      if (countBefore != null) _serverUnread.value = 0;
    });
    final api = _api;
    if (api == null || !_session.isAuthenticated) return;
    final generation = _sessionGeneration;
    try {
      await api.markAllRead();
    } catch (raw) {
      final error = storeApiException(raw);
      developer.log('Mark all notifications read failed: $error',
          name: 'FCM');
      if (generation != _sessionGeneration) return;
      runInAction(() {
        for (var i = 0; i < notifications.length; i++) {
          final original = originals[notifications[i].id];
          if (original != null) notifications[i] = original;
        }
        if (countBefore != null) _serverUnread.value = countBefore;
        _actionError.value = error;
      });
      return;
    }
    // Thành công: lấy lại số chưa đọc từ server (có thể có thông báo mới đến
    // trong lúc gọi). Lỗi ở bước này không hoàn tác — giữ số 0 lạc quan.
    try {
      final count = await api.unreadCount();
      if (generation != _sessionGeneration) return;
      runInAction(() => _serverUnread.value = count);
    } catch (error) {
      developer.log('Reload unread count failed: $error', name: 'FCM');
    }
  }

  /// Đích điều hướng từ push — chỉ `ShellNotificationHost` tiêu thụ (§14.1).
  void navigateTo(NotificationTarget target) =>
      runInAction(() => _pendingTarget.value = target);

  NotificationTarget? consumePendingTarget() {
    final target = _pendingTarget.value;
    if (target != null) runInAction(() => _pendingTarget.value = null);
    return target;
  }

  void dispose() {
    _refreshSub?.cancel();
    _sessionDisposer?.call();
  }
}
