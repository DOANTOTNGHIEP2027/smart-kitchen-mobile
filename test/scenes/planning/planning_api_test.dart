import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/auth/token_storage.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/dio_client.dart';
import 'package:smart_kitchen_mobile/scenes/planning/data/guest_diner_api.dart';
import 'package:smart_kitchen_mobile/scenes/planning/data/meal_slot_api.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/meal_slot_template_item.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/secure_storage_channel.dart';

Map<String, dynamic> slotJson({
  String? id = 's1',
  int? dayOfWeek,
  String slotKey = 'BREAKFAST',
  String scheduledTime = '07:00:00',
  int sortOrder = 1,
  bool isDefault = false,
}) =>
    <String, dynamic>{
      'id': id,
      'dayOfWeek': dayOfWeek,
      'slotKey': slotKey,
      'label': 'Bữa sáng',
      'scheduledTime': scheduledTime,
      'sortOrder': sortOrder,
      'isDefault': isDefault,
    };

Map<String, dynamic> guestJson({String id = 'g1'}) => <String, dynamic>{
      'id': id,
      'mealPlanId': 'plan-1',
      'displayName': 'Bác Tư',
      'addedBy': 'u1',
      'createdAt': '2026-10-18T03:00:00Z',
      'allergens': <dynamic>[
        <String, dynamic>{'id': 3, 'name': 'Đậu phộng'},
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storageChannel = FakeSecureStorageChannel();
  late Dio client;

  setUpAll(storageChannel.install);
  tearDownAll(storageChannel.uninstall);

  FakeHttpAdapter use(Future<ResponseBody> Function(RequestOptions) handler) {
    final adapter = FakeHttpAdapter(handler);
    client = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    return adapter;
  }

  DioClient dioClient() => DioClient.build(tokenStorage: TokenStorage(), dio: client);

  group('MealSlotApi', () {
    test('GET parse camelCase, chấp nhận giờ "HH:mm:ss" và dayOfWeek null', () async {
      use((_) async => jsonResponse(200, successEnvelope(<dynamic>[
            slotJson(id: null, isDefault: true),
            slotJson(id: 's2', dayOfWeek: 5, slotKey: 'SNACK', scheduledTime: '15:30'),
          ])));

      final slots = await MealSlotApi(dioClient()).getTemplate();

      expect(slots, hasLength(2));
      expect(slots[0].id, isNull);
      expect(slots[0].dayOfWeek, isNull);
      expect(slots[0].isDefault, isTrue);
      expect(slots[0].timeText, '07:00');
      expect(slots[1].dayOfWeek, 5);
      expect(slots[1].hour, 15);
      expect(slots[1].minute, 30);
    });

    test('PUT gửi body {slots:[...]} không kèm id/isDefault', () async {
      final adapter = use((_) async => jsonResponse(200, successEnvelope(<dynamic>[slotJson()])));

      await MealSlotApi(dioClient()).putTemplate(const <MealSlotTemplateItem>[
        MealSlotTemplateItem(
          id: 's1',
          slotKey: 'BREAKFAST',
          label: 'Bữa sáng',
          hour: 7,
          minute: 5,
          sortOrder: 1,
          isDefault: true,
        ),
      ]);

      final req = adapter.requests.single;
      expect(req.method, 'PUT');
      expect(req.path, '/api/v1/households/me/meal-slots');
      final body = req.data as Map<String, dynamic>;
      final item = (body['slots'] as List).single as Map<String, dynamic>;
      expect(item.keys, unorderedEquals(<String>['dayOfWeek', 'slotKey', 'label', 'scheduledTime', 'sortOrder']));
      expect(item['scheduledTime'], '07:05');
    });

    test('400 ERR_MEAL_SLOT_INVALID → ApiException giữ đúng code (không lọt DioException)', () async {
      use((_) async => jsonResponse(400, errorEnvelope('ERR_MEAL_SLOT_INVALID', 'Duplicate slotKey')));

      await expectLater(
        MealSlotApi(dioClient()).putTemplate(const <MealSlotTemplateItem>[]),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'ERR_MEAL_SLOT_INVALID')),
      );
    });
  });

  group('GuestDinerApi', () {
    test('list parse allergens {id,name} theo mealPlanId tuần', () async {
      final adapter = use((_) async => jsonResponse(200, successEnvelope(<dynamic>[guestJson()])));

      final diners = await GuestDinerApi(dioClient()).list('plan-1');

      expect(adapter.requests.single.path, '/api/v1/meal-plans/plan-1/guest-diners');
      expect(diners.single.trimmedName, 'Bác Tư');
      expect(diners.single.allergens.single.id, 3);
      expect(diners.single.mealPlanId, 'plan-1');
    });

    test('add gửi displayName + allergenIds (camelCase)', () async {
      final adapter = use((_) async => jsonResponse(201, successEnvelope(guestJson())));

      await GuestDinerApi(dioClient()).add('plan-1', displayName: 'Bác Tư', allergenIds: <int>[3]);

      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body, <String, dynamic>{'displayName': 'Bác Tư', 'allergenIds': <int>[3]});
    });

    test('remove chấp nhận 204 không body', () async {
      final adapter = use((_) async => ResponseBody.fromString('', 204));

      await GuestDinerApi(dioClient()).remove('plan-1', 'g1');

      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, '/api/v1/meal-plans/plan-1/guest-diners/g1');
    });

    test('404 ERR_MEAL_GUEST_DINER_NOT_FOUND → ApiException đúng code', () async {
      use((_) async => jsonResponse(404, errorEnvelope('ERR_MEAL_GUEST_DINER_NOT_FOUND', 'not found')));

      await expectLater(
        GuestDinerApi(dioClient()).updateAllergens('plan-1', 'g1', <int>[]),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'ERR_MEAL_GUEST_DINER_NOT_FOUND')),
      );
    });
  });

}
