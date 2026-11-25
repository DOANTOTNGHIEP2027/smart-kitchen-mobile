import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/env_config.dart';
import '../../demo/demo_backend_adapter.dart';
import '../../domain/auth/auth_refresh_usecase.dart';
import '../../l10n/app_localizations.dart';
import '../auth/token_storage.dart';
import '../network/api_exception.dart';
import '../network/interceptors/error_mapping_interceptor.dart';
import 'bg_files.dart';
import 'cross_isolate_lock.dart';
import 'fcm_action_payload.dart';
import 'notification_service.dart';
import 'quick_action_api.dart';

/// Entry top-level của nút `MARK_USED`/`DISCARD` trên Android
/// (`showsUserInterface: false`) — chạy ở isolate nền do plugin dựng, kể cả
/// khi app terminated (Guard 23, 25; inventory-management.md §20.3 A3).
@pragma('vm:entry-point')
Future<void> quickActionBackgroundEntry(NotificationResponse response) async {
  // TRƯỚC mọi plugin: secure storage, path_provider, FLN.
  DartPluginRegistrant.ensureInitialized();
  try {
    await QuickActionBackgroundRunner.production().handle(response);
  } catch (error) {
    developer.log('Quick-action background failed: $error', name: 'FCM');
  }
}

/// Một lần dựng/cập nhật notification (cùng id, cùng payload — A6).
class QuickActionNotification {
  const QuickActionNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.actions,
    required this.payload,
    this.timeoutAfterMs,
  });

  final int id;
  final String? title;
  final String body;
  final List<FcmNotificationAction> actions;
  final String payload;
  final int? timeoutAfterMs;
}

abstract interface class QuickActionNotificationPresenter {
  Future<void> show(QuickActionNotification notification);
}

/// Presenter thật: tự khởi tạo plugin trong isolate nền với đủ callback nền
/// (Guard 25) rồi `show` cùng id, `onlyAlertOnce: true`.
class PluginQuickActionPresenter implements QuickActionNotificationPresenter {
  PluginQuickActionPresenter([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  @override
  Future<void> show(QuickActionNotification notification) async {
    if (!_ready) {
      await initInventoryNotificationsInBackground(_plugin);
      _ready = true;
    }
    await _plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: inventoryNotificationDetails(
        notification.actions,
        timeoutAfter: notification.timeoutAfterMs,
        onlyAlertOnce: true,
        bigText: notification.body,
      ),
      payload: notification.payload,
    );
  }
}

/// Vòng đời notification sau khi bấm (A6, S1–S8; S0 dựng riêng).
enum QuickActionState {
  applied, // S1
  noOp, // S2
  gone, // S3
  readonly, // S4
  noHousehold, // S5
  authFail, // S6
  network, // S7
  other, // S8
}

class QuickActionOutcome {
  const QuickActionOutcome(this.state, {this.transactionReason});

  final QuickActionState state;
  final String? transactionReason;

  /// Cache máy có thể lệch server ⇒ đặt cờ pending-sync ở S1/S2/S3.
  bool get setsPendingSync =>
      state == QuickActionState.applied ||
      state == QuickActionState.noOp ||
      state == QuickActionState.gone;
}

/// Lõi quick-action chạy nền (A3/A4): refresh-first rồi gọi, ngân sách 9 s,
/// không GetX/MobX/Drift (Guard 18), không queue (Guard 20).
class QuickActionBackgroundRunner {
  QuickActionBackgroundRunner({
    required Dio dio,
    required TokenStorage tokenStorage,
    required CrossIsolateLock lock,
    required BgFiles files,
    required QuickActionNotificationPresenter presenter,
    required AppLocalizations l10n,
    void Function()? pingCatchUp,
    this.deadline = const Duration(seconds: 9),
    this.lockWait = const Duration(seconds: 3),
    this.stepBudget = const Duration(seconds: 3),
  })  : _dio = dio,
        _gate = RefreshGate(lock: lock, tokenStorage: tokenStorage),
        _files = files,
        _presenter = presenter,
        _l10n = l10n,
        _pingCatchUp = pingCatchUp ?? pingInventoryCatchUp;

  factory QuickActionBackgroundRunner.production() {
    final dio = Dio(BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 3),
      contentType: Headers.jsonContentType,
    ));
    // Chỉ ErrorMappingInterceptor (thuần, không GetX) — KHÔNG DioClient.build().
    dio.interceptors.add(ErrorMappingInterceptor());
    // Demo: adapter là instance riêng của isolate nền (giới hạn đã biết, A3).
    if (EnvConfig.isDemoMode) dio.httpClientAdapter = DemoBackendAdapter();
    final files = BgFiles.production();
    final locale = PlatformDispatcher.instance.locale;
    return QuickActionBackgroundRunner(
      dio: dio,
      // FlutterSecureStorage MẶC ĐỊNH y như UI isolate (khác option = kho khác).
      tokenStorage: TokenStorage(),
      lock: FileLeaseLock(directory: files.directory),
      files: files,
      presenter: PluginQuickActionPresenter(),
      l10n: lookupAppLocalizations(
        locale.languageCode == 'vi' ? const Locale('vi') : const Locale('en'),
      ),
    );
  }

  /// t0 + 9 s (chừa 1 s cho lần cập nhật notification cuối — A4).
  final Duration deadline;
  final Duration lockWait;
  final Duration stepBudget;

  final Dio _dio;
  final RefreshGate _gate;
  final BgFiles _files;
  final QuickActionNotificationPresenter _presenter;
  final AppLocalizations _l10n;
  final void Function() _pingCatchUp;

  Future<void> handle(NotificationResponse response) async {
    final action = response.actionId;
    if (action == null || !isBackgroundQuickAction(action)) return;
    final interaction = decodeNotificationInteraction(response.payload);
    if (interaction == null) return;
    final watch = Stopwatch()..start();
    final payload = FcmActionPayload.tryParse(interaction.data);
    final itemId = payload?.actionItemId;
    if (itemId == null || itemId.isEmpty) {
      await _present(
        interaction,
        payload,
        response.payload!,
        const QuickActionOutcome(QuickActionState.other),
      );
      return;
    }

    InFlightGuard? guard;
    try {
      guard = await _files.tryAcquireInFlight(itemId: itemId, action: action);
      // Lần bấm khác cùng item đang chạy ⇒ thoát: 0 request, không đổi
      // notification (A7, Guard 27).
      if (guard == null) return;
    } catch (error) {
      // File system lỗi: vẫn chạy (lớp S0 không nút vẫn chặn bấm lần 2).
      developer.log('In-flight guard unavailable: $error', name: 'FCM');
    }
    try {
      // S0 TRƯỚC mọi I/O mạng — không nút, không tự ẩn (F6).
      await _presenter.show(QuickActionNotification(
        id: interaction.notificationId,
        title: _title(interaction, payload),
        body: _l10n.notificationQuickActionProcessing,
        actions: const <FcmNotificationAction>[],
        payload: response.payload!,
      ));
      final outcome = await _execute(itemId, action, watch);
      if (outcome.setsPendingSync) await _markPendingSync();
      await _present(
        interaction,
        payload,
        response.payload!,
        outcome,
        itemId: itemId,
      );
    } finally {
      await guard?.release();
    }
  }

  Duration _remaining(Stopwatch watch) => deadline - watch.elapsed;

  Duration _min(Duration a, Duration b) => a < b ? a : b;

  Future<QuickActionOutcome> _execute(
    String itemId,
    String action,
    Stopwatch watch,
  ) async {
    var remaining = _remaining(watch);
    if (remaining <= Duration.zero) {
      return const QuickActionOutcome(QuickActionState.network);
    }
    // Refresh-first: isolate nền không có access token (D6 — chỉ in-memory).
    final gate = await _gate.run(
      wait: _min(lockWait, remaining),
      budget: _min(stepBudget, remaining),
      refresh: (refreshToken, options, cancelToken) =>
          AuthRefreshUseCase(_dio).call(
        refreshToken,
        options: options,
        cancelToken: cancelToken,
      ),
    );
    switch (gate.outcome) {
      case RefreshOutcome.lockTimeout:
        return const QuickActionOutcome(QuickActionState.network);
      case RefreshOutcome.rejected:
        return const QuickActionOutcome(QuickActionState.authFail);
      case RefreshOutcome.failed:
        return QuickActionOutcome(
          _isNetworkFailure(gate.error)
              ? QuickActionState.network
              : QuickActionState.other,
        );
      case RefreshOutcome.refreshed:
        break;
    }

    remaining = _remaining(watch);
    if (remaining <= Duration.zero) {
      return const QuickActionOutcome(QuickActionState.network);
    }
    final budget = _min(stepBudget, remaining);
    final cancelToken = CancelToken();
    final timer =
        Timer(budget, () => cancelToken.cancel('quick-action budget'));
    try {
      final result = await QuickActionApiImpl.withDio(_dio).apply(
        itemId: itemId,
        action: action,
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer ${gate.tokens!.accessToken}',
          },
          connectTimeout: budget,
          sendTimeout: budget,
          receiveTimeout: budget,
        ),
        cancelToken: cancelToken,
      );
      return result.applied
          ? const QuickActionOutcome(QuickActionState.applied)
          : QuickActionOutcome(
              QuickActionState.noOp,
              transactionReason: result.transactionReason,
            );
    } on AuthExpiredException {
      // 401 sau refresh ⇒ auth-fail, KHÔNG refresh lần 2.
      return const QuickActionOutcome(QuickActionState.authFail);
    } on BusinessException catch (error) {
      return QuickActionOutcome(switch (error.code) {
        'ERR_INVENTORY_NOT_FOUND' => QuickActionState.gone,
        'ERR_INVENTORY_READONLY_ROLE' => QuickActionState.readonly,
        'ERR_INVENTORY_NO_HOUSEHOLD' => QuickActionState.noHousehold,
        _ => QuickActionState.other,
      });
    } on NetworkException {
      return const QuickActionOutcome(QuickActionState.network);
    } on ServerException catch (error) {
      // 5xx ⇒ mạng; ERR_UNKNOWN = envelope/response lạ phía client ⇒ lỗi khác.
      if (cancelToken.isCancelled) {
        return const QuickActionOutcome(QuickActionState.network);
      }
      return QuickActionOutcome(error.code == 'ERR_UNKNOWN'
          ? QuickActionState.other
          : QuickActionState.network);
    } catch (_) {
      return QuickActionOutcome(cancelToken.isCancelled
          ? QuickActionState.network
          : QuickActionState.other);
    } finally {
      timer.cancel();
    }
  }

  bool _isNetworkFailure(Object? error) {
    // Đọc storage quá budget (không có lỗi) ⇒ hết thời gian ⇒ mạng.
    if (error == null) return true;
    if (error is! DioException) return false;
    if (error.type == DioExceptionType.cancel ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    final mapped = error.error;
    return mapped is NetworkException ||
        (mapped is ServerException && mapped.code != 'ERR_UNKNOWN');
  }

  Future<void> _markPendingSync() async {
    try {
      await _files.markInventoryPendingSync();
      _pingCatchUp();
    } catch (error) {
      developer.log('Pending-sync flag failed: $error', name: 'FCM');
    }
  }

  String? _title(NotificationInteraction interaction, FcmActionPayload? p) =>
      interaction.title ?? p?.title;

  Future<void> _present(
    NotificationInteraction interaction,
    FcmActionPayload? payload,
    String rawPayload,
    QuickActionOutcome outcome, {
    String? itemId,
  }) {
    final title = _title(interaction, payload);
    final originalBody = interaction.body ?? payload?.body ?? '';
    final originalActions = payload?.actions ?? const <FcmNotificationAction>[];
    QuickActionNotification build(
      String body, {
      List<FcmNotificationAction> actions = const <FcmNotificationAction>[],
      int? timeoutAfterMs,
      String? payloadOverride,
    }) =>
        QuickActionNotification(
          id: interaction.notificationId,
          title: title,
          body: body,
          actions: actions,
          payload: payloadOverride ?? rawPayload,
          timeoutAfterMs: timeoutAfterMs,
        );
    String withLine(String line) =>
        originalBody.isEmpty ? line : '$originalBody\n$line';

    final notification = switch (outcome.state) {
      QuickActionState.applied =>
        build(_l10n.notificationInventoryUpdated, timeoutAfterMs: 4000),
      QuickActionState.noOp => build(
          switch (outcome.transactionReason) {
            'COOKED' => _l10n.notificationInventoryAlreadyUsed,
            'WASTE' => _l10n.notificationInventoryAlreadyDiscarded,
            // Nhánh mặc định BẮT BUỘC: CORRECTED/EXPIRED/BOUGHT/lạ/null.
            _ => _l10n.notificationInventoryAlreadyProcessed,
          },
          timeoutAfterMs: 4000,
        ),
      QuickActionState.gone =>
        build(_l10n.notificationInventoryGone, timeoutAfterMs: 4000),
      QuickActionState.readonly => build(_l10n.notificationInventoryReadonly),
      QuickActionState.noHousehold => build(
          _l10n.notificationQuickActionOpenApp,
          payloadOverride: _deepLinkPayload(interaction, itemId),
        ),
      QuickActionState.authFail => build(
          _l10n.notificationQuickActionSessionExpired,
          payloadOverride: _deepLinkPayload(interaction, itemId),
        ),
      QuickActionState.network => build(
          withLine(_l10n.notificationNoNetwork),
          actions: originalActions,
        ),
      QuickActionState.other => build(
          withLine(_l10n.notificationQuickActionRetry),
          actions: originalActions,
        ),
    };
    return _presenter.show(notification);
  }

  /// S5/S6: Android 10+ không mở activity từ nền ⇒ chạm thân đi đường tap có
  /// sẵn tới list Tồn kho. `item` chỉ là thông tin (Q-E2: target không mang
  /// tham số).
  String _deepLinkPayload(NotificationInteraction interaction, String? itemId) {
    final data = Map<String, dynamic>.from(interaction.data)
      ..['deepLink'] = itemId == null
          ? 'smartkitchen://inventory'
          : 'smartkitchen://inventory?item=${Uri.encodeQueryComponent(itemId)}';
    return encodeNotificationInteraction(
      data,
      interaction.notificationId,
      messageId: interaction.messageId,
      title: interaction.title,
      body: interaction.body,
    );
  }
}
