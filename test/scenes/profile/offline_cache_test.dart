import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/diet_type.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/health_profile_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/profile_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/stale_data_banner.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import 'health_test_fakes.dart';

/// Cache-fallback của HealthProfileScreen trên Drift thật (in-memory):
/// mất mạng + có cache → dữ liệu cache + StaleDataBanner (chỉ đọc);
/// mất mạng + không cache → lỗi toàn màn + Thử lại (S10.7).
void main() {
  late AppDatabase db;
  late ReadCacheDao dao;
  late FakeHealthApi api;
  late ProfileStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ReadCacheDao(db);
    api = FakeHealthApi();
    store = putProfileStore(api, dao);
  });
  tearDown(() async {
    Get.reset();
    await db.close();
  });

  /// Drift chạy ở zone thật — cho I/O hoàn tất rồi mới pump.
  Future<void> settleDrift(WidgetTester tester) async {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  testWidgets('mất mạng + có cache Drift → dữ liệu cache + StaleDataBanner',
      (tester) async {
    await tester.runAsync(() => dao.put('health_profile:me',
        healthProfile(goal: 1800, diet: DietType.keto).toJson()));
    api.readError = NetworkException();

    await pumpHealthScreen(tester, const HealthProfileScreen());
    await settleDrift(tester);

    expect(store.healthProfileIsFromCache, isTrue);
    expect(find.byType(StaleDataBanner), findsOneWidget);
    expect(find.text('1800 kcal'), findsOneWidget);
    expect(find.text('Keto'), findsOneWidget);
    expect(find.text('Cần kết nối mạng để chỉnh sửa.'), findsOneWidget);
    expect(find.byType(AppErrorView), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('mất mạng + không có cache → lỗi toàn màn + Thử lại hồi phục',
      (tester) async {
    api.readError = NetworkException();

    await pumpHealthScreen(tester, const HealthProfileScreen());
    await settleDrift(tester);

    expect(store.healthProfileState, isA<ErrorState<HealthProfile>>());
    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.byType(StaleDataBanner), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);

    api.readError = null;
    api.profile = healthProfile(goal: 2100);
    await tester.tap(find.text('Thử lại'));
    await settleDrift(tester);

    expect(find.text('2100 kcal'), findsOneWidget);
    expect(store.healthProfileIsFromCache, isFalse);
    final cached = await tester.runAsync(() => dao.get('health_profile:me'));
    expect(cached!.payload['targetDailyCalories'], 2100);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('lỗi 5xx (không phải mạng) không rơi về cache → ErrorState', () async {
    await dao.put('health_profile:me', healthProfile(goal: 1800).toJson());
    api.readError = ServerException('ERR_INTERNAL', 'down');
    await store.loadHealthProfile();
    expect(store.healthProfileState, isA<ErrorState<HealthProfile>>());
    expect(store.healthProfileIsFromCache, isFalse);
  });
}
