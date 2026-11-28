import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/domain/shared/budget_period.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/monthly_recap_api.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/monthly_recap_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/recap_badge.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

/// Payload mẫu đúng contract `GET /api/v1/insights/monthly`.
Map<String, dynamic> monthlyJson([Map<String, dynamic> extra = const {}]) =>
    <String, dynamic>{
      'householdId': 'h1',
      'month': '2026-11',
      'mealsLoggedCount': 42,
      'avgCaloriesKcal': 1850.25,
      'adherencePercent': 82.5,
      'bestStreakWeeks': 2,
      'memberInsights': <dynamic>[
        <String, dynamic>{
          'memberId': 'self',
          'calorieAvg': 1900,
          'calorieGoal': 2000,
          'compliancePct': 85,
          'badge': 'great_week',
          'topNutrientGap': 'Sắt',
          'highlight': 'Tháng tốt',
          'tip': 'Ăn thêm rau',
          'weeks': <dynamic>[
            <String, dynamic>{
              'weekStart': '2026-11-02',
              'calorieAvg': 1800,
              'calorieGoal': 2000,
              'compliancePct': 80,
              'badge': 'on_track',
              'topNutrientGap': 'Chất xơ',
              'highlight': 'Tuần đầu ổn',
              'tip': 'Uống đủ nước',
            },
          ],
        },
      ],
      'householdSummary': 'Cả nhà tốt',
      'suggestedFocus': 'Rau',
      'isStale': false,
      'computedAt': '2026-11-28T07:00:00Z',
      'wasteItemCount': 3,
      'wasteCauseBreakdown': <String, dynamic>{
        'OVERBOUGHT': 1,
        'FORGOTTEN': 2,
        'SPOILED_EARLY': 0,
        'UNTAGGED': 0,
      },
      'spendTotal': 1250000,
      'spendItemCount': 20,
      'shoppingCompletedItemCount': 25,
      'spendByCategory': <String, dynamic>{'Rau': 300000},
      'budgetAmount': 500000,
      'budgetPeriod': 'WEEKLY',
      'budgetMonthlyAmount': 2500000,
      'spendTrend': <dynamic>[
        <String, dynamic>{
          'weekStart': '2026-11-02',
          'spendTotal': 300000,
          'budgetWeeklyAmount': 500000,
        },
      ],
      'hasPrevious': true,
      ...extra,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonthlyRecapMapper', () {
    test('parse đủ field, số nguyên JSON ép sang double', () {
      final s = MonthlyRecapMapper.summaryFromJson(monthlyJson());

      expect(s.month, DateTime(2026, 11));
      expect(s.mealsLoggedCount, 42);
      expect(s.avgCaloriesKcal, 1850.25);
      expect(s.adherencePercent, 82.5);
      expect(s.bestStreakWeeks, 2);
      expect(s.hasPrevious, isTrue);
      expect(s.wasteItemCount, 3);
      expect(s.wasteCauseBreakdown.forgotten, 2);
      expect(s.spendTotal, 1250000.0);
      expect(s.budgetPeriod, BudgetPeriod.weekly);
      expect(s.budgetMonthlyAmount, 2500000.0);
      expect(s.spendByCategory, <String, double>{'Rau': 300000.0});
      expect(s.spendTrend!.single.budgetWeeklyAmount, 500000.0);

      final m = s.memberInsights.single;
      expect(m.memberId, 'self');
      expect(m.summary.calorieAvg, 1900.0);
      expect(m.summary.badge, RecapBadge.greatWeek);
      expect(m.weeks.single.weekStart, DateTime(2026, 11, 2));
      expect(m.weeks.single.insight.memberId, 'self');
      expect(m.weeks.single.insight.badge, RecapBadge.onTrack);
      expect(m.weeks.single.insight.topNutrientGap, 'Chất xơ');
    });

    test('gói FREE + isStale + field nullable vắng → null, không lỗi', () {
      final s =
          MonthlyRecapMapper.summaryFromJson(monthlyJson(<String, dynamic>{
        'avgCaloriesKcal': null,
        'adherencePercent': null,
        'spendTotal': null,
        'budgetAmount': null,
        'budgetPeriod': null,
        'budgetMonthlyAmount': null,
        'spendByCategory': null,
        'spendTrend': null,
        'isStale': true,
        'memberInsights': <dynamic>[],
        'householdSummary': null,
        'suggestedFocus': null,
        'hasPrevious': false,
      }));

      expect(s.avgCaloriesKcal, isNull);
      expect(s.adherencePercent, isNull);
      expect(s.spendTotal, isNull);
      expect(s.budgetMonthlyAmount, isNull);
      expect(s.budgetPeriod, BudgetPeriod.unknown);
      expect(s.spendByCategory, isNull);
      expect(s.spendTrend, isNull);
      expect(s.isStale, isTrue);
      expect(s.memberInsights, isEmpty);
      expect(s.hasPrevious, isFalse);
    });

    test('toSpendSummary đặt ngân sách THÁNG vào ô so sánh của widget chi tiêu',
        () {
      final spend =
          MonthlyRecapMapper.summaryFromJson(monthlyJson()).toSpendSummary();
      expect(spend.weekStart, DateTime(2026, 11));
      expect(spend.budgetWeeklyAmount, 2500000.0);
      expect(spend.spendRatio, closeTo(0.5, 1e-9));
      expect(spend.spendByCategory, isNotNull);
    });

    test('parseMonth/formatMonth', () {
      expect(MonthlyRecapMapper.parseMonth('2026-01'), DateTime(2026, 1));
      expect(MonthlyRecapMapper.formatMonth(DateTime(2026, 3)), '2026-03');
      expect(
          () => MonthlyRecapMapper.parseMonth('2026-1'), throwsFormatException);
    });
  });

  group('MonthlyRecapApi', () {
    final storageChannel = FakeSecureStorageChannel();
    setUpAll(storageChannel.install);
    tearDownAll(storageChannel.uninstall);

    MonthlyRecapApi makeApi(FakeHttpAdapter adapter) => MonthlyRecapApi(
          DioClient.build(
            tokenStorage: TokenStorage(),
            dio: Dio(BaseOptions(baseUrl: 'https://test.local'))
              ..httpClientAdapter = adapter,
          ),
        );

    test('không truyền month → không gửi query; có month → yyyy-MM', () async {
      final adapter = FakeHttpAdapter(
          (_) async => jsonResponse(200, successEnvelope(monthlyJson())));
      final api = makeApi(adapter);

      await api.getMonthlyRecap();
      expect(adapter.requests.last.path, '/api/v1/insights/monthly');
      expect(adapter.requests.last.queryParameters, isEmpty);

      await api.getMonthlyRecap(month: DateTime(2026, 9));
      expect(adapter.requests.last.queryParameters['month'], '2026-09');
    });

    test('400 ERR_RECAP_MONTH_INVALID ném ApiException giữ nguyên code',
        () async {
      final adapter = FakeHttpAdapter((_) async => jsonResponse(
          400, errorEnvelope('ERR_RECAP_MONTH_INVALID', 'invalid month')));
      final api = makeApi(adapter);

      await expectLater(
        api.getMonthlyRecap(month: DateTime(2030, 1)),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'ERR_RECAP_MONTH_INVALID')),
      );
    });
  });
}
