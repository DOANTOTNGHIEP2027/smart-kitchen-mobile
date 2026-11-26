import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_health_profile_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_summary.dart';

import '../../helpers/secure_storage_channel.dart';
import 'dependent_test_fakes.dart';

/// #125 §16.14 — DependentHealthProfileScreen (S-D1..S-D8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(() {
    storage.uninstall();
    Get.reset();
  });
  final l = lookupAppLocalizations(const Locale('vi'));

  Future<DepFixture> pumpHealth(
    WidgetTester tester, {
    String role = 'OWNER',
    DependentSummary? d,
    void Function(DepFixture f)? arrange,
  }) async {
    final f = await makeDepFixture(role: role, register: true);
    f.api.items = <DependentSummary>[d ?? dep('d1')];
    f.api.health['d1'] = depHealth('d1');
    arrange?.call(f);
    await pumpDependentScreen(
        tester, const DependentHealthProfileScreen(dependentId: 'd1'),
        pages: <GetPage<dynamic>>[
          GetPage<dynamic>(
              name: AppRoutes.dependents,
              page: () => const Scaffold(body: Text('list-page'))),
        ]);
    return f;
  }

  testWidgets('cold deep-link: detail Loading → gọi getDependent TRƯỚC health, rồi hiện view', (tester) async {
    final f = await pumpHealth(tester);
    expect(f.api.calls.first, 'get:d1');
    expect(f.api.calls, contains('health:d1'));
    expect(f.api.calls.indexOf('get:d1'), lessThan(f.api.calls.indexOf('health:d1')));
    expect(find.text(l.dependentHealthTitle('Bé Bo')), findsOneWidget);
    expect(byKey('dependent-health-edit'), findsOneWidget);
  });

  testWidgets('S-D8: guard fail (MEMBER không phải guardian) → Blocked, getHealthProfile KHÔNG gọi', (tester) async {
    final f = await pumpHealth(tester, role: 'MEMBER', d: dep('d1', guardian: 'a'));
    expect(byKey('dependent-health-blocked'), findsOneWidget);
    expect(find.text(l.dependentNoAccessHealth), findsOneWidget);
    expect(f.api.count('health:'), 0);
  });

  testWidgets('S-D8: guardian !guardianActive cũng bị chặn', (tester) async {
    final f = await pumpHealth(tester, role: 'MEMBER', d: dep('d1', guardian: 'me', active: false));
    expect(byKey('dependent-health-blocked'), findsOneWidget);
    expect(f.api.count('health:'), 0);
  });

  testWidgets('Guard 6: lưu gửi đủ 4 key (null tường minh) → về view + toast', (tester) async {
    final f = await pumpHealth(tester);
    await tester.tap(byKey('dependent-health-edit'));
    await tester.pumpAndSettle();
    expect(find.text(l.healthProfileEditTitle), findsWidgets);
    await tester.enterText(byKey('health-weight'), '');
    await tester.enterText(byKey('health-height'), '112');
    await tester.tap(byKey('health-save'));
    await tester.pumpAndSettle();
    final payload = f.api.healthWrites.single;
    expect(payload.keys, unorderedEquals(<String>['targetDailyCalories', 'dietType', 'heightCm', 'weightKg']));
    expect(payload['targetDailyCalories'], 1400); // không chạm slider → giữ nguyên
    expect(payload['dietType'], 'VEGETARIAN');
    expect(payload['heightCm'], 112.0);
    expect(payload['weightKg'], isNull);
    expect(find.text(l.healthSavedToast), findsOneWidget);
    expect(byKey('dependent-health-edit'), findsOneWidget);
  });

  testWidgets('S-D5: fieldErrors.heightCm → lỗi inline dưới ô chiều cao, giữ giá trị', (tester) async {
    final f = await pumpHealth(tester);
    f.api.healthWriteError = ValidationException('ERR_VALIDATION_FAILED', 'invalid',
        fieldErrors: <String, String>{'heightCm': 'must be <= 300'});
    await tester.tap(byKey('dependent-health-edit'));
    await tester.pumpAndSettle();
    await tester.enterText(byKey('health-height'), '250');
    await tester.tap(byKey('health-save'));
    await tester.pumpAndSettle();
    expect(find.text(l.healthProfileHeightInvalid), findsOneWidget);
    expect(find.textContaining('must be'), findsNothing); // không in message BE
    expect(find.text('250'), findsOneWidget);
  });

  testWidgets('HIGH-1: dietType lạ → không có nút Chỉnh sửa, hiện ghi chú', (tester) async {
    await pumpHealth(tester, arrange: (f) => f.api.health['d1'] = depHealth('d1', dietRaw: 'PALEO'));
    expect(byKey('dependent-health-unknown-diet'), findsOneWidget);
    expect(byKey('dependent-health-edit'), findsNothing);
    expect(find.text(l.healthProfileDietUnset), findsOneWidget);
  });

  testWidgets('S-D2: hồ sơ trống → "Chưa thiết lập" + CTA thiết lập; dị ứng [] vẫn hiện chip mờ', (tester) async {
    await pumpHealth(tester, arrange: (f) => f.api.health.remove('d1'));
    expect(byKey('dependent-health-empty'), findsOneWidget);
    expect(byKey('dependent-health-setup'), findsOneWidget);
    expect(find.text('Chưa ghi nhận dị ứng'), findsOneWidget);
  });

  testWidgets('S-D7: lỗi mạng khi tải → AppErrorView + thử lại', (tester) async {
    final f = await pumpHealth(tester, arrange: (f) => f.api.healthReadError = NetworkException());
    expect(find.text(l.networkError), findsOneWidget);
    f.api.healthReadError = null;
    await tester.tap(find.text(l.commonRetry));
    await tester.pump();
    await tester.pump();
    expect(byKey('dependent-health-edit'), findsOneWidget);
  });

  testWidgets('L3: mở khi health của detail đang bay → KHÔNG GET trùng', (tester) async {
    final f = await makeDepFixture(register: true);
    f.api.items = <DependentSummary>[dep('d1')];
    f.api.health['d1'] = depHealth('d1');
    final gate = Completer<void>();
    f.api.healthReadGate = gate;
    final load = f.store.loadDependentDetail('d1');
    await tester.pump();
    await pumpDependentScreen(
        tester, const DependentHealthProfileScreen(dependentId: 'd1'));
    gate.complete();
    await load;
    await tester.pumpAndSettle();
    expect(f.api.count('health:d1'), 1);
    expect(byKey('dependent-health-edit'), findsOneWidget);
  });

  testWidgets('L7: lưu → 403 ERR_DEP_002 + guardian mất quyền → màn chuyển Blocked', (tester) async {
    final f = await pumpHealth(tester, role: 'MEMBER', d: dep('d1', guardian: 'me'));
    await tester.tap(byKey('dependent-health-edit'));
    await tester.pumpAndSettle();
    f.api.items = <DependentSummary>[dep('d1', guardian: 'me', active: false)];
    f.api.healthWriteError = BusinessException('ERR_DEP_002', 'forbidden');
    await tester.tap(byKey('health-save'));
    await tester.pumpAndSettle();
    expect(byKey('dependent-health-blocked'), findsOneWidget);
    expect(byKey('health-save'), findsNothing);
  });

  testWidgets('L7: lưu → 404 ERR_DEP_001 → về danh sách + toast', (tester) async {
    final f = await pumpHealth(tester);
    await tester.tap(byKey('dependent-health-edit'));
    await tester.pumpAndSettle();
    f.api.healthWriteError = BusinessException('ERR_DEP_001', 'gone');
    await tester.tap(byKey('health-save'));
    await tester.pumpAndSettle();
    expect(find.text('list-page'), findsOneWidget);
    expect(find.text(l.dependentNotFoundTitle), findsOneWidget);
  });
}
