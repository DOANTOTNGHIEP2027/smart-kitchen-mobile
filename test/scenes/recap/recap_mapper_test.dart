import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/recap_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/household_streak.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/recap_badge.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/weekly_recap_summary.dart';

void main() {
  group('RecapBadgeParsing.fromApi', () {
    test('4 giá trị đã biết map đúng', () {
      expect(RecapBadgeParsing.fromApi('on_track'), RecapBadge.onTrack);
      expect(RecapBadgeParsing.fromApi('under'), RecapBadge.under);
      expect(RecapBadgeParsing.fromApi('over'), RecapBadge.over);
      expect(RecapBadgeParsing.fromApi('great_week'), RecapBadge.greatWeek);
    });

    test('string lạ/null → unknown, không throw (Guard #6)', () {
      expect(RecapBadgeParsing.fromApi('mystery'), RecapBadge.unknown);
      expect(RecapBadgeParsing.fromApi(null), RecapBadge.unknown);
      expect(RecapBadgeParsing.fromApi(''), RecapBadge.unknown);
    });
  });

  group('MemberWeeklyInsight.ringRatio', () {
    MemberWeeklyInsight make(double pct) => MemberWeeklyInsight(
          memberId: 'm1',
          calorieAvg: 2000,
          calorieGoal: 2000,
          compliancePct: pct,
          badge: RecapBadge.onTrack,
          topNutrientGap: 'protein',
          highlight: 'h',
          tip: 't',
        );

    test('clamp [0,1], không đổi giá trị hiển thị gốc', () {
      expect(make(50).ringRatio, 0.5);
      expect(make(120).ringRatio, 1.0); // compliance >100% vẫn clamp ratio
      expect(make(-10).ringRatio, 0.0);
      expect(make(120).compliancePct, 120.0); // số gốc KHÔNG clamp
    });
  });

  group('RecapMapper.summaryFromJson (camelCase contract)', () {
    test('parse đầy đủ, coercion số nguyên → double', () {
      final s = RecapMapper.summaryFromJson(<String, dynamic>{
        'householdId': 'h1',
        'weekStart': '2026-03-02',
        'mealsLoggedCount': 25,
        'avgCaloriesKcal': 1850,
        'adherencePercent': 90,
        'memberInsights': <Map<String, dynamic>>[
          <String, dynamic>{
            'memberId': 'm1',
            'calorieAvg': 1900,
            'calorieGoal': 2000,
            'compliancePct': 95,
            'badge': 'on_track',
            'topNutrientGap': 'vitamin D',
            'highlight': 'Bạn ăn đủ rau hôm nay',
            'tip': 'Thêm protein vào bữa tối',
          },
        ],
        'householdSummary': 'Cả nhà đang đi đúng hướng',
        'suggestedFocus': 'Tăng rau xanh',
        'isStale': false,
        'computedAt': '2026-03-08T07:00:00.000Z',
      });

      expect(s.householdId, 'h1');
      expect(s.weekStart, DateTime(2026, 3, 2));
      expect(s.mealsLoggedCount, 25);
      expect(s.avgCaloriesKcal, 1850.0);
      expect(s.adherencePercent, 90.0);
      expect(s.memberInsights, hasLength(1));
      final m = s.memberInsights.first;
      expect(m.memberId, 'm1');
      expect(m.compliancePct, 95.0);
      expect(m.badge, RecapBadge.onTrack);
      expect(s.isStale, isFalse);
      expect(s.computedAt, DateTime.utc(2026, 3, 8, 7));
    });

    test('isStale=true → memberInsights vẫn parse là danh sách (có thể rỗng)', () {
      final s = RecapMapper.summaryFromJson(<String, dynamic>{
        'householdId': 'h1',
        'weekStart': '2026-03-02',
        'mealsLoggedCount': 10,
        'avgCaloriesKcal': null,
        'adherencePercent': null,
        'memberInsights': <dynamic>[],
        'householdSummary': null,
        'suggestedFocus': null,
        'isStale': true,
        'computedAt': '2026-03-08T07:00:00.000Z',
      });
      expect(s.isStale, isTrue);
      expect(s.memberInsights, isEmpty);
      expect(s.avgCaloriesKcal, isNull);
    });
  });

  group('RecapMapper.streakFromJson (camelCase contract)', () {
    test('parse streak household', () {
      final s = RecapMapper.streakFromJson(<String, dynamic>{
        'householdId': 'h1',
        'currentStreak': 4,
        'bestStreak': 9,
        'lastComputedWeekStart': '2026-03-02',
      });
      expect(s, isA<HouseholdStreak>());
      expect(s.currentStreak, 4);
      expect(s.bestStreak, 9);
      expect(s.lastComputedWeekStart, DateTime(2026, 3, 2));
    });

    test('lastComputedWeekStart null khi chưa batch', () {
      final s = RecapMapper.streakFromJson(<String, dynamic>{
        'householdId': 'h1',
        'currentStreak': 0,
        'bestStreak': 0,
        'lastComputedWeekStart': null,
      });
      expect(s.lastComputedWeekStart, isNull);
    });
  });
}