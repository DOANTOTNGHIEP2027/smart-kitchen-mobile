import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/recap/data/recap_api.dart';
import 'package:smart_kitchen_mobile/scenes/recap/domain/recap_badge.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  late FakeHttpAdapter adapter;
  late Dio client;

  setUpAll(storageChannel.install);
  tearDownAll(storageChannel.uninstall);

  setUp(() {
    adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(<String, dynamic>{})));
    client = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
  });

  RecapApi makeApi() =>
      RecapApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));

  Map<String, dynamic> summaryBody() => <String, dynamic>{
        'householdId': 'h1',
        'weekStart': '2026-03-02',
        'mealsLoggedCount': 3,
        'avgCaloriesKcal': 800,
        'adherencePercent': 80,
        'memberInsights': <dynamic>[
          <String, dynamic>{
            'memberId': 'self-1',
            'calorieAvg': 1800,
            'calorieGoal': 2000,
            'compliancePct': 90,
            'badge': 'great_week',
            'topNutrientGap': 'xơ',
            'highlight': 'Học cách ăn chậm',
            'tip': 'Ngủ đủ giấc',
          },
        ],
        'householdSummary': 'Tốt',
        'suggestedFocus': 'Nhiều rau',
        'isStale': false,
        'computedAt': '2026-03-08T07:00:00.000Z',
      };

  group('RecapApi.getWeeklyRecap', () {
    test('parse snapshot weekly, detect own member insight', () async {
      adapter = FakeHttpAdapter((_) async =>
          jsonResponse(200, successEnvelope(summaryBody())));
      client.httpClientAdapter = adapter;

      final s = await makeApi().getWeeklyRecap();

      expect(s.householdId, 'h1');
      expect(s.isStale, isFalse);
      expect(s.memberInsights, hasLength(1));
      expect(s.memberInsights.first.badge, RecapBadge.greatWeek);
    });

    test('isStale=true không phải lỗi — parse thành công', () async {
      final body = summaryBody()
        ..['isStale'] = true
        ..['memberInsights'] = <dynamic>[];
      adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(body)));
      client.httpClientAdapter = adapter;

      final s = await makeApi().getWeeklyRecap();
      expect(s.isStale, isTrue);
      expect(s.memberInsights, isEmpty);
    });
  });

  group('RecapApi.getHouseholdStreak', () {
    test('parse streak household + coerce int', () async {
      adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(<String, dynamic>{
            'householdId': 'h1',
            'currentStreak': 4,
            'bestStreak': 9,
            'lastComputedWeekStart': '2026-03-02',
          })));
      client.httpClientAdapter = adapter;

      final s = await makeApi().getHouseholdStreak(memberId: 'self-1');
      expect(s.currentStreak, 4);
      expect(s.bestStreak, 9);
      expect(s.lastComputedWeekStart, DateTime(2026, 3, 2));
    });

    test('memberId được gửi đúng trong query (Guard #11)', () async {
      adapter = FakeHttpAdapter((req) async =>
          jsonResponse(200, successEnvelope(<String, dynamic>{
            'householdId': 'h1',
            'currentStreak': 1,
            'bestStreak': 2,
            'lastComputedWeekStart': null,
          })));
      client.httpClientAdapter = adapter;

      await makeApi().getHouseholdStreak(memberId: 'self-1');
      final lastReq = adapter.requests.last;
      final sent = lastReq.queryParameters['memberId'];
      expect(sent, 'self-1');
    });
  });
}