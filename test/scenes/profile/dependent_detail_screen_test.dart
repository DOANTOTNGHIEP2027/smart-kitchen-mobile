import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/profile/dependent_detail_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/dependent_summary.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';

import '../../helpers/secure_storage_channel.dart';
import 'dependent_test_fakes.dart';
import 'family_test_fakes.dart' as ff;

/// #125 §16.14 — DependentDetailScreen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FakeSecureStorageChannel();
  setUp(storage.install);
  tearDown(() {
    storage.uninstall();
    Get.reset();
  });
  final l = lookupAppLocalizations(const Locale('vi'));

  final listPage = GetPage<dynamic>(
      name: AppRoutes.dependents,
      page: () => const Scaffold(body: Text('list-page')));

  Future<DepFixture> pumpDetail(
    WidgetTester tester, {
    String role = 'OWNER',
    DependentSummary? d,
    List<HouseholdMember>? members,
    void Function(DepFixture f)? arrange,
  }) async {
    final f = await makeDepFixture(role: role, members: members, register: true);
    f.api.items = <DependentSummary>[d ?? dep('d1')];
    f.api.health['d1'] = depHealth('d1');
    arrange?.call(f);
    await pumpDependentScreen(tester, const DependentDetailScreen(dependentId: 'd1'),
        pages: <GetPage<dynamic>>[listPage]);
    return f;
  }

  testWidgets('Loading trước khi có dữ liệu (title = Người phụ thuộc)', (tester) async {
    final gate = Completer<void>();
    await pumpDetail(tester, arrange: (f) => f.api.getGates['d1'] = gate);
    expect(find.byType(AppLoadingView), findsOneWidget);
    expect(find.text(l.dependentListTitle), findsOneWidget);
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppLoadingView), findsNothing);
  });

  testWidgets('404 ERR_DEP_001 → not-found + nút về danh sách (không màn đen)', (tester) async {
    await pumpDetail(tester, arrange: (f) => f.api.items = <DependentSummary>[]);
    expect(byKey('dependent-not-found'), findsOneWidget);
    expect(find.text(l.dependentNotFoundBody), findsOneWidget);
    await tester.tap(byKey('dependent-back-to-list'));
    await tester.pumpAndSettle();
    expect(find.text('list-page'), findsOneWidget);
  });

  testWidgets('banner !guardianActive KHÔNG chặn nội dung; OWNER thấy hint + health + nút sửa (D2/L8)', (tester) async {
    await pumpDetail(tester, d: dep('d1', guardian: 'gone-user-123', active: false));
    expect(byKey('dependent-guardian-inactive-banner'), findsOneWidget);
    expect(find.text(l.dependentGuardianInactiveBanner), findsOneWidget);
    expect(byKey('dependent-guardian-owner-hint'), findsOneWidget);
    expect(byKey('dependent-summary'), findsOneWidget);
    expect(byKey('dependent-health-calories'), findsOneWidget);
    expect(byKey('dependent-edit-health'), findsOneWidget);
    expect(byKey('dependent-edit-allergens'), findsOneWidget);
  });

  testWidgets('MEDIUM-1: allergens [] → "Chưa ghi nhận dị ứng", KHÔNG "Không có dị ứng"', (tester) async {
    await pumpDetail(tester);
    expect(find.text('Chưa ghi nhận dị ứng'), findsOneWidget);
    expect(find.text('Không có dị ứng'), findsNothing);
  });

  testWidgets('MEDIUM-4: health ErrorState → khối lỗi + Thử lại, không có nút sửa; summary vẫn hiện', (tester) async {
    final f = await pumpDetail(tester,
        arrange: (f) => f.api.healthReadError = NetworkException());
    expect(byKey('dependent-health-error'), findsOneWidget);
    expect(byKey('dependent-edit-health'), findsNothing);
    expect(byKey('dependent-summary'), findsOneWidget);
    f.api.healthReadError = null;
    await tester.tap(byKey('dependent-health-retry'));
    await tester.pump();
    await tester.pump();
    expect(byKey('dependent-edit-health'), findsOneWidget);
  });

  group('Tên guardian (§16.3) — không throw khi roster thiếu', () {
    testWidgets('active + là mình → "{name} (bạn)"', (tester) async {
      await pumpDetail(tester, d: dep('d1', guardian: 'me'));
      expect(find.text(l.dependentGuardianYou('Người me')), findsOneWidget);
      expect(find.text(l.dependentGuardianCurrent), findsOneWidget);
    });

    testWidgets('active + không có trong roster → id rút gọn', (tester) async {
      await pumpDetail(tester, d: dep('d1', guardian: '7f3a9c21-0000-1111'));
      expect(find.text('7f3a9c21…'), findsOneWidget);
    });

    testWidgets('inactive + còn trong roster (bị hạ RV) → tên + "Không còn quyền quản lý"', (tester) async {
      await pumpDetail(tester, d: dep('d1', guardian: 'v', active: false));
      expect(find.text('Người v'), findsOneWidget);
      expect(find.text(l.dependentGuardianNoManage), findsOneWidget);
    });

    testWidgets('inactive + không có trong roster, id ngắn < 8 (L5) → id + "Đã rời gia đình"', (tester) async {
      await pumpDetail(tester, d: dep('d1', guardian: 'abc', active: false));
      expect(find.text('abc'), findsOneWidget);
      expect(find.text(l.dependentGuardianLeft), findsOneWidget);
    });
  });

  group('Quyền (KHÔNG render, không chỉ disabled)', () {
    testWidgets('OWNER: đổi guardian + xoá', (tester) async {
      await pumpDetail(tester);
      expect(byKey('dependent-change-guardian'), findsOneWidget);
      expect(byKey('dependent-delete'), findsOneWidget);
    });

    testWidgets('MEMBER là guardian: sửa health được, KHÔNG đổi guardian/xoá (Guard 10)', (tester) async {
      await pumpDetail(tester, role: 'MEMBER', d: dep('d1', guardian: 'me'));
      expect(byKey('dependent-edit-health'), findsOneWidget);
      expect(byKey('dependent-change-guardian'), findsNothing);
      expect(byKey('dependent-delete'), findsNothing);
    });

    testWidgets('MEMBER không phải guardian: ghi chú hạn chế, KHÔNG gọi health-profile (Guard 2)', (tester) async {
      final f = await pumpDetail(tester, role: 'MEMBER', d: dep('d1', guardian: 'a'));
      expect(byKey('dependent-health-restricted'), findsOneWidget);
      expect(f.api.count('health:'), 0);
    });

    testWidgets('REMOTE_VIEWER: chỉ summary + ghi chú', (tester) async {
      final f = await pumpDetail(tester, role: 'REMOTE_VIEWER', d: dep('d1', guardian: 'me'));
      expect(byKey('dependent-summary'), findsOneWidget);
      expect(byKey('dependent-health-restricted'), findsOneWidget);
      expect(byKey('dependent-edit-health'), findsNothing);
      expect(byKey('dependent-change-guardian'), findsNothing);
      expect(byKey('dependent-delete'), findsNothing);
      expect(f.api.count('health:'), 0);
    });
  });

  group('Xoá', () {
    testWidgets('xác nhận nêu tên → thành công: về danh sách + toast', (tester) async {
      final f = await pumpDetail(tester);
      await tester.ensureVisible(byKey('dependent-delete'));
      await tester.tap(byKey('dependent-delete'));
      await tester.pumpAndSettle();
      expect(find.text(l.dependentDeleteConfirmTitle('Bé Bo')), findsOneWidget);
      await tester.tap(byKey('dependent-delete-confirm'));
      await tester.pumpAndSettle();
      expect(f.api.count('delete:d1'), 1);
      expect(find.text('list-page'), findsOneWidget);
      expect(find.text(l.dependentDeletedToast), findsOneWidget);
    });

    testWidgets('lỗi xoá → dialog đóng, snackbar, ở lại màn', (tester) async {
      await pumpDetail(tester,
          arrange: (f) => f.api.deleteError = BusinessException('ERR_DEP_006', 'owner only'));
      await tester.ensureVisible(byKey('dependent-delete'));
      await tester.tap(byKey('dependent-delete'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('dependent-delete-confirm'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(l.dependentErrorForbidden), findsOneWidget);
      expect(byKey('dependent-summary'), findsOneWidget);
      expect(find.text('list-page'), findsNothing);
    });

    testWidgets('huỷ → không gọi API', (tester) async {
      final f = await pumpDetail(tester);
      await tester.ensureVisible(byKey('dependent-delete'));
      await tester.tap(byKey('dependent-delete'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('dependent-delete-cancel'));
      await tester.pumpAndSettle();
      expect(f.api.count('delete:'), 0);
    });
  });

  testWidgets('đổi guardian thành công → banner biến mất + toast (G4)', (tester) async {
    await pumpDetail(tester,
        d: dep('d1', guardian: 'gone', active: false),
        members: <HouseholdMember>[ff.member('me', 'OWNER'), ff.member('a', 'MEMBER')]);
    expect(byKey('dependent-guardian-inactive-banner'), findsOneWidget);
    await tester.ensureVisible(byKey('dependent-change-guardian'));
    await tester.tap(byKey('dependent-change-guardian'));
    await tester.pumpAndSettle();
    await tester.tap(byKey('change-guardian-a'));
    await tester.pump();
    await tester.tap(byKey('change-guardian-confirm'));
    await tester.pumpAndSettle();
    expect(byKey('dependent-guardian-inactive-banner'), findsNothing);
    expect(find.text(l.dependentGuardianChangedToast), findsOneWidget);
    expect(find.text('Người a'), findsOneWidget);
  });

  group('Review #125 v1 — M1/L1/L4', () {
    testWidgets('M1: roster tải lỗi → snackbar lỗi, KHÔNG mở sheet / không hiện "không có ai"', (tester) async {
      final f = await makeDepFixture(loadRoster: false, register: true);
      f.familyApi.rosterError = ServerException('ERR_SERVER', 'down');
      f.api.items = <DependentSummary>[dep('d1')];
      await pumpDependentScreen(tester, const DependentDetailScreen(dependentId: 'd1'));
      await tester.ensureVisible(byKey('dependent-change-guardian'));
      await tester.tap(byKey('dependent-change-guardian'));
      await tester.pumpAndSettle();
      expect(byKey('change-guardian-empty'), findsNothing);
      expect(byKey('change-guardian-confirm'), findsNothing);
      expect(find.text(l.genericRetryError), findsOneWidget);
    });

    testWidgets('L1: kéo làm mới giữ nội dung, không spinner toàn màn', (tester) async {
      final f = await pumpDetail(tester);
      final gate = Completer<void>();
      f.api.getGates['d1'] = gate;
      await tester.fling(find.byType(ListView).first, const Offset(0, 500), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(f.api.count('get:d1'), 2);
      expect(byKey('dependent-summary'), findsOneWidget);
      expect(find.byType(AppLoadingView), findsNothing);
      expect(byKey('dependent-health-calories'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(byKey('dependent-summary'), findsOneWidget);
    });

    testWidgets('L4: quyền false → true sau khi detail đã tải → tự nạp health', (tester) async {
      final f = await pumpDetail(tester, role: 'MEMBER', d: dep('d1', guardian: 'a'));
      expect(byKey('dependent-health-restricted'), findsOneWidget);
      expect(f.api.count('health:'), 0);
      f.familyApi.current = ff.roster(callerRole: 'OWNER', members: defaultMembers('OWNER'));
      await f.family.loadRoster(keepCurrent: true);
      await tester.pump();
      await tester.pump();
      expect(f.api.count('health:d1'), 1);
      expect(byKey('dependent-edit-health'), findsOneWidget);
    });
  });
}
