import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import '../stores/realtime_store.dart';

/// Hàm log cùng dạng `developer.log` — tách ra để test kiểm được `name`.
typedef RealtimeStartupLog = void Function(
  String message, {
  String name,
  Object? error,
  StackTrace? stackTrace,
});

/// #93 §5.4 F1 — khởi động realtime SAU frame đầu, không chặn `runApp`.
///
/// - Không await: WS chậm/treo không giữ first frame.
/// - Lỗi của `init()` được log `name: 'bootstrap'`, không ném ra zone.
/// - `RealtimeStore.init()` idempotent nên gọi lặp không nhân đôi reaction.
/// - Không điều hướng: quyết định route vẫn do Splash đọc `SessionStore`.
void startRealtimeAfterFirstFrame(
  RealtimeStore store, {
  RealtimeStartupLog log = developer.log,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      store.init().catchError((Object e, StackTrace st) {
        log('realtimeStore.init lỗi',
            name: 'bootstrap', error: e, stackTrace: st);
      }),
    );
  });
}
