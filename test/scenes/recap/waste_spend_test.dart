import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/domain/auth/auth_refresh_usecase.dart';
import 'package:smart_kitchen_mobile/domain/auth/user_summary.dart';
import 'package:smart_kitchen_mobile/domain/shared/budget_period.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations.dart';
import 'package:smart_kitchen_mobile/scenes/profile/profile_family_routes.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/recap_api.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/recap_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/household_streak.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/waste_spend.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/weekly_recap_summary.dart';
import 'package:smart_kitchen_mobile/scenes/recap/scenes/weekly_recap_scene.dart';
import 'package:smart_kitchen_mobile/scenes/recap/stores/weekly_recap_store.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/shareable_recap_card.dart';
import 'package:smart_kitchen_mobile/scenes/recap/widgets/waste_spend_sections.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/stores/session_store.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/pump_app.dart';

/// Payload camelCase thật của `WeeklyRecapResponse` (BE).
Map<String, dynamic> recapJson(Map<String, dynamic> extra) => <String, dynamic>{
      'householdId': 'h1',
      'weekStart': '2026-10-12',
      'mealsLoggedCount': 5,
      'avgCaloriesKcal': 1800,
      'adherencePercent': 80,
      'memberInsights': <dynamic>[],
      'householdSummary': null,
      'suggestedFocus': null,
      'isStale': true,
      'computedAt': '2026-10-19T00:00:00Z',
      ...extra,
    };

WeeklyRecapSummary parse(Map<String, dynamic> extra) => RecapMapper.summaryFromJson(
    jsonDecode(jsonEncode(recapJson(extra))) as Map<String, dynamic>);

WeeklyRecapSummary summary({
  int waste = 0,
  WasteCauseBreakdown breakdown = const WasteCauseBreakdown(),
  double? spend,
  int priced = 0,
  int completed = 0,
  double? budgetAmount,
  BudgetPeriod period = BudgetPeriod.unknown,
  double? budgetWeekly,
  Map<String, double>? byCategory,
  List<SpendTrendPoint>? trend,
  bool isStale = false,
}) =>
    WeeklyRecapSummary(
      householdId: 'h1',
      weekStart: DateTime(2026, 10, 12),
      mealsLoggedCount: 5,
      avgCaloriesKcal: 1800,
      adherencePercent: 80,
      memberInsights: const [],
      householdSummary: null,
      suggestedFocus: null,
      isStale: isStale,
      computedAt: DateTime.utc(2026, 10, 19),
      wasteItemCount: waste,
      wasteCauseBreakdown: breakdown,
      spendTotal: spend,
      spendItemCount: priced,
      shoppingCompletedItemCount: completed,
      budgetAmount: budgetAmount,
      budgetPeriod: period,
      budgetWeeklyAmount: budgetWeekly,
      spendByCategory: byCategory,
      spendTrend: trend,
    );

class _FakeRecapApi implements RecapApi {
  _FakeRecapApi(this.summary);
  final WeeklyRecapSummary summary;
  int recapCalls = 0;

  @override
  Future<WeeklyRecapSummary> getWeeklyRecap() async {
    recapCalls++;
    return summary;
  }

  @override
  Future<HouseholdStreak> getHouseholdStreak({required String memberId}) async =>
      const HouseholdStreak(householdId: 'h1', currentStreak: 1, bestStreak: 1, lastComputedWeekStart: null);
}

/// Mô phỏng mapper ném TypeError khi field mới méo shape.
class _ThrowingRecapApi implements RecapApi {
  @override
  Future<WeeklyRecapSummary> getWeeklyRecap() async =>
      RecapMapper.summaryFromJson(recapJson(<String, dynamic>{'spendByCategory': <String, dynamic>{'MEAT': 'abc'}}));

  @override
  Future<HouseholdStreak> getHouseholdStreak({required String memberId}) async =>
      const HouseholdStreak(householdId: 'h1', currentStreak: 1, bestStreak: 1, lastComputedWeekStart: null);
}

SessionStore session({String? tier, String role = 'MEMBER'}) {
  final s = SessionStore(
    TokenStorage(),
    AuthRefreshUseCase(Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(null)))),
  );
  s.currentUser = const UserSummary(id: 'self', fullName: 'Me');
  s.applyRefreshedClaims(fakeJwt(<String, dynamic>{
    'sub': 'self',
    'household_id': 'h1',
    'role': role,
    if (tier != null) 'tier': tier,
  }));
  return s;
}

Future<WeeklyRecapStore> loadedStore(WeeklyRecapSummary s, {String? tier, String role = 'MEMBER'}) async {
  final store = WeeklyRecapStore(_FakeRecapApi(s), session(tier: tier, role: role));
  await store.fetchAll();
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecapMapper (Guard #13–#16)', () {
    test('(a) PREMIUM đủ dữ liệu: số int → double, điểm trend null giữ null', () {
      final s = parse(<String, dynamic>{
        'wasteItemCount': 3,
        'wasteCauseBreakdown': <String, dynamic>{'OVERBOUGHT': 1, 'FORGOTTEN': 1, 'SPOILED_EARLY': 0, 'UNTAGGED': 1},
        'spendTotal': 850000,
        'spendItemCount': 4,
        'shoppingCompletedItemCount': 6,
        'budgetAmount': 6000000,
        'budgetPeriod': 'MONTHLY',
        'budgetWeeklyAmount': 1354839,
        'spendByCategory': <String, dynamic>{'MEAT': 500000, 'UNCATEGORIZED': 350000},
        'spendTrend': <dynamic>[
          <String, dynamic>{'weekStart': '2026-09-28', 'spendTotal': 700000, 'budgetWeeklyAmount': 1354839},
          <String, dynamic>{'weekStart': '2026-10-05', 'spendTotal': null, 'budgetWeeklyAmount': 1354839},
          <String, dynamic>{'weekStart': '2026-10-12', 'spendTotal': 850000, 'budgetWeeklyAmount': 1354839},
        ],
      });
      expect(s.spendTotal, 850000.0);
      expect(s.budgetPeriod, BudgetPeriod.monthly);
      expect(s.spendByCategory!['MEAT'], 500000.0);
      expect(s.spendTrend![1].spendTotal, isNull);
      expect(s.wasteCauseBreakdown.untagged, 1);
    });

    test('(b) FREE: spendByCategory/spendTrend null → domain null, KHÔNG phải {}/[]', () {
      final s = parse(<String, dynamic>{'spendByCategory': null, 'spendTrend': null});
      expect(s.spendByCategory, isNull);
      expect(s.spendTrend, isNull);
    });

    test('(c) PREMIUM nhưng {} → {} (khác null)', () {
      final s = parse(<String, dynamic>{'spendByCategory': <String, dynamic>{}, 'spendTrend': <dynamic>[]});
      expect(s.spendByCategory, isEmpty);
      expect(s.spendByCategory, isNotNull);
    });

    test('(d) payload cũ thiếu key → không throw, 0/null an toàn', () {
      final s = parse(<String, dynamic>{});
      expect(s.wasteItemCount, 0);
      expect(s.spendTotal, isNull);
      expect(s.budgetPeriod, BudgetPeriod.unknown);
      expect(s.spendByCategory, isNull);
    });

    test('breakdown: key lạ → other, KHÔNG cộng vào untagged; thiếu key → 0', () {
      final b = WasteCauseBreakdown.fromJson(<String, dynamic>{'UNTAGGED': 2, 'FUTURE_CAUSE': 3});
      expect(b.other, 3);
      expect(b.untagged, 2);
      expect(b.overbought, 0);
      expect(WasteCauseBreakdown.fromJson(null).barTotal, 0);
    });

    test('spendRatio: thiếu vế / ngân sách 0 → null; vượt ngân sách > 1, không clamp', () {
      expect(summary(spend: 100).spendRatio, isNull);
      expect(summary(spend: 100, budgetWeekly: 0).spendRatio, isNull);
      expect(summary(budgetWeekly: 100).spendRatio, isNull);
      expect(summary(spend: 150, budgetWeekly: 100).spendRatio, 1.5);
    });
  });

  test('payload méo (lỗi parse) → status error, KHÔNG kẹt loading', () async {
    final store = WeeklyRecapStore(_ThrowingRecapApi(), session());
    await store.fetchAll();
    expect(store.status, RecapLoadStatus.error);
    // null → màn hiện `l10n.recapError`, không hiện chuỗi tiếng Anh cứng.
    expect(store.error, isNull);
    expect(BudgetPeriod.fromApi('monthly'), BudgetPeriod.monthly);
  });

  group('spendDetailGate (Guard #14, #20)', () {

    test('BE trả breakdown → unlocked KỂ CẢ khi claim FREE', () async {
      final st = await loadedStore(summary(byCategory: const <String, double>{}), tier: 'FREE');
      expect(st.spendDetailGate, SpendDetailGate.unlocked);
    });

    test('BE gate + claim FREE/null/lạ → lockedUpsell', () async {
      for (final tier in <String?>['FREE', null, 'GOLD']) {
        final st = await loadedStore(summary(), tier: tier);
        expect(st.spendDetailGate, SpendDetailGate.lockedUpsell, reason: 'tier=$tier');
      }
    });

    test('BE gate + claim PREMIUM (kể cả viết thường) → lockedNeutral', () async {
      for (final tier in <String>['PREMIUM', 'premium']) {
        final st = await loadedStore(summary(), tier: tier);
        expect(st.spendDetailGate, SpendDetailGate.lockedNeutral, reason: 'tier=$tier');
      }
    });

    test('canSetBudget: CHỈ role OWNER', () async {
      expect((await loadedStore(summary(), role: 'OWNER')).canSetBudget, isTrue);
      for (final role in <String>['MEMBER', 'REMOTE_VIEWER']) {
        expect((await loadedStore(summary(), role: role)).canSetBudget, isFalse, reason: 'role=$role');
      }
    });
  });

  group('Widget', () {
    tearDown(Get.reset);

    testWidgets('WasteSection: 0 → khen, không có thanh; >0 breakdown toàn 0 → không crash', (tester) async {
      await tester.pumpAppWidget(WasteSection(count: 0, breakdown: const WasteCauseBreakdown(), weekStart: DateTime(2026, 10, 12)));
      expect(find.byKey(const ValueKey<String>('waste-none')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Thứ Hai 12/10 – Chủ Nhật 18/10'), findsOneWidget);

      await tester.pumpAppWidget(WasteSection(count: 2, breakdown: const WasteCauseBreakdown(), weekStart: DateTime(2026, 10, 12)));
      expect(find.text('2 món bị bỏ đi'), findsOneWidget);
      expect(find.text('Khác'), findsNothing);

      // Key lạ của BE (other > 0) → thêm dòng "Khác".
      await tester.pumpAppWidget(WasteSection(
          count: 3, breakdown: const WasteCauseBreakdown(untagged: 1, other: 2), weekStart: DateTime(2026, 10, 12)));
      expect(find.text('Khác'), findsOneWidget);
    });

    testWidgets('SpendSection: spendTotal null → KHÔNG có "0 ₫"; mẫu số 0 → ẩn độ phủ; non-OWNER không nút', (tester) async {
      await tester.pumpAppWidget(SpendSection(summary: summary(), canSetBudget: false, onSetBudget: () {}));
      expect(find.byKey(const ValueKey<String>('spend-none')), findsOneWidget);
      expect(find.textContaining('0 ₫'), findsNothing);
      expect(find.byKey(const ValueKey<String>('spend-coverage')), findsNothing);
      expect(find.byKey(const ValueKey<String>('spend-set-budget')), findsNothing);
      expect(find.byKey(const ValueKey<String>('spend-no-budget-member')), findsOneWidget);
    });

    testWidgets('SpendSection: vượt ngân sách → nhãn Vượt + độ phủ; OWNER chưa đặt → nút Đặt ngân sách', (tester) async {
      await tester.pumpAppWidget(SpendSection(
          summary: summary(spend: 1500000, budgetWeekly: 1000000, priced: 3, completed: 5),
          canSetBudget: true,
          onSetBudget: () {}));
      expect(find.text('1.500.000 ₫ / 1.000.000 ₫'), findsOneWidget);
      // % GỐC > 100% vẫn hiện cạnh "Vượt" (mock-up state 12).
      expect(find.text('150% ngân sách tuần · Vượt 500.000 ₫'), findsOneWidget);
      expect(find.text('3/5 món đã nhập giá'), findsOneWidget);

      await tester.pumpAppWidget(SpendSection(summary: summary(spend: 200000), canSetBudget: true, onSetBudget: () {}));
      expect(find.byKey(const ValueKey<String>('spend-set-budget')), findsOneWidget);
    });

    testWidgets('SpendSection: vượt < 1 ₫ sau làm tròn → KHÔNG "Vượt 0 ₫"', (tester) async {
      await tester.pumpAppWidget(SpendSection(
          summary: summary(spend: 1354839, budgetWeekly: 1354838.71), canSetBudget: false, onSetBudget: () {}));
      expect(find.textContaining('Vượt'), findsNothing);
      expect(find.text('100% ngân sách tuần'), findsOneWidget);
      // Không "Vượt" thì cũng không tô đỏ — màu và câu chữ phải khớp nhau.
      final label = tester.widget<Text>(find.byKey(const ValueKey<String>('spend-percent')));
      expect(label.style!.color, isNot(AppColors.error));
    });

    testWidgets('Sparkline: tuần null là cột rỗng viền đứt, vẫn thấy khi mọi tuần khác chi 0 ₫ (Guard #13)', (tester) async {
      await tester.pumpAppWidget(SizedBox(
          height: 140,
          child: SpendTrendSparkline(points: <SpendTrendPoint>[
            SpendTrendPoint(weekStart: DateTime(2026, 10, 5), spendTotal: 0),
            SpendTrendPoint(weekStart: DateTime(2026, 10, 12)),
          ])));
      final data = tester.widget<BarChart>(find.byType(BarChart)).data;
      expect(data.maxY, greaterThan(0));
      final nullRod = data.barGroups[1].barRods.single;
      expect(nullRod.toY, greaterThan(0));
      expect(nullRod.color, Colors.transparent);
      expect(nullRod.borderDashArray, isNotNull);
      expect(data.barGroups[0].barRods.single.toY, 0);
      expect(find.text('12/10'), findsOneWidget);
    });

    testWidgets('SpendSection: ghi chú quy đổi — weekly không có; monthly có; unknown không chứa "tháng"', (tester) async {
      await tester.pumpAppWidget(SpendSection(
          summary: summary(spend: 1, budgetWeekly: 2, budgetAmount: 2, period: BudgetPeriod.weekly),
          canSetBudget: false,
          onSetBudget: () {}));
      expect(find.byKey(const ValueKey<String>('spend-converted')), findsNothing);

      await tester.pumpAppWidget(SpendSection(
          summary: summary(spend: 1, budgetWeekly: 2, budgetAmount: 6000000, period: BudgetPeriod.monthly),
          canSetBudget: false,
          onSetBudget: () {}));
      expect(find.text('Ngân sách tháng (6.000.000 ₫) đã được quy đổi theo tuần.'), findsOneWidget);

      await tester.pumpAppWidget(SpendSection(
          summary: summary(spend: 1, budgetWeekly: 2, budgetAmount: 3000000),
          canSetBudget: false,
          onSetBudget: () {}));
      final text = tester.widget<Text>(find.byKey(const ValueKey<String>('spend-converted'))).data!;
      expect(text, contains('quy đổi theo tuần'));
      expect(text, isNot(contains('tháng')));
    });

    testWidgets('SpendDetailSection: lockedNeutral không có CTA; lockedUpsell có CTA', (tester) async {
      await tester.pumpAppWidget(SpendDetailSection(gate: SpendDetailGate.lockedNeutral, summary: summary(), onUpgrade: () {}));
      expect(find.byKey(const ValueKey<String>('spend-detail-neutral')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('spend-upsell-cta')), findsNothing);

      await tester.pumpAppWidget(SpendDetailSection(gate: SpendDetailGate.lockedUpsell, summary: summary(), onUpgrade: () {}));
      expect(find.byKey(const ValueKey<String>('spend-upsell-cta')), findsOneWidget);
    });

    testWidgets('SpendDetailSection unlocked: trend null/[] → không sparkline, danh sách vẫn có', (tester) async {
      for (final trend in <List<SpendTrendPoint>?>[null, const <SpendTrendPoint>[]]) {
        await tester.pumpAppWidget(SpendDetailSection(
            gate: SpendDetailGate.unlocked,
            summary: summary(byCategory: const <String, double>{'UNCATEGORIZED': 100000}, trend: trend),
            onUpgrade: () {}));
        expect(find.byType(SpendTrendSparkline), findsNothing);
        expect(find.byKey(const ValueKey<String>('spend-category-list')), findsOneWidget);
        expect(find.text('Chưa phân nhóm'), findsOneWidget);
      }
      await tester.pumpAppWidget(SpendDetailSection(
          gate: SpendDetailGate.unlocked,
          summary: summary(byCategory: const <String, double>{}, trend: <SpendTrendPoint>[
            SpendTrendPoint(weekStart: DateTime(2026, 10, 5)),
            SpendTrendPoint(weekStart: DateTime(2026, 10, 12), spendTotal: 50000, budgetWeeklyAmount: 100000),
          ]),
          onUpgrade: () {}));
      expect(find.byKey(const ValueKey<String>('spend-category-empty')), findsOneWidget);
      expect(find.byType(SpendTrendSparkline), findsOneWidget);
    });

    testWidgets('Scene: isStale vẫn hiện 2 khối; khối chi tiêu NGOÀI RepaintBoundary chia sẻ (Guard #19)', (tester) async {
      late WeeklyRecapStore st;
      await tester.runAsync(() async {
        st = await loadedStore(summary(isStale: true, waste: 1, spend: 1000, budgetWeekly: 2000));
      });
      Get.put<WeeklyRecapStore>(st);
      // Màn hình cao để ListView build đủ cả card share lẫn 3 khối mới.
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpAppWidget(const WeeklyRecapScene(), wrapInScaffold: false);
      await tester.pump();
      await tester.scrollUntilVisible(find.byType(SpendSection), 300);
      expect(find.byType(WasteSection), findsOneWidget);
      expect(find.byType(SpendSection), findsOneWidget);
      // Phải thật sự được build CÙNG LÚC với ShareableRecapCard — nếu không,
      // assert "không nằm trong ảnh share" bên dưới đúng một cách vô nghĩa.
      expect(find.byType(SpendDetailSection), findsOneWidget);
      // RepaintBoundary gần nhất bọc ShareableRecapCard = vùng chụp ảnh share.
      final shareBoundary = find
          .ancestor(of: find.byType(ShareableRecapCard), matching: find.byType(RepaintBoundary))
          .first;
      for (final type in <Type>[WasteSection, SpendSection, SpendDetailSection]) {
        expect(find.descendant(of: shareBoundary, matching: find.byType(type)), findsNothing,
            reason: '$type không được lọt vào ảnh share');
      }
    });

    testWidgets('Điều hướng bằng hằng route thật; quay về từ nâng cấp LUÔN tải lại recap', (tester) async {
      final api = _FakeRecapApi(summary(spend: 1000));
      late WeeklyRecapStore st;
      await tester.runAsync(() async {
        st = WeeklyRecapStore(api, session(tier: 'FREE', role: 'OWNER'));
        await st.fetchAll();
      });
      Get.put<WeeklyRecapStore>(st);
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WeeklyRecapScene(),
        getPages: <GetPage<dynamic>>[
          for (final r in <String>[ProfileFamilyRoutes.family, ProfileFamilyRoutes.tierUpgrade])
            GetPage<void>(name: r, page: () => Scaffold(body: Text('route:$r'))),
        ],
      ));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey<String>('spend-set-budget')));
      await tester.pumpAndSettle();
      expect(find.text('route:${ProfileFamilyRoutes.family}'), findsOneWidget);
      Get.back<void>();
      // Màn recap có animation lặp → không pumpAndSettle khi nó hiện lại.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final callsBefore = api.recapCalls;
      await tester.tap(find.byKey(const ValueKey<String>('spend-upsell-cta')));
      await tester.pumpAndSettle();
      expect(find.text('route:${ProfileFamilyRoutes.tierUpgrade}'), findsOneWidget);
      // Claim vẫn FREE (refreshClaims hỏng im lặng) — vẫn phải tải lại.
      Get.back<void>();
      // Màn recap có animation lặp → không pumpAndSettle khi nó hiện lại.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(api.recapCalls, callsBefore + 1);
    });
  });
}
