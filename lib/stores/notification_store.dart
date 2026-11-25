import 'dart:async';
import 'dart:developer' as developer;

import 'package:mobx/mobx.dart';

import '../data/network/api_exception.dart';
import '../data/notification/app_notification.dart';
import '../data/notification/device_api.dart';
import '../data/notification/notification_prefs.dart';
import '../data/notification/notification_routing.dart';
import '../data/notification/push_gateway.dart';
import '../scenes/auth/stores/store_error.dart';
import 'session_store.dart';

/// Trạng thái thông báo của app (fcm-notification-flow.md §6, §14).
///
/// MobX thuần như `MealPlanStore`. `NotificationService` vẫn là adapter phía
/// platform (local notification, listener FCM, quick-action); store giữ quyền,
/// token, danh sách trong phiên và đích điều hướng đang chờ.
class NotificationStore {
  NotificationStore({
    required PushGateway gateway,
    required DeviceApi deviceApi,
    required NotificationPrefs prefs,
    required SessionStore session,
  })  : _gateway = gateway,
        _deviceApi = deviceApi,
        _prefs = prefs,
        _session = session;

  static const int maxNotifications = 50;

  /// deleteToken khi offline không được chặn hàng đợi token mãi.
  static const Duration deleteTokenTimeout = Duration(seconds: 10);

  final PushGateway _gateway;
  final DeviceApi _deviceApi;
  final NotificationPrefs _prefs;
  final SessionStore _session;

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

  late final Computed<int> _unread =
      Computed(() => notifications.where((n) => !n.read).length);
  int get unreadCount => _unread.value;

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
    if (_wasAuthenticated) unawaited(refreshToken());
  }

  void _onAuthChanged(bool authenticated) {
    final was = _wasAuthenticated;
    _wasAuthenticated = authenticated;
    if (authenticated && !was) {
      unawaited(refreshToken());
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
      });
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

  /// Thêm thông báo vào danh sách trong phiên (giới hạn, bỏ trùng theo id).
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
      if (notifications.length > maxNotifications) {
        notifications.removeRange(maxNotifications, notifications.length);
      }
    });
  }

  void markRead(String id) => runInAction(() {
        final index = notifications.indexWhere((n) => n.id == id);
        if (index >= 0 && !notifications[index].read) {
          notifications[index] = notifications[index].copyWith(read: true);
        }
      });

  void markAllRead() => runInAction(() {
        for (var i = 0; i < notifications.length; i++) {
          if (!notifications[i].read) {
            notifications[i] = notifications[i].copyWith(read: true);
          }
        }
      });

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
