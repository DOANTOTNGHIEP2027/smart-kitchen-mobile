import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/data/network/api_response.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_session_mapper.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_result.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/ingredient_deduction.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_session_scene.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_session_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/widgets/shortfall_sheet.dart';

import '../../helpers/pump_app.dart';
import 'cooking_session_store_test.dart' show MemoryProgressStore;
import 'fake_cooking_api.dart';

/// OD-36 — 409 `ERR_INSUFFICIENT_STOCK_FOR_RECIPE` khi "Hoàn thành":
/// kho không đổi, hỏi người dùng, chỉ gửi `allowShortfall=true` khi họ xác nhận.
void main() {
  const code = 'ERR_INSUFFICIENT_STOCK_FOR_RECIPE';

  Map<String, dynamic> detailsJson() => <String, dynamic>{
        'missingIngredients': <Map<String, dynamic>>[
          <String, dynamic>{
            'ingredientName': 'Thịt heo',
            'requiredQuantity': 300,
            'availableQuantity': 200,
            'shortfallQuantity': 100,
            'unit': 'GRAM',
          },
        ],
      };

  BusinessException shortfallError([Map<String, dynamic>? details]) =>
      BusinessException(code, 'Not enough stock', details: details);

  group('mapMissingIngredients', () {
    test('đủ field (số nguyên JSON) → parse đúng, camelCase', () {
      final list = mapMissingIngredients(detailsJson());
      expect(list, hasLength(1));
      expect(list.single.ingredientName, 'Thịt heo');
      expect(list.single.requiredQuantity, 300.0);
      expect(list.single.availableQuantity, 200.0);
      expect(list.single.shortfallQuantity, 100.0);
      expect(list.single.unit, 'GRAM');
    });

    test('details null / sai kiểu → list rỗng, không throw', () {
      expect(mapMissingIngredients(null), isEmpty);
      expect(mapMissingIngredients(<String, dynamic>{'missingIngredients': 'x'}),
          isEmpty);
    });

    test('item thiếu field bắt buộc / sai kiểu → bỏ qua item đó', () {
      final list = mapMissingIngredients(<String, dynamic>{
        'missingIngredients': <Object?>[
          <String, dynamic>{'ingredientName': 'Thiếu số'},
          'rác',
          null,
          <String, dynamic>{
            'ingredient_name': 'snake_case',
            'requiredQuantity': 1,
            'availableQuantity': 0,
            'shortfallQuantity': 1,
            'unit': 'UNIT',
          },
          ...detailsJson()['missingIngredients'] as List<dynamic>,
        ],
      });
      expect(list.map((e) => e.ingredientName), <String>['Thịt heo']);
    });
  });

  test('ApiError.fromJson giữ error.details; sai kiểu thì bỏ', () {
    final ok = ApiError.fromJson(<String, dynamic>{
      'code': code,
      'message': 'm',
      'details': detailsJson(),
    });
    expect(mapMissingIngredients(ok.details), hasLength(1));

    final bad = ApiError.fromJson(<String, dynamic>{
      'code': code,
      'message': 'm',
      'details': 'không phải map',
    });
    expect(bad.details, isNull);
  });

  // ── Store ────────────────────────────────────────────────────────────────

  late FakeCookingApi cookingApi;
  late FakeRecipeApi recipeApi;

  CookingSession session({
    CookingSessionStatusWire status = CookingSessionStatusWire.inProgress,
  }) =>
      CookingSession(
        id: 's1',
        householdId: 'h1',
        recipeId: 'r1',
        recipeName: 'Canh chua',
        startedBy: 'u1',
        status: status,
        totalSteps: 1,
        startedAt: DateTime.parse('2026-11-19T07:00:00Z'),
        stepsSnapshot: const <CookingSessionStep>[
          CookingSessionStep(stepNumber: 1, instruction: 'Nấu'),
        ],
      );

  CookingSessionResult completedResult() => CookingSessionResult(
        session: session(status: CookingSessionStatusWire.completed),
        deductions: const <IngredientDeduction>[
          IngredientDeduction(
            ingredientName: 'Thịt heo',
            requiredQuantity: 300,
            requiredUnit: 'GRAM',
            deductedQuantity: 200,
            shortfallQuantity: 100,
            matchedItemCount: 1,
          ),
        ],
      );

  /// Thiếu kho khi chưa xác nhận, thành công khi `allowShortfall=true`.
  void stubShortfallThenOk() {
    cookingApi.onCompleteWith = (_, allow) async {
      if (!allow) throw shortfallError(detailsJson());
      return completedResult();
    };
  }

  CookingSessionStore newStore() => CookingSessionStore(
        cookingApi: cookingApi,
        recipeApi: recipeApi,
        progressStore: CookingProgressCoordinator(MemoryProgressStore()),
        userId: 'u1',
        entryMode: CookingEntryMode.start,
        recipeId: 'r1',
      );

  setUp(() {
    cookingApi = FakeCookingApi()..onStart = (_) async => session();
    recipeApi = FakeRecipeApi();
  });

  group('CookingSessionStore — thiếu kho', () {
    test('409 → shortfall có list, phase active, KHÔNG actionError/retry',
        () async {
      stubShortfallThenOk();
      final store = newStore();
      await store.init();

      await store.complete();

      expect(store.shortfall, hasLength(1));
      expect(store.phase, CookingScreenPhase.active);
      expect(store.actionError, isNull);
      expect(store.canRetryAction, isFalse);
      expect(store.deductions, isEmpty, reason: 'kho chưa bị trừ gì');
      expect(cookingApi.completeCalls, <bool>[false]);
    });

    test('409 không có details → shortfall là list rỗng (sheet vẫn hiện)',
        () async {
      cookingApi.onCompleteError = shortfallError();
      final store = newStore();
      await store.init();

      await store.complete();

      expect(store.shortfall, isNotNull);
      expect(store.shortfall, isEmpty);
    });

    test('completeWithShortfall → gửi allowShortfall=true, phase completed',
        () async {
      stubShortfallThenOk();
      final store = newStore();
      await store.init();
      await store.complete();

      await store.completeWithShortfall();

      expect(cookingApi.completeCalls, <bool>[false, true]);
      expect(store.phase, CookingScreenPhase.completed);
      expect(store.shortfall, isNull);
      expect(store.deductions.single.hasShortfall, isTrue);
    });

    test('completeWithShortfall khi không có shortfall → không gọi API',
        () async {
      stubShortfallThenOk();
      final store = newStore();
      await store.init();

      await store.completeWithShortfall();

      expect(cookingApi.completeCalls, isEmpty);
    });

    test('dismissShortfall → xoá câu hỏi, vẫn nấu tiếp, không gọi API',
        () async {
      stubShortfallThenOk();
      final store = newStore();
      await store.init();
      await store.complete();

      store.dismissShortfall();

      expect(store.shortfall, isNull);
      expect(store.phase, CookingScreenPhase.active);
      expect(cookingApi.completeCalls, <bool>[false]);
    });

    test('bấm Hoàn thành lại sau khi đóng → hỏi lại (chống sheet không mở)',
        () async {
      cookingApi.onCompleteError = shortfallError();
      final store = newStore();
      await store.init();
      final seen = <List<Object?>?>[];
      await store.complete();
      seen.add(store.shortfall);
      store.dismissShortfall();
      await store.complete();
      seen.add(store.shortfall);

      expect(seen, everyElement(isNotNull));
      expect(identical(seen[0], seen[1]), isFalse,
          reason: 'giá trị mới mỗi lần → reaction luôn chạy');
    });

    test('lần allowShortfall=true gặp lỗi mạng → Thử lại vẫn gửi true',
        () async {
      var failNext = true;
      cookingApi.onCompleteWith = (_, allow) async {
        if (!allow) throw shortfallError(detailsJson());
        if (failNext) {
          failNext = false;
          throw NetworkException();
        }
        return completedResult();
      };
      final store = newStore();
      await store.init();
      await store.complete();
      await store.completeWithShortfall();

      expect(store.actionError, isA<NetworkException>());
      expect(store.canRetryAction, isTrue);

      await store.retryLastAction();

      expect(cookingApi.completeCalls, <bool>[false, true, true]);
      expect(store.phase, CookingScreenPhase.completed);
    });

    test('lỗi mạng ở lần đầu → Thử lại vẫn gửi false (không tự xác nhận)',
        () async {
      var failNext = true;
      cookingApi.onCompleteWith = (_, allow) async {
        if (failNext) {
          failNext = false;
          throw NetworkException();
        }
        throw shortfallError(detailsJson());
      };
      final store = newStore();
      await store.init();
      await store.complete();
      await store.retryLastAction();

      expect(cookingApi.completeCalls, <bool>[false, false]);
      expect(store.shortfall, hasLength(1));
    });

    test('BE vẫn trả 409 dù allowShortfall=true → lỗi thường, không lặp',
        () async {
      cookingApi.onCompleteWith = (_, __) async => throw shortfallError();
      final store = newStore();
      await store.init();
      await store.complete();
      await store.completeWithShortfall();

      expect(store.shortfall, isNull);
      expect(store.actionError?.code, code);
      expect(store.canRetryAction, isFalse);
      expect(cookingApi.completeCalls, <bool>[false, true]);
    });

    test('ALREADY_ENDED khi hoàn tất dù thiếu → resync, đóng câu hỏi',
        () async {
      cookingApi.onCompleteWith = (_, allow) async {
        if (!allow) throw shortfallError(detailsJson());
        throw BusinessException('ERR_SESSION_ALREADY_ENDED', 'ended');
      };
      cookingApi.onGetById = (_) async => CookingSessionResult(
            session: session(status: CookingSessionStatusWire.abandoned),
            deductions: const <IngredientDeduction>[],
          );
      final store = newStore();
      await store.init();
      await store.complete();
      await store.completeWithShortfall();

      expect(store.phase, CookingScreenPhase.abandoned);
      expect(store.shortfall, isNull);
      expect(store.actionError, isNull);
    });

    test('completeWithShortfall khi store đang bận → bỏ câu hỏi, không gọi API',
        () async {
      stubShortfallThenOk();
      final gate = Completer<CookingSession>();
      cookingApi.onAbandon = (_) => gate.future;
      final store = newStore();
      await store.init();
      await store.complete();
      final abandoning = store.abandon();

      await store.completeWithShortfall();

      expect(store.shortfall, isNull, reason: 'không treo câu hỏi');
      expect(cookingApi.completeCalls, <bool>[false]);
      gate.complete(session(status: CookingSessionStatusWire.abandoned));
      await abandoning;
    });

    test('Huỷ bỏ khi đang có câu hỏi → shortfall về null', () async {
      stubShortfallThenOk();
      cookingApi.onAbandon =
          (_) async => session(status: CookingSessionStatusWire.abandoned);
      final store = newStore();
      await store.init();
      await store.complete();

      await store.abandon();

      expect(store.shortfall, isNull);
      expect(store.phase, CookingScreenPhase.abandoned);
    });
  });

  // ── Widget (mức màn hình) ────────────────────────────────────────────────

  group('CookingSessionScene — sheet thiếu nguyên liệu', () {
    late CookingSessionStore store;

    setUp(() {
      for (final api in <String>['toggle', 'isEnabled']) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$api',
          (_) async => const StandardMessageCodec()
              .encodeMessage(<Object?>[api == 'isEnabled' ? false : null]),
        );
      }
      store = newStore();
      Get.put<CookingSessionStore>(store);
    });
    tearDown(Get.reset);

    Future<void> pumpActive(WidgetTester tester) async {
      await tester.pumpAppWidget(const CookingSessionScene(),
          wrapInScaffold: false);
      await tester.pump();
      await tester.pump();
      expect(store.phase, CookingScreenPhase.active);
    }

    Future<void> tapComplete(WidgetTester tester) async {
      await tester.tap(find.text('Hoàn thành'));
      await tester.pumpAndSettle();
    }

    testWidgets('409 → sheet hiện tên + số lượng + đơn vị, không snackbar',
        (tester) async {
      stubShortfallThenOk();
      await pumpActive(tester);

      await tapComplete(tester);

      expect(find.byType(ShortfallSheet), findsOneWidget);
      expect(find.text('Kho không đủ nguyên liệu'), findsOneWidget);
      expect(find.text('Thịt heo'), findsOneWidget);
      expect(find.text('Cần 300 · Có 200 · Thiếu 100 g'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(store.phase, CookingScreenPhase.active);
      expect(store.deductions, isEmpty);
    });

    testWidgets('Hoàn tất dù thiếu → allowShortfall=true → màn completed',
        (tester) async {
      stubShortfallThenOk();
      await pumpActive(tester);
      await tapComplete(tester);

      await tester.tap(find.text('Hoàn tất dù thiếu (trừ phần đang có)'));
      await tester.pumpAndSettle();

      expect(find.byType(ShortfallSheet), findsNothing);
      expect(cookingApi.completeCalls, <bool>[false, true]);
      expect(store.phase, CookingScreenPhase.completed);
      expect(find.text('Đã hoàn thành — còn thiếu nguyên liệu'),
          findsOneWidget);
    });

    testWidgets('Quay lại nấu → đóng sheet, vẫn ở bước nấu, kho không đổi',
        (tester) async {
      stubShortfallThenOk();
      await pumpActive(tester);
      await tapComplete(tester);

      await tester.tap(find.text('Quay lại nấu'));
      await tester.pumpAndSettle();

      expect(find.byType(ShortfallSheet), findsNothing);
      expect(store.shortfall, isNull);
      expect(store.phase, CookingScreenPhase.active);
      expect(cookingApi.completeCalls, <bool>[false]);
    });

    testWidgets('vuốt đóng sheet rồi bấm Hoàn thành lại → sheet mở lại',
        (tester) async {
      stubShortfallThenOk();
      await pumpActive(tester);
      await tapComplete(tester);

      // Chạm vùng tối ngoài sheet = đóng như vuốt/back.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(ShortfallSheet), findsNothing);
      expect(store.shortfall, isNull);

      await tapComplete(tester);

      expect(find.byType(ShortfallSheet), findsOneWidget);
      expect(cookingApi.completeCalls, <bool>[false, false]);
    });

    testWidgets('store bỏ câu hỏi khi sheet đang mở → chỉ sheet đóng',
        (tester) async {
      stubShortfallThenOk();
      await pumpActive(tester);
      await tapComplete(tester);
      expect(find.byType(ShortfallSheet), findsOneWidget);

      store.dismissShortfall();
      await tester.pumpAndSettle();

      expect(find.byType(ShortfallSheet), findsNothing);
      expect(find.byType(CookingSessionScene), findsOneWidget,
          reason: 'không pop nhầm màn nấu');
      expect(store.phase, CookingScreenPhase.active);
    });

    testWidgets('route khác đè lên sheet → store bỏ câu hỏi KHÔNG pop route đó',
        (tester) async {
      stubShortfallThenOk();
      await pumpActive(tester);
      await tapComplete(tester);
      final sheetContext = tester.element(find.byType(ShortfallSheet));
      showDialog<void>(
        context: sheetContext,
        builder: (_) => const AlertDialog(content: Text('Dialog đè')),
      );
      await tester.pumpAndSettle();

      store.dismissShortfall();
      await tester.pumpAndSettle();

      expect(find.text('Dialog đè'), findsOneWidget);
      expect(find.byType(CookingSessionScene), findsOneWidget);
    });

    testWidgets('409 không có chi tiết → câu chung, vẫn có 2 nút',
        (tester) async {
      cookingApi.onCompleteError = shortfallError();
      await pumpActive(tester);

      await tapComplete(tester);

      expect(find.text('Không lấy được danh sách nguyên liệu thiếu.'),
          findsOneWidget);
      expect(find.text('Hoàn tất dù thiếu (trừ phần đang có)'),
          findsOneWidget);
      expect(find.text('Quay lại nấu'), findsOneWidget);
    });
  });
}
