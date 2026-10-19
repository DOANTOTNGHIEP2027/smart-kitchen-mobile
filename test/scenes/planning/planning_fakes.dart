import 'dart:async';

import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/planning/data/guest_diner_api.dart';
import 'package:smart_kitchen_mobile/scenes/planning/data/meal_slot_api.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/guest_diner.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/meal_slot_template_item.dart';
import 'package:smart_kitchen_mobile/scenes/profile/api/health_api.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/health_profile.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/member_health_summary.dart';

const List<MealSlotTemplateItem> defaultSlots = <MealSlotTemplateItem>[
  MealSlotTemplateItem(slotKey: 'BREAKFAST', label: 'Bữa sáng', hour: 7, minute: 0, sortOrder: 1, isDefault: true),
  MealSlotTemplateItem(slotKey: 'LUNCH', label: 'Bữa trưa', hour: 12, minute: 0, sortOrder: 2, isDefault: true),
  MealSlotTemplateItem(slotKey: 'DINNER', label: 'Bữa tối', hour: 18, minute: 0, sortOrder: 3, isDefault: true),
];

class FakeMealSlotApi implements MealSlotApi {
  List<MealSlotTemplateItem> template = defaultSlots;
  ApiException? getError;
  ApiException? putError;
  List<MealSlotTemplateItem>? lastPut;

  /// Đặt để giữ request PUT treo (test trạng thái đang lưu).
  Completer<void>? putGate;

  @override
  Future<List<MealSlotTemplateItem>> getTemplate() async {
    if (getError != null) throw getError!;
    return template;
  }

  @override
  Future<List<MealSlotTemplateItem>> putTemplate(List<MealSlotTemplateItem> slots) async {
    lastPut = slots;
    await putGate?.future;
    if (putError != null) throw putError!;
    return <MealSlotTemplateItem>[
      for (final s in slots)
        MealSlotTemplateItem(
          id: 'id-${s.dayOfWeek}-${s.slotKey}',
          dayOfWeek: s.dayOfWeek,
          slotKey: s.slotKey,
          label: s.label,
          hour: s.hour,
          minute: s.minute,
          sortOrder: s.sortOrder,
        ),
    ];
  }
}

GuestDiner guest(String id, {String? name, List<Allergen> allergens = const <Allergen>[]}) => GuestDiner(
      id: id,
      mealPlanId: 'plan-1',
      displayName: name,
      allergens: allergens,
      addedBy: 'u1',
      createdAt: DateTime.utc(2026, 10, 18),
    );

class FakeGuestDinerApi implements GuestDinerApi {
  List<GuestDiner> diners = <GuestDiner>[];
  ApiException? listError;
  ApiException? mutationError;
  final List<String> calls = <String>[];

  @override
  Future<List<GuestDiner>> list(String mealPlanId) async {
    calls.add('list:$mealPlanId');
    if (listError != null) throw listError!;
    return diners;
  }

  @override
  Future<GuestDiner> add(String mealPlanId, {String? displayName, required List<int> allergenIds}) async {
    calls.add('add:$mealPlanId:$displayName:$allergenIds');
    if (mutationError != null) throw mutationError!;
    return guest('new', name: displayName, allergens: <Allergen>[for (final id in allergenIds) Allergen(id: id, name: 'A$id')]);
  }

  @override
  Future<GuestDiner> updateAllergens(String mealPlanId, String guestDinerId, List<int> allergenIds) async {
    calls.add('update:$guestDinerId:$allergenIds');
    if (mutationError != null) throw mutationError!;
    return guest(guestDinerId, allergens: <Allergen>[for (final id in allergenIds) Allergen(id: id, name: 'A$id')]);
  }

  @override
  Future<void> remove(String mealPlanId, String guestDinerId) async {
    calls.add('remove:$guestDinerId');
    if (mutationError != null) throw mutationError!;
  }
}

class FakeHealthApi implements HealthApi {
  List<Allergen> catalog = const <Allergen>[
    Allergen(id: 1, name: 'Gluten'),
    Allergen(id: 3, name: 'Đậu phộng'),
  ];
  Object? catalogError;

  @override
  Future<List<Allergen>> getAllergenCatalog() async {
    if (catalogError != null) throw catalogError!;
    return catalog;
  }

  @override
  Future<HealthProfile> getMyHealthProfile() => throw UnimplementedError();

  @override
  Future<HealthProfile> updateMyHealthProfile(Map<String, dynamic> payload) => throw UnimplementedError();

  @override
  Future<List<Allergen>> updateMyAllergens(List<int> allergenIds) => throw UnimplementedError();

  @override
  Future<MemberHealthSummary> getMemberHealthSummary(String userId) => throw UnimplementedError();
}
