import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/insights/data/adherence_api.dart';
import 'package:smart_kitchen_mobile/scenes/insights/data/history_api.dart';

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

  group('HistoryApi.getSelfWeekQuickStat', () {
    test('tự lọc member đúng theo memberId, không đọc phần tử đầu mảng', () async {
      adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(<dynamic>[
            <String, dynamic>{
              'memberId': 'other',
              'avgCaloriesKcal': 999,
              'loggedCount': 7,
            },
            <String, dynamic>{
              'memberId': 'self-1',
              'avgCaloriesKcal': 550,
              'loggedCount': 12,
            },
          ])));
      client.httpClientAdapter = adapter;

      final api = HistoryApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));
      final stat = await api.getSelfWeekQuickStat('self-1');

      expect(stat.avgCaloriesKcal, 550);
      expect(stat.loggedCount, 12);
    });

    test('member không có trong mảng → trả WeekQuickStat rỗng', () async {
      adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(<dynamic>[
            <String, dynamic>{'memberId': 'other', 'avgCaloriesKcal': 1, 'loggedCount': 1},
          ])));
      client.httpClientAdapter = adapter;

      final api = HistoryApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));
      final stat = await api.getSelfWeekQuickStat('absent');

      expect(stat.avgCaloriesKcal, isNull);
      expect(stat.loggedCount, isNull);
    });
  });

  group('AdherenceApi.getWeeklyAdherencePercent', () {
    test('404 ERR_ADHERENCE_NOT_FOUND → trả null, không throw', () async {
      adapter = FakeHttpAdapter((_) async =>
          jsonResponse(404, errorEnvelope('ERR_ADHERENCE_NOT_FOUND', 'chưa có snapshot')));
      client.httpClientAdapter = adapter;
      // 404 → ErrorMappingInterceptor mapping.
      final api = AdherenceApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));

      final result = await api.getWeeklyAdherencePercent(DateTime(2026, 3, 2));
      expect(result, isNull);
    });

    test('thành công → trả adherence_percent qua num coerce', () async {
      adapter = FakeHttpAdapter((_) async =>
          jsonResponse(200, successEnvelope(<String, dynamic>{'adherencePercent': 85})));
      client.httpClientAdapter = adapter;

      final api = AdherenceApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));
      final result = await api.getWeeklyAdherencePercent(DateTime(2026, 3, 9));
      expect(result, 85.0);
    });

    test('lỗi thật (5xx) → propagate, KHÔNG nuốt thành null', () async {
      adapter = FakeHttpAdapter((_) async =>
          jsonResponse(500, errorEnvelope('ERR_SERVER', 'internal')));
      client.httpClientAdapter = adapter;

      final api = AdherenceApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));
      await expectLater(
        api.getWeeklyAdherencePercent(DateTime(2026, 3, 16)),
        throwsA(isA<Object>()),
      );
    });
  });

  group('HistoryApi.listAllLogsInRange', () {
    Map<String, dynamic> logEntry(String id, String memberId) =>
        <String, dynamic>{
          'id': id,
          'householdId': 'hh-1',
          'memberId': memberId,
          'loggedBy': memberId,
          'description': 'rỗng',
          'caloriesKcal': 300,
          'requiresConfirmation': false,
          'confirmedByUser': false,
          'loggedAt': '2026-03-02T07:00:00.000Z',
          'confirmedAt': null,
          'foodItemsDetected': null,
          'nutrition': null,
        };

    test('gửi query memberId/from/to camelCase ĐÚNG contract', () async {
      adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(
          <String, dynamic>{'items': <dynamic>[], 'totalPages': 1, 'totalElements': 0})));
      client.httpClientAdapter = adapter;

      final api = HistoryApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));
      final logs = await api.listAllLogsInRange(
        memberId: 'self-1',
        from: DateTime(2026, 3, 1),
        to: DateTime(2026, 3, 31),
      );

      expect(logs, isEmpty);
      final req = adapter.requests.last;
      expect(req.path, '/api/v1/cooking/logs');
      expect(req.queryParameters['memberId'], 'self-1');
      expect(req.queryParameters['from'], '2026-03-01');
      expect(req.queryParameters['to'], '2026-03-31');
    });

    test('lặp phân trang theo totalPages và gộp toàn bộ items', () async {
      var page = 0;
      adapter = FakeHttpAdapter((_) async {
        final p = page++;
        return jsonResponse(
          200,
          successEnvelope(<String, dynamic>{
            'items': <dynamic>[logEntry('p$p-0', 'self-1'), logEntry('p$p-1', 'self-1')],
            'totalPages': 2,
            'totalElements': 4,
          }),
        );
      });
      client.httpClientAdapter = adapter;

      final api = HistoryApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));
      final logs = await api.listAllLogsInRange(
        memberId: 'self-1',
        from: DateTime(2026, 3, 1),
        to: DateTime(2026, 3, 31),
      );

      expect(adapter.requests.length, 2);
      expect(logs, hasLength(4));
      expect(logs.map((e) => e.id), <String>['p0-0', 'p0-1', 'p1-0', 'p1-1']);
    });
  });

  group('AdherenceApi.getStreak', () {
    test('parse số + coerce (integer từ jsonDecode)', () async {
      adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(<String, dynamic>{
            'currentStreak': 4,
            'bestStreak': 9,
            'lastComputedWeekStart': '2026-03-02',
          })));
      client.httpClientAdapter = adapter;

      final api = AdherenceApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));
      final s = await api.getStreak('self-1');

      expect(s.currentStreak, 4);
      expect(s.bestStreak, 9);
      expect(s.lastComputedWeekStart, DateTime(2026, 3, 2));
    });

    test('zero-fill khi household chưa batch (last_computed null)', () async {
      adapter = FakeHttpAdapter((_) async => jsonResponse(200, successEnvelope(<String, dynamic>{
            'currentStreak': 0,
            'bestStreak': 0,
            'lastComputedWeekStart': null,
          })));
      client.httpClientAdapter = adapter;

      final api = AdherenceApi(DioClient.build(tokenStorage: TokenStorage(), dio: client));
      final s = await api.getStreak('self-1');

      expect(s.currentStreak, 0);
      expect(s.bestStreak, 0);
      expect(s.lastComputedWeekStart, isNull);
    });
  });
}