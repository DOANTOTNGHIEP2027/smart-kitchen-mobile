import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/guest_diner.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/meal_slot_template_item.dart';
import 'package:smart_kitchen_mobile/scenes/planning/stores/guest_diner_store.dart';
import 'package:smart_kitchen_mobile/scenes/planning/stores/meal_slot_store.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/stores/form_status.dart';
import 'package:smart_kitchen_mobile/widgets/states/view_state.dart';

import 'planning_fakes.dart';

class _ThrowingSlotApi extends FakeMealSlotApi {
  @override
  Future<List<MealSlotTemplateItem>> getTemplate() async =>
      throw const FormatException('scheduledTime sai dạng');
}

/// Lần `list` ĐẦU treo tới khi test mở `firstGate`; các lần sau trả ngay.
class _GatedListGuestApi extends FakeGuestDinerApi {
  final Completer<void> firstGate = Completer<void>();
  int _listCalls = 0;

  @override
  Future<List<GuestDiner>> list(String mealPlanId) async {
    if (_listCalls++ == 0) {
      await firstGate.future;
      return const <GuestDiner>[];
    }
    return super.list(mealPlanId);
  }
}

class _GatedRemoveGuestApi extends FakeGuestDinerApi {
  final Completer<void> gate = Completer<void>();

  @override
  Future<void> remove(String mealPlanId, String guestDinerId) async {
    await gate.future;
    return super.remove(mealPlanId, guestDinerId);
  }
}

MealSlotTemplateItem slot(String key, int hour, {int? day, String label = 'x'}) =>
    MealSlotTemplateItem(dayOfWeek: day, slotKey: key, label: label, hour: hour, minute: 0, sortOrder: 0);

void main() {
  group('MealSlotStore', () {
    late FakeMealSlotApi api;
    late MealSlotStore store;

    setUp(() async {
      api = FakeMealSlotApi();
      store = MealSlotStore(api);
      await store.load();
    });

    test('load seed draft từ DEFAULT_SLOTS ảo → isUsingDefaults', () {
      expect(store.templateState, isA<SuccessState<List<MealSlotTemplateItem>>>());
      expect(store.draftSlots, hasLength(3));
      expect(store.isUsingDefaults, isTrue);
    });

    test('load lỗi → ErrorState giữ ApiException', () async {
      api.getError = ServerException('ERR_SERVER', 'down');
      await store.load();
      expect(store.templateState, isA<ErrorState<List<MealSlotTemplateItem>>>());
    });

    test('slot theo ngày CỘNG THÊM, không lẫn vào nhóm mọi ngày', () {
      store.addSlot(slot('CUSTOM_1', 15, day: 5));
      expect(store.draftEveryDay, hasLength(3));
      expect(store.slotsOfDay(5).single.slotKey, 'CUSTOM_1');
      expect(store.slotsOfDay(0), isEmpty);
    });

    test('validate: trùng slotKey cùng nhóm ngày → chặn, KHÔNG gọi API', () async {
      store.addSlot(slot('LUNCH', 13));
      final ok = await store.save();
      expect(ok, isFalse);
      expect(store.draftError, MealSlotDraftError.duplicateKey);
      expect(api.lastPut, isNull);
    });

    test('validate: cùng slotKey nhưng KHÁC nhóm ngày là hợp lệ', () {
      store.addSlot(slot('LUNCH', 13, day: 2));
      expect(store.validate(), isNull);
    });

    test('validate: rỗng / quá 10 / tên trống', () {
      for (final s in store.draftSlots.toList()) {
        store.removeSlot(s);
      }
      expect(store.validate(), MealSlotDraftError.empty);
      for (var i = 0; i < 11; i++) {
        store.addSlot(slot('CUSTOM_$i', i));
      }
      expect(store.validate(), MealSlotDraftError.tooMany);
      for (final s in store.draftSlots.toList()) {
        store.removeSlot(s);
      }
      store.addSlot(slot('BREAKFAST', 7, label: '   '));
      expect(store.validate(), MealSlotDraftError.blankLabel);
    });

    test('resequence sortOrder 1..n theo giờ TRONG từng nhóm ngày', () {
      final result = MealSlotStore.resequence(<MealSlotTemplateItem>[
        slot('DINNER', 18),
        slot('CUSTOM_1', 20, day: 1),
        slot('BREAKFAST', 7),
        slot('CUSTOM_2', 9, day: 1),
      ]);
      int order(String key, int? day) =>
          result.firstWhere((s) => s.slotKey == key && s.dayOfWeek == day).sortOrder;
      expect(order('BREAKFAST', null), 1);
      expect(order('DINNER', null), 2);
      expect(order('CUSTOM_2', 1), 1);
      expect(order('CUSTOM_1', 1), 2);
    });

    test('save OK → draft đồng bộ theo response, hết isDefault', () async {
      final ok = await store.save();
      expect(ok, isTrue);
      expect(store.saveStatus, FormStatus.success);
      expect(api.lastPut!.map((s) => s.sortOrder), <int>[1, 2, 3]);
      expect(store.isUsingDefaults, isFalse);
    });

    test('save lỗi server → failure + giữ nguyên draft để sửa tiếp', () async {
      api.putError = BusinessException('ERR_MEAL_SLOT_LIMIT', 'Maximum 10 slots');
      store.addSlot(slot('SNACK', 15));
      final ok = await store.save();
      expect(ok, isFalse);
      expect(store.saveStatus, FormStatus.failure);
      expect(store.saveError!.code, 'ERR_MEAL_SLOT_LIMIT');
      expect(store.draftSlots, hasLength(4));
      // Sửa tiếp → xoá banner lỗi.
      store.removeSlot(store.draftSlots.last);
      expect(store.saveStatus, FormStatus.idle);
    });

    test('sửa/xoá 1 bữa mặc định → hết banner "đang dùng mặc định"', () {
      expect(store.isUsingDefaults, isTrue);
      store.removeSlot(store.draftSlots.first);
      expect(store.isUsingDefaults, isFalse);
    });

    test('load lỗi parse (giờ sai dạng) → ErrorState, không treo spinner', () async {
      final bad = _ThrowingSlotApi();
      final s = MealSlotStore(bad);
      await s.load();
      expect(s.templateState, isA<ErrorState<List<MealSlotTemplateItem>>>());
    });

    test('nextCustomKey bỏ qua key đã dùng trong cùng nhóm ngày', () {
      store.addSlot(slot('CUSTOM_1', 10));
      expect(store.nextCustomKey(null), 'CUSTOM_2');
      expect(store.nextCustomKey(3), 'CUSTOM_1');
    });
  });

  group('GuestDinerStore', () {
    late FakeGuestDinerApi api;
    late FakeHealthApi health;
    late GuestDinerStore store;

    setUp(() {
      api = FakeGuestDinerApi();
      health = FakeHealthApi();
      store = GuestDinerStore(api, health, 'plan-1');
    });

    test('list rỗng → EmptyState; gọi đúng mealPlanId tuần', () async {
      await store.loadAll();
      expect(store.dinersState, isA<EmptyState<List<GuestDiner>>>());
      expect(api.calls, contains('list:plan-1'));
      expect(store.isCatalogReady, isTrue);
    });

    test('catalog lỗi (DioException thô) KHÔNG chặn danh sách khách', () async {
      api.diners = <GuestDiner>[guest('g1')];
      health.catalogError = DioException(requestOptions: RequestOptions(path: '/api/v1/allergens'));
      await store.loadAll();
      expect(store.dinersState, isA<SuccessState<List<GuestDiner>>>());
      expect(store.catalogState, isA<ErrorState<List<Allergen>>>());
      expect(store.isCatalogReady, isFalse);
    });

    test('add: tên rỗng gửi null, list chỉ đổi SAU khi BE trả OK', () async {
      await store.loadAll();
      final ok = await store.add(displayName: '  ', allergenIds: <int>{3, 1});
      expect(ok, isTrue);
      expect(api.calls.last, 'add:plan-1:null:[1, 3]');
      final state = store.dinersState as SuccessState<List<GuestDiner>>;
      expect(state.data.single.id, 'new');
    });

    test('add lỗi → list không đổi, giữ lỗi', () async {
      await store.loadAll();
      api.mutationError = BusinessException('ERR_ALLERGEN_NOT_FOUND', 'x');
      final ok = await store.add(allergenIds: <int>{99});
      expect(ok, isFalse);
      expect(store.mutationStatus, FormStatus.failure);
      expect(store.dinersState, isA<EmptyState<List<GuestDiner>>>());
    });

    test('add khi list đang lỗi → tải lại từ BE, không nối vào list rỗng', () async {
      api.listError = ServerException('ERR_SERVER', 'down');
      await store.loadAll();
      api
        ..listError = null
        ..diners = <GuestDiner>[guest('g1'), guest('new')];
      final ok = await store.add(allergenIds: <int>{});
      expect(ok, isTrue);
      final data = (store.dinersState as SuccessState<List<GuestDiner>>).data;
      expect(data.map((d) => d.id), <String>['g1', 'new']);
    });

    test('404 ERR_MEAL_GUEST_DINER_NOT_FOUND → tải lại list cho khớp BE', () async {
      api.diners = <GuestDiner>[guest('g1')];
      await store.loadAll();
      api
        ..diners = <GuestDiner>[]
        ..mutationError = BusinessException('ERR_MEAL_GUEST_DINER_NOT_FOUND', 'gone');
      final ok = await store.updateAllergens('g1', <int>{3});
      await Future<void>.delayed(Duration.zero);
      expect(ok, isFalse);
      expect(store.mutationStatus, FormStatus.failure);
      expect(store.dinersState, isA<EmptyState<List<GuestDiner>>>());
    });

    test('updateAllergens thay đúng phần tử', () async {
      api.diners = <GuestDiner>[guest('g1'), guest('g2')];
      await store.loadAll();
      await store.updateAllergens('g2', <int>{3});
      final data = (store.dinersState as SuccessState<List<GuestDiner>>).data;
      expect(data.map((d) => d.id), <String>['g1', 'g2']);
      expect(data[1].allergens.single.id, 3);
    });

    test('add lúc lần tải đầu còn treo → response cũ về sau KHÔNG ghi đè list mới', () async {
      final slowApi = _GatedListGuestApi();
      final s = GuestDinerStore(slowApi, health, 'plan-1');
      final initial = s.loadAll();
      await Future<void>.delayed(Duration.zero);
      expect(s.isCatalogReady, isTrue);
      expect(s.dinersState, isA<LoadingState<List<GuestDiner>>>());

      slowApi.diners = <GuestDiner>[guest('new')];
      final ok = await s.add(allergenIds: <int>{});
      expect(ok, isTrue);
      // Response của lần tải đầu (chưa có khách mới) về SAU cùng.
      slowApi.firstGate.complete();
      await initial;
      final data = (s.dinersState as SuccessState<List<GuestDiner>>).data;
      expect(data.map((d) => d.id), <String>['new']);
    });

    test('clearMutationStatus KHÔNG reset khi request còn treo (giữ guard isSubmitting)', () async {
      final g = guest('g1');
      final slowApi = _GatedRemoveGuestApi()..diners = <GuestDiner>[g];
      final s = GuestDinerStore(slowApi, health, 'plan-1');
      await s.loadAll();
      final pending = s.remove(g);
      expect(s.isSubmitting, isTrue);
      s.clearMutationStatus();
      expect(s.isSubmitting, isTrue);
      expect(await s.add(allergenIds: <int>{}), isFalse, reason: 'không cho mutation chồng');
      slowApi.gate.complete();
      expect(await pending, isTrue);
    });

    test('remove → bỏ khỏi list + set lastRemoved cho banner', () async {
      final g = guest('g1', name: 'Bác Tư');
      api.diners = <GuestDiner>[g];
      await store.loadAll();
      final ok = await store.remove(g);
      expect(ok, isTrue);
      expect(store.dinersState, isA<EmptyState<List<GuestDiner>>>());
      expect(store.lastRemoved, same(g));
      store.clearLastRemoved();
      expect(store.lastRemoved, isNull);
    });
  });
}
