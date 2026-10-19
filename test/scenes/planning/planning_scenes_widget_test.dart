import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/planning/domain/meal_slot_template_item.dart';
import 'package:smart_kitchen_mobile/scenes/planning/scenes/guest_diner_scene.dart';
import 'package:smart_kitchen_mobile/scenes/planning/scenes/meal_slot_config_scene.dart';
import 'package:smart_kitchen_mobile/scenes/planning/stores/guest_diner_store.dart';
import 'package:smart_kitchen_mobile/scenes/planning/stores/meal_slot_store.dart';
import 'package:smart_kitchen_mobile/scenes/planning/widgets/slot_form_sheet.dart';
import 'package:smart_kitchen_mobile/scenes/profile/domain/allergen.dart';
import 'package:smart_kitchen_mobile/widgets/buttons/app_button.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_empty_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_error_view.dart';
import 'package:smart_kitchen_mobile/widgets/states/app_loading_view.dart';

import '../../helpers/pump_app.dart';
import 'planning_fakes.dart';

/// API treo cho tới khi test tự mở — để quan sát trạng thái loading.
class _HangingSlotApi extends FakeMealSlotApi {
  final Completer<void> gate = Completer<void>();

  @override
  Future<List<MealSlotTemplateItem>> getTemplate() async {
    await gate.future;
    return super.getTemplate();
  }
}

Future<void> tapSave(WidgetTester tester) async {
  final save = find.byKey(const ValueKey<String>('slot-save'));
  await tester.scrollUntilVisible(save, 200);
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
}

void main() {
  tearDown(Get.reset);

  group('MealSlotConfigScene', () {
    Future<FakeMealSlotApi> pump(WidgetTester tester, [FakeMealSlotApi? api]) async {
      final fake = api ?? FakeMealSlotApi();
      Get.put<MealSlotStore>(MealSlotStore(fake));
      await tester.pumpAppWidget(const MealSlotConfigScene(), wrapInScaffold: false);
      return fake;
    }

    testWidgets('loading', (tester) async {
      final api = _HangingSlotApi();
      await pump(tester, api);
      expect(find.byType(AppLoadingView), findsOneWidget);
      api.gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('error → AppErrorView + retry', (tester) async {
      final api = FakeMealSlotApi()..getError = ServerException('ERR_SERVER', 'down');
      await pump(tester, api);
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorView), findsOneWidget);

      api.getError = null;
      await tester.tap(find.descendant(of: find.byType(AppErrorView), matching: find.byType(ElevatedButton)));
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorView), findsNothing);
    });

    testWidgets('success mặc định → banner "đang dùng mặc định" + 3 bữa', (tester) async {
      await pump(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('slot-default-banner')), findsOneWidget);
      expect(find.text('Bữa sáng'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    testWidgets('empty: xoá hết rồi Lưu → banner lỗi client, không gọi API', (tester) async {
      final api = await pump(tester);
      await tester.pumpAndSettle();
      for (final key in <String>['BREAKFAST', 'LUNCH', 'DINNER']) {
        await tester.tap(find.byKey(ValueKey<String>('slot-delete-null-$key')));
        await tester.pump();
      }
      await tapSave(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('slot-draft-error')), findsOneWidget);
      expect(api.lastPut, isNull);
    });

    testWidgets('lỗi server khi lưu → banner lỗi hiện message BE', (tester) async {
      final api = FakeMealSlotApi()..putError = BusinessException('ERR_MEAL_SLOT_LIMIT', 'Tối đa 10');
      await pump(tester, api);
      await tester.pumpAndSettle();
      await tapSave(tester);
      await tester.pumpAndSettle();
      expect(api.lastPut, isNotNull, reason: 'tap Lưu phải gọi PUT');
      await tester.drag(find.byType(ListView), const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('slot-save-error')), findsOneWidget);
      expect(find.text('Tối đa 10'), findsOneWidget);
    });
  });

  group('MealSlotConfigScene — đang lưu', () {
    testWidgets('saving → nút Lưu isLoading, nút xoá bị khoá (§8.1)', (tester) async {
      final api = FakeMealSlotApi()..putGate = Completer<void>();
      Get.put<MealSlotStore>(MealSlotStore(api));
      await tester.pumpAppWidget(const MealSlotConfigScene(), wrapInScaffold: false);
      await tester.pumpAndSettle();

      await tapSave(tester);
      await tester.pump();

      final save = tester.widget<AppButton>(find.byKey(const ValueKey<String>('slot-save')));
      expect(save.isLoading, isTrue);
      await tester.drag(find.byType(ListView), const Offset(0, 2000));
      await tester.pump();
      final delete = tester.widget<IconButton>(find.byKey(const ValueKey<String>('slot-delete-null-BREAKFAST')));
      expect(delete.onPressed, isNull);

      api.putGate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('SlotFormSheet', () {
    Future<SlotFormResult?> openAndSubmit(WidgetTester tester, MealSlotTemplateItem? initial) async {
      SlotFormResult? result;
      await tester.pumpAppWidget(Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showSlotFormSheet(context, initial: initial),
          child: const Text('open'),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('slot-form-submit')));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('sửa bữa tự đặt tên → giữ nguyên slotKey cũ (D-SLOT-REPLACE)', (tester) async {
      final result = await openAndSubmit(
        tester,
        const MealSlotTemplateItem(slotKey: 'CUSTOM_2', label: 'Ăn khuya', hour: 22, minute: 30, sortOrder: 1),
      );
      expect(result!.slotKey, 'CUSTOM_2');
      expect(result.label, 'Ăn khuya');
      expect((result.hour, result.minute), (22, 30));
    });

    testWidgets('thêm mới → seed tên theo preset mặc định', (tester) async {
      final result = await openAndSubmit(tester, null);
      expect(result!.slotKey, 'BREAKFAST');
      expect(result.label, 'Bữa sáng');
    });
  });

  group('GuestDinerScene', () {
    Future<(FakeGuestDinerApi, FakeHealthApi)> pump(
      WidgetTester tester, {
      FakeGuestDinerApi? api,
      FakeHealthApi? health,
    }) async {
      final a = api ?? FakeGuestDinerApi();
      final h = health ?? FakeHealthApi();
      Get.put<GuestDinerStore>(GuestDinerStore(a, h, 'plan-1'));
      await tester.pumpAppWidget(const GuestDinerScene(), wrapInScaffold: false);
      return (a, h);
    }

    testWidgets('loading → spinner, banner phạm vi luôn hiện', (tester) async {
      await pump(tester);
      expect(find.byType(AppLoadingView), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('guest-scope-banner')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('empty', (tester) async {
      await pump(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AppEmptyView), findsOneWidget);
    });

    testWidgets('error', (tester) async {
      await pump(tester, api: FakeGuestDinerApi()..listError = ServerException('ERR_SERVER', 'down'));
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorView), findsOneWidget);
    });

    testWidgets('success: tên fallback + "Không dị ứng" + chip dị ứng', (tester) async {
      final api = FakeGuestDinerApi()
        ..diners = [
          guest('g1'),
          guest('g2', name: 'Bác Tư', allergens: const <Allergen>[Allergen(id: 3, name: 'Đậu phộng')]),
        ];
      await pump(tester, api: api);
      await tester.pumpAndSettle();
      expect(find.text('Khách chưa đặt tên'), findsOneWidget);
      expect(find.text('Không dị ứng'), findsOneWidget);
      expect(find.text('Bác Tư'), findsOneWidget);
      expect(find.text('Đậu phộng'), findsOneWidget);
    });

    testWidgets('xoá khách → banner "không tự mở lại món đã chặn"', (tester) async {
      final api = FakeGuestDinerApi()..diners = [guest('g1', name: 'Bác Tư')];
      await pump(tester, api: api);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('guest-delete-g1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('guest-delete-confirm')));
      await tester.pumpAndSettle();
      expect(api.calls, contains('remove:g1'));
      expect(find.byKey(const ValueKey<String>('guest-removed-hint')), findsOneWidget);
      expect(find.textContaining('Đã xoá Bác Tư'), findsOneWidget);
      expect(find.byType(AppEmptyView), findsOneWidget);
    });

    testWidgets('catalog lỗi → nút Thêm bị khoá (I9)', (tester) async {
      await pump(tester, health: FakeHealthApi()..catalogError = ServerException('ERR_SERVER', 'x'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('guest-add')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('guest-catalog-error')), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.descendant(
        of: find.byKey(const ValueKey<String>('guest-form-submit')),
        matching: find.byType(ElevatedButton),
      ));
      expect(button.onPressed, isNull);
    });
  });
}
