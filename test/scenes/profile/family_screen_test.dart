import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/constants/app_theme.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/routing/app_routes.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_member.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/household_roster.dart';
import 'package:smart_kitchen_mobile/scenes/profile/family_screen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/family_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/household_plan_strip.dart';
import 'package:smart_kitchen_mobile/scenes/profile/widgets/invite_result_sheet.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';
import 'dependent_test_fakes.dart' show FakeDependentApi, dep, registerFakeDependentStore;
import 'family_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  late AppDatabase db;
  String? copied;

  setUp(() {
    storageChannel.install();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    copied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    storageChannel.uninstall();
    await db.close();
    Get.reset();
  });

  SessionStore session(String role) {
    final s = SessionStore(
      TokenStorage(),
      AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))),
    );
    s.currentUser = const UserSummary(id: 'me', fullName: 'Tôi');
    s.applyRefreshedClaims(fakeJwt(<String, dynamic>{
      'sub': 'me',
      'household_id': 'h1',
      'role': role,
    }));
    return s;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Dựng FamilyScreen thật trong GetMaterialApp (redirect ERR_HH_001 cần Get).
  Future<(FamilyStore, FakeFamilyApi)> pumpFamily(
    WidgetTester tester, {
    HouseholdRoster? r,
    void Function(FakeFamilyApi api)? arrange,
    FakeDependentApi? depApi,
  }) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeFamilyApi();
    if (r != null) api.current = r;
    arrange?.call(api);
    final st = FamilyStore(api, FakeHealthApi(), ReadCacheDao(db),
        session(r?.callerRole ?? 'OWNER'));
    Get.put<FamilyStore>(st);
    // #125 MEDIUM-2: FamilyScreen.initState Get.find<DependentStore>().
    registerFakeDependentStore(api: depApi);
    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: '/family',
      getPages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: '/family', page: () => const FamilyScreen()),
        GetPage<dynamic>(
            name: AppRoutes.householdSetup,
            page: () => const Scaffold(body: Text('household-setup-page'))),
      ],
    ));
    await settle(tester);
    return (st, api);
  }

  Finder key(String k) => find.byKey(ValueKey<String>(k));

  AppButton inviteButton(WidgetTester tester) =>
      tester.widget<AppButton>(key('family-invite'));

  final mixed = <HouseholdMember>[
    member('me', 'OWNER'),
    member('a', 'MEMBER', provider: 'GUEST'),
    member('v', 'REMOTE_VIEWER'),
    member('o2', 'OWNER'),
  ];

  testWidgets(
      'OWNER: Mời + Xóa trên dòng người khác; không Xóa dòng mình/OWNER',
      (tester) async {
    await pumpFamily(tester, r: roster(members: mixed));
    expect(inviteButton(tester).onPressed, isNotNull);
    expect(key('member-remove-a'), findsOneWidget);
    expect(key('member-remove-v'), findsOneWidget);
    expect(key('member-remove-me'), findsNothing);
    expect(key('member-remove-o2'), findsNothing);
    // "(bạn)" ở dòng của mình; GUEST → badge "Khách" (không phải chữ GUEST).
    expect(find.text('Người me (bạn)'), findsOneWidget);
    expect(key('member-guest-a'), findsOneWidget);
    expect(find.text('Khách'), findsOneWidget);
    expect(find.text('GUEST'), findsNothing);
    // ChangeRoleSheet (#96) vẫn còn nguyên.
    expect(key('member-change-role-a'), findsOneWidget);
  });

  testWidgets('MEMBER: chỉ đọc — không Mời, không Xóa', (tester) async {
    await pumpFamily(tester, r: roster(callerRole: 'MEMBER', members: mixed));
    expect(key('family-invite'), findsNothing);
    expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
  });

  testWidgets(
      'Xóa: dialog nêu tên → xác nhận → dòng biến mất, không nháy Loading',
      (tester) async {
    final (st, api) = await pumpFamily(tester, r: roster(members: mixed));
    await tester.tap(key('member-remove-a'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa Người a khỏi gia đình?'), findsOneWidget);
    expect(tester.widget<AppButton>(key('family-remove-confirm')).variant,
        AppButtonVariant.destructive);

    api.removeGate = Completer<void>();
    await tester.tap(key('family-remove-confirm'));
    await tester.pump();
    // Đang xoá: dialog còn, nút loading, Huỷ khoá.
    expect(tester.widget<AppButton>(key('family-remove-confirm')).isLoading,
        isTrue);
    expect(tester.widget<TextButton>(key('family-remove-cancel')).onPressed,
        isNull);
    api.removeGate!.complete();
    await settle(tester);
    await tester.pumpAndSettle();

    expect(api.calls, contains('remove:a'));
    expect(find.text('Xóa Người a khỏi gia đình?'), findsNothing);
    expect(find.text('Người a'), findsNothing);
    expect(find.text('Người v'), findsOneWidget);
    expect(find.byType(AppLoadingView), findsNothing);
    expect(find.text('Đã xóa Người a khỏi gia đình.'), findsOneWidget);
    expect(st.inviteStatus.name, 'idle');
  });

  testWidgets(
      'M3 — Xóa: nút khoá suốt lúc nạp lại roster, bấm lần 2 không xoá lại, '
      'không toast lỗi', (tester) async {
    final (_, api) = await pumpFamily(tester, r: roster(members: mixed));
    await tester.tap(key('member-remove-a'));
    await tester.pumpAndSettle();

    api.rosterGate = Completer<void>(); // nạp lại roster sau xoá bị treo
    await tester.tap(key('family-remove-confirm'));
    await settle(tester);

    // BE đã xoá, đang nạp lại: nút vẫn khoá, Huỷ vẫn khoá.
    expect(api.calls.where((c) => c == 'remove:a'), hasLength(1));
    expect(tester.widget<AppButton>(key('family-remove-confirm')).isLoading,
        isTrue);
    expect(tester.widget<TextButton>(key('family-remove-cancel')).onPressed,
        isNull);
    await tester.tap(key('family-remove-confirm'), warnIfMissed: false);
    await tester.pump();

    api.rosterGate!.complete();
    await settle(tester);
    await tester.pumpAndSettle();

    expect(api.calls.where((c) => c.startsWith('remove')), hasLength(1));
    expect(find.text('Xóa Người a khỏi gia đình?'), findsNothing);
    expect(find.text('Đã xóa Người a khỏi gia đình.'), findsOneWidget);
    expect(find.text('Đã có lỗi xảy ra. Vui lòng thử lại'), findsNothing);
  });

  testWidgets('Xóa: Huỷ → không gọi API', (tester) async {
    final (_, api) = await pumpFamily(tester, r: roster(members: mixed));
    await tester.tap(key('member-remove-a'));
    await tester.pumpAndSettle();
    await tester.tap(key('family-remove-cancel'));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
    expect(find.text('Người a'), findsOneWidget);
  });

  testWidgets('Xóa lỗi ERR_HH_007 → toast l10n (không lộ message BE)',
      (tester) async {
    final (_, api) =
        await pumpFamily(tester, r: roster(members: mixed), arrange: (api) {
      api.removeError =
          BusinessException('ERR_HH_007', 'Transfer ownership before leaving');
    });
    final before = api.rosterCalls;
    await tester.tap(key('member-remove-a'));
    await tester.pumpAndSettle();
    await tester.tap(key('family-remove-confirm'));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('Không thể xóa thành viên này.'), findsOneWidget);
    expect(find.textContaining('Transfer ownership'), findsNothing);
    expect(api.rosterCalls, before + 1);
  });

  testWidgets('Mời thành công → InviteResultSheet: QR + mã + link + sao chép',
      (tester) async {
    final (st, api) = await pumpFamily(tester);
    await tester.tap(key('family-invite'));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.byType(InviteResultSheet), findsOneWidget);
    expect(key('invite-qr'), findsOneWidget);
    expect(tester.widget<SelectableText>(key('invite-code')).data,
        api.invite.code);
    expect(tester.widget<SelectableText>(key('invite-link')).data,
        api.invite.link);
    expect(find.textContaining('Hết hạn:'), findsOneWidget);

    await tester.tap(key('invite-copy-link'));
    await tester.pump();
    expect(copied, api.invite.link);
    await tester.tap(key('invite-copy-code'));
    await tester.pump();
    expect(copied, api.invite.code);
    expect(find.text('Đã sao chép'), findsWidgets);

    // Đóng sheet → về idle, lastInvite giữ để mở lại.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(InviteResultSheet), findsNothing);
    expect(st.inviteStatus.name, 'idle');
    await tester.tap(key('family-invite-show-last'));
    await tester.pumpAndSettle();
    expect(find.byType(InviteResultSheet), findsOneWidget);
  });

  testWidgets('Mời 429 ERR_HH_006 → banner giới hạn 3 lời mời', (tester) async {
    await pumpFamily(tester, arrange: (api) {
      api.inviteError = BusinessException(
          'ERR_HH_006', 'Maximum active invite limit reached (3)');
    });
    await tester.tap(key('family-invite'));
    await settle(tester);
    expect(key('family-invite-limit'), findsOneWidget);
    expect(find.byType(InviteResultSheet), findsNothing);
    expect(find.textContaining('Maximum'), findsNothing);
  });

  testWidgets('Roster từ cache → banner + Thử lại; Mời khoá, không có Xóa',
      (tester) async {
    final (st, api) = await pumpFamily(tester, r: roster(members: mixed));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      api.rosterError = NetworkException();
      await st.loadRoster();
    });
    await tester.pump();
    expect(st.rosterIsFromCache, isTrue);
    expect(key('stale-data-retry'), findsOneWidget);
    expect(inviteButton(tester).onPressed, isNull);
    expect(key('family-needs-network'), findsOneWidget);
    expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
  });

  testWidgets('Roster chỉ có mình → empty state + CTA mời', (tester) async {
    await pumpFamily(tester,
        r: roster(members: <HouseholdMember>[member('me', 'OWNER')]));
    expect(key('family-roster-empty'), findsOneWidget);
    expect(find.text('Chưa có thành viên khác.'), findsOneWidget);
    expect(inviteButton(tester).onPressed, isNotNull);
  });

  testWidgets('404 ERR_HH_001 → chuyển tới householdSetup, không AppErrorView',
      (tester) async {
    await pumpFamily(tester, arrange: (api) {
      api.rosterError = BusinessException('ERR_HH_001', 'Household not found');
    });
    await tester.pumpAndSettle();
    expect(find.text('household-setup-page'), findsOneWidget);
    expect(find.byType(AppErrorView), findsNothing);
  });

  group('#125 card "Người phụ thuộc" (§16.7)', () {
    testWidgets('nằm DƯỚI plan strip, TRÊN roster (Guard 12); 0 hồ sơ → "Chưa có hồ sơ nào" + "Thêm hồ sơ"',
        (tester) async {
      await pumpFamily(tester, r: roster(members: mixed));
      final card = tester.getTopLeft(key('family-dependents-card')).dy;
      expect(card, greaterThan(tester.getTopLeft(find.byType(HouseholdPlanStrip)).dy));
      expect(card, lessThan(tester.getTopLeft(find.text('Người a')).dy));
      expect(find.text('Chưa có hồ sơ nào'), findsOneWidget);
      expect(find.text('Thêm hồ sơ'), findsOneWidget);
    });

    testWidgets('N hồ sơ → "{n} hồ sơ" + "Xem tất cả"; OWNER thấy badge cần đổi giám hộ',
        (tester) async {
      final depApi = FakeDependentApi()
        ..items = [dep('d1'), dep('d2', guardian: 'x', active: false)];
      await pumpFamily(tester, depApi: depApi);
      expect(find.text('2 hồ sơ'), findsOneWidget);
      expect(find.text('Xem tất cả'), findsOneWidget);
      expect(key('family-dependents-inactive'), findsOneWidget);
    });

    testWidgets('REMOTE_VIEWER → "Xem", không có "Thêm hồ sơ"', (tester) async {
      await pumpFamily(tester, r: roster(callerRole: 'REMOTE_VIEWER', members: mixed));
      expect(find.text('Xem'), findsOneWidget);
      expect(find.text('Thêm hồ sơ'), findsNothing);
    });

    testWidgets('loading → spinner nhỏ trong card', (tester) async {
      final gate = Completer<void>();
      final depApi = FakeDependentApi()..listGates.add(gate);
      await pumpFamily(tester, depApi: depApi);
      expect(key('family-dependents-loading'), findsOneWidget);
      gate.complete();
      await settle(tester);
      expect(key('family-dependents-loading'), findsNothing);
      expect(find.text('Chưa có hồ sơ nào'), findsOneWidget);
    });

    testWidgets('lỗi → "Không thể tải…" + Thử lại', (tester) async {
      final depApi = FakeDependentApi()
        ..listError = BusinessException('ERR_SERVER', 'down');
      await pumpFamily(tester, depApi: depApi);
      expect(key('family-dependents-error'), findsOneWidget);
      depApi.listError = null;
      await tester.tap(key('family-dependents-retry'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Chưa có hồ sơ nào'), findsOneWidget);
    });

    testWidgets('L4: pull-to-refresh gọi lại loadDependents', (tester) async {
      final depApi = FakeDependentApi();
      await pumpFamily(tester, depApi: depApi);
      final before = depApi.count('list');
      await tester.fling(find.byType(ListView).first, const Offset(0, 500), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(depApi.count('list'), greaterThan(before));
    });
  });
}
