import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/monthly_recap_api.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/monthly_recap_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/monthly_recap_summary.dart';
import 'package:smart_kitchen_mobile/scenes/recap/stores/monthly_recap_store.dart';
import 'package:smart_kitchen_mobile/scenes/recap/stores/weekly_recap_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import 'monthly_recap_mapper_test.dart' show monthlyJson;

/// API giả: trả tổng kết cho tháng được hỏi; `earliest` quyết `hasPrevious`.
class FakeMonthlyRecapApi implements MonthlyRecapApi {
  FakeMonthlyRecapApi({required this.current, required this.earliest});

  final DateTime current;
  final DateTime earliest;
  final List<DateTime?> calls = <DateTime?>[];
  Object? error;

  /// Ghi đè field payload (vd. gói FREE: spendByCategory null).
  Map<String, dynamic> extra = const <String, dynamic>{};

  /// Nếu đặt, lần gọi tiếp theo chờ completer này (giả lập mạng chậm).
  Completer<void>? gate;

  static MonthlyRecapSummary build(DateTime month,
      {required bool hasPrevious, Map<String, dynamic> extra = const {}}) {
    return MonthlyRecapMapper.summaryFromJson(monthlyJson(<String, dynamic>{
      'month': MonthlyRecapMapper.formatMonth(month),
      'hasPrevious': hasPrevious,
      ...extra,
    }));
  }

  @override
  Future<MonthlyRecapSummary> getMonthlyRecap({DateTime? month}) async {
    calls.add(month);
    final g = gate;
    if (g != null) {
      gate = null;
      await g.future;
    }
    final e = error;
    if (e != null) throw e;
    final target = month ?? current;
    return build(target, hasPrevious: target.isAfter(earliest), extra: extra);
  }
}

SessionStore makeSession({String? householdId = 'h1', String? tier}) {
  final s = SessionStore(
    TokenStorage(),
    AuthRefreshUseCase(
      Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = FakeHttpAdapter(
          (_) async => jsonResponse(200, successEnvelope(null)),
        ),
    ),
  );
  s.currentUser = const UserSummary(id: 'self', fullName: 'Me');
  if (householdId != null) {
    s.applyRefreshedClaims(fakeJwt(<String, dynamic>{
      'sub': 'self',
      'household_id': householdId,
      'role': 'OWNER',
      if (tier != null) 'tier': tier,
    }));
  }
  return s;
}

void main() {
  final today = DateTime(2026, 11, 28);
  late FakeMonthlyRecapApi api;

  MonthlyRecapStore makeStore({SessionStore? session}) => MonthlyRecapStore(
        api,
        session ?? makeSession(),
        now: () => today,
      );

  setUp(() {
    api = FakeMonthlyRecapApi(
      current: DateTime(2026, 11),
      earliest: DateTime(2026, 9),
    );
  });

  test('tải tháng hiện tại: không gửi month, ready, ownInsight khớp self',
      () async {
    final store = makeStore();
    await store.loadCurrentMonth();

    expect(api.calls, <DateTime?>[null]);
    expect(store.status, MonthlyRecapStatus.ready);
    expect(store.month, DateTime(2026, 11));
    expect(store.isCurrentMonth, isTrue);
    expect(store.canGoNext, isFalse);
    expect(store.canGoPrevious, isTrue);
    expect(store.ownInsight!.memberId, 'self');
    expect(store.ownInsight!.weeks, hasLength(1));
    expect(store.canSetBudget, isTrue);
  });

  test(
      'lùi tháng tới khi hasPrevious=false thì nút trước tắt; tiến lại tháng '
      'hiện tại không gửi month', () async {
    final store = makeStore();
    await store.loadCurrentMonth();

    await store.previousMonth();
    expect(store.month, DateTime(2026, 10));
    expect(api.calls.last, DateTime(2026, 10));
    expect(store.canGoNext, isTrue);
    expect(store.canGoPrevious, isTrue);

    await store.previousMonth();
    expect(store.month, DateTime(2026, 9));
    expect(store.canGoPrevious, isFalse);

    // Bị chặn: không gọi thêm API.
    final before = api.calls.length;
    await store.previousMonth();
    expect(api.calls.length, before);
    expect(store.month, DateTime(2026, 9));

    await store.nextMonth();
    expect(store.month, DateTime(2026, 10));
    expect(api.calls.last, DateTime(2026, 10));

    await store.nextMonth();
    expect(store.month, DateTime(2026, 11));
    expect(api.calls.last, isNull);
    expect(store.canGoNext, isFalse);

    final atCurrent = api.calls.length;
    await store.nextMonth();
    expect(api.calls.length, atCurrent, reason: 'không xem tháng tương lai');
  });

  test('lỗi mạng → error (không kẹt loading), retry tải lại được', () async {
    api.error = NetworkException();
    final store = makeStore();
    await store.loadCurrentMonth();

    expect(store.status, MonthlyRecapStatus.error);
    expect(store.error!.code, 'ERR_NETWORK');
    expect(store.summary, isNull);
    expect(store.canGoPrevious, isFalse);

    api.error = null;
    store.retry();
    await pumpEventQueue();
    expect(store.status, MonthlyRecapStatus.ready);
    expect(store.error, isNull);
  });

  test('lỗi parse (không phải ApiException) → error với error=null', () async {
    api.error = const FormatException('hỏng');
    final store = makeStore();
    await store.loadCurrentMonth();
    expect(store.status, MonthlyRecapStatus.error);
    expect(store.error, isNull);
  });

  test('400 ERR_RECAP_MONTH_INVALID → error giữ code; 403 → noHousehold',
      () async {
    api.error = BusinessException('ERR_RECAP_MONTH_INVALID', 'invalid');
    final store = makeStore();
    await store.loadCurrentMonth();
    expect(store.status, MonthlyRecapStatus.error);
    expect(store.error!.code, 'ERR_RECAP_MONTH_INVALID');

    api.error = BusinessException('ERR_RECAP_NO_HOUSEHOLD', 'no household');
    await store.reload();
    expect(store.status, MonthlyRecapStatus.noHousehold);
  });

  test('chưa có hộ → noHousehold, KHÔNG gọi API', () async {
    final store = makeStore(session: makeSession(householdId: null));
    await store.loadCurrentMonth();
    expect(store.status, MonthlyRecapStatus.noHousehold);
    expect(api.calls, isEmpty);
  });

  test('phản hồi cũ về sau bị bỏ qua khi đã chuyển tháng', () async {
    final store = makeStore();
    await store.loadCurrentMonth();

    final slow = Completer<void>();
    api.gate = slow;
    final first = store.previousMonth(); // tháng 10, bị treo
    // Trong lúc đang tải, nút điều hướng tắt.
    expect(store.status, MonthlyRecapStatus.loading);
    expect(store.canGoNext, isFalse);
    expect(store.canGoPrevious, isFalse);

    await store.reload(); // tải lại tháng 10, về trước
    slow.complete();
    await first;
    expect(store.status, MonthlyRecapStatus.ready);
    expect(store.month, DateTime(2026, 10));
  });

  test('gói FREE (spendByCategory null) → upsell; PREMIUM claim → neutral',
      () async {
    final store = makeStore();
    await store.loadCurrentMonth();
    expect(store.spendDetailGate, SpendDetailGate.unlocked);

    api.extra = <String, dynamic>{'spendByCategory': null, 'spendTrend': null};
    final free =
        MonthlyRecapStore(api, makeSession(tier: 'FREE'), now: () => today);
    await free.loadCurrentMonth();
    expect(free.spendDetailGate, SpendDetailGate.lockedUpsell);

    final premium =
        MonthlyRecapStore(api, makeSession(tier: 'PREMIUM'), now: () => today);
    await premium.loadCurrentMonth();
    expect(premium.spendDetailGate, SpendDetailGate.lockedNeutral);
  });
}
