import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/scenes/profile/member_detail_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/family_store.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/secure_storage_channel.dart';
import 'family_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  late AppDatabase db;
  late FakeHealthApi health;

  setUp(() {
    storageChannel.install();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    health = FakeHealthApi();
    Get.put<FamilyStore>(FamilyStore(
      FakeFamilyApi(),
      health,
      ReadCacheDao(db),
      SessionStore(
        TokenStorage(),
        AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
      ),
    ));
  });
  tearDown(() async {
    storageChannel.uninstall();
    await db.close();
    Get.reset();
  });

  Finder key(String k) => find.byKey(ValueKey<String>(k));

  testWidgets('403 ERR_HEALTH_FORBIDDEN → copy l10n, KHÔNG có Thử lại (S12.12)',
      (tester) async {
    health.summaryError =
        BusinessException('ERR_HEALTH_FORBIDDEN', 'Insufficient permissions');
    await tester.pumpAppWidget(const MemberDetailScreen(userId: 'a'),
        wrapInScaffold: false);
    await tester.pumpAndSettle();
    expect(
        find.text('Bạn không có quyền xem hồ sơ sức khỏe của thành viên này.'),
        findsOneWidget);
    expect(find.textContaining('Insufficient'), findsNothing);
    expect(find.text('Thử lại'), findsNothing);
    expect(find.byType(AppErrorView), findsNothing);
    expect(key('member-detail-close'), findsOneWidget);
    expect(health.summaryReads, <String>['a']);
  });

  testWidgets('thiếu userId → lỗi tại chỗ, KHÔNG gọi API', (tester) async {
    await tester.pumpAppWidget(const MemberDetailScreen(),
        wrapInScaffold: false);
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy thành viên này.'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
    expect(health.summaryReads, isEmpty);
  });

  testWidgets('thành công → ghi chú riêng tư; empty diet/dị ứng có nhãn',
      (tester) async {
    await tester.pumpAppWidget(const MemberDetailScreen(userId: 'a'),
        wrapInScaffold: false);
    await tester.pumpAndSettle();
    expect(key('member-privacy-note'), findsOneWidget);
    expect(find.text('Chưa có mục dị ứng được lưu'), findsOneWidget);
  });
}
