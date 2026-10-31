import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobx/mobx.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_result.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/ingredient_deduction.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/scenes/cooking_session_scene.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_session_store.dart';

import '../../helpers/pump_app.dart';
import 'fake_cooking_api.dart';

/// OD-18: "Thử lại" gọi lại đúng thao tác vừa lỗi; snackbar lỗi chỉ hiện 1 lần
/// dù Observer build lại mỗi giây; snackbar ẩn → lỗi được dọn khỏi store.
void main() {
  late FakeCookingApi cookingApi;
  late FakeRecipeApi recipeApi;
  var completeCalls = 0;

  CookingSession session(
          {CookingSessionStatusWire status =
              CookingSessionStatusWire.inProgress,
          int totalSteps = 1}) =>
      CookingSession(
        id: 's1',
        householdId: 'h1',
        recipeId: 'r1',
        recipeName: 'Canh chua',
        startedBy: 'u1',
        status: status,
        totalSteps: totalSteps,
        startedAt: DateTime.parse('2026-09-16T07:00:00Z'),
        endedAt: null,
      );

  setUp(() {
    completeCalls = 0;
    cookingApi = FakeCookingApi()
      ..onStart = ((_) async => session())
      ..onCompleteError =
          BusinessException('ERR_SESSION_COMPLETE_CONFLICT', 'deadlock')
      ..onAbandonError = NetworkException();
    recipeApi = FakeRecipeApi()
      ..onGetSteps = ((_) async => const <CookingSessionStep>[
            // Có timer → Observer build lại mỗi giây.
            CookingSessionStep(
                stepNumber: 1, instruction: 'Nấu', durationSeconds: 300),
            CookingSessionStep(stepNumber: 2, instruction: 'Nấu tiếp'),
            CookingSessionStep(stepNumber: 3, instruction: 'Xong'),
          ]);
  });

  CookingSessionStore newStore() => CookingSessionStore(
        cookingApi: cookingApi,
        recipeApi: recipeApi,
        progressStore: CookingProgressCoordinator(_MemoryProgress()),
        userId: 'u1',
        entryMode: CookingEntryMode.start,
        recipeId: 'r1',
      );

  void completeSucceeds() {
    cookingApi
      ..onCompleteError = null
      ..onComplete = (_) async {
        completeCalls++;
        return CookingSessionResult(
          session: session(status: CookingSessionStatusWire.completed),
          deductions: const <IngredientDeduction>[],
        );
      };
  }

  group('store', () {
    test('complete lỗi → retryLastAction gọi lại complete (không chỉ xoá lỗi)',
        () async {
      final store = newStore();
      await store.init();
      await store.complete();
      expect(store.actionError, isNotNull);
      expect(store.canRetryAction, isTrue);

      completeSucceeds();
      await store.retryLastAction();
      expect(completeCalls, 1);
      expect(store.phase, CookingScreenPhase.completed);
      expect(store.actionError, isNull);
      store.dispose();
    });

    test('abandon lỗi → KHÔNG có retry từ snackbar (dialog Huỷ bỏ tự bấm lại)',
        () async {
      final store = newStore();
      await store.init();
      await store.abandon();
      expect(store.actionError, isNotNull);
      expect(store.canRetryAction, isFalse);
      store.dispose();
    });

    test('tiến bước local không tạo retry mạng', () async {
      cookingApi.onStart = (_) async => session(totalSteps: 3);
      final store = newStore();
      await store.init();
      await store.advanceOrComplete();
      expect(store.currentStep, 2);
      expect(store.actionError, isNull);
      expect(store.canRetryAction, isFalse);
      store.dispose();
    });

    test('tiến bước local mới huỷ retry complete cũ', () async {
      cookingApi.onStart = (_) async => session(totalSteps: 3);
      final store = newStore();
      await store.init();
      await store.complete();
      expect(store.canRetryAction, isTrue);
      await store.advanceOrComplete();
      expect(store.canRetryAction, isFalse);
      completeSucceeds();
      await store.retryLastAction();
      expect(completeCalls, 0);
      expect(store.currentStep, 2);
      store.dispose();
    });

    test('clearActionError xoá luôn thao tác chờ retry', () async {
      final store = newStore();
      await store.init();
      await store.complete();
      store.clearActionError();
      expect(store.canRetryAction, isFalse);
      completeSucceeds();
      await store.retryLastAction();
      expect(completeCalls, 0);
      store.dispose();
    });
  });

  group('OD-27', () {
    test(
        'lỗi chắc chắn lặp lại (AuthExpired, ERR_SESSION_NOT_FOUND/NO_HOUSEHOLD) → KHÔNG có retry',
        () async {
      for (final err in <ApiException>[
        AuthExpiredException('ERR_AUTH_EXPIRED', 'expired'),
        BusinessException('ERR_SESSION_NOT_FOUND', 'x'),
        BusinessException('ERR_SESSION_NO_HOUSEHOLD', 'x'),
      ]) {
        cookingApi.onCompleteError = err;
        final store = newStore();
        await store.init();
        await store.complete();
        expect(store.actionError, same(err));
        expect(store.canRetryAction, isFalse, reason: err.code);
        store.dispose();
      }
    });

    test(
        'retry complete khi đang xem bước cũ → quay về bước hiện tại TRƯỚC khi gọi API',
        () async {
      cookingApi.onStart = (_) async => session(totalSteps: 3);
      recipeApi.onGetSteps = (_) async => const <CookingSessionStep>[
            CookingSessionStep(stepNumber: 1, instruction: 'A'),
            CookingSessionStep(stepNumber: 2, instruction: 'B'),
            CookingSessionStep(stepNumber: 3, instruction: 'C'),
          ];
      final store = newStore();
      await store.init();
      await store.advanceOrComplete();
      await store.advanceOrComplete();
      await store.complete();
      store.viewPreviousStep();
      expect(store.isViewingCurrentStep, isFalse);
      bool? viewingCurrentAtCall;
      cookingApi
        ..onCompleteError = null
        ..onComplete = (_) async {
          viewingCurrentAtCall = store.isViewingCurrentStep;
          return CookingSessionResult(
            session: session(
                status: CookingSessionStatusWire.completed, totalSteps: 3),
            deductions: const <IngredientDeduction>[],
          );
        };
      await store.retryLastAction();
      expect(viewingCurrentAtCall, isTrue);
      expect(store.phase, CookingScreenPhase.completed);
      store.dispose();
    });

    test('resync đang chạy → isResyncing = true (nút chính khoá), xong → false',
        () async {
      cookingApi
        ..onStart = ((_) async => session(totalSteps: 3))
        ..onCompleteError =
            BusinessException('ERR_SESSION_ALREADY_ENDED', 'stale');
      final gate = Completer<void>();
      cookingApi.onGetById = (_) async {
        await gate.future;
        return CookingSessionResult(
            session: session(totalSteps: 3),
            deductions: const <IngredientDeduction>[]);
      };
      final store = newStore();
      await store.init();
      final advancing = store.complete();
      await Future<void>.delayed(Duration.zero);
      expect(store.isResyncing, isTrue);
      gate.complete();
      await advancing;
      expect(store.isResyncing, isFalse);
      expect(store.currentStep, 1);
      store.dispose();
    });

    test(
        'ValidationException (400) → KHÔNG có retry (gửi lại y nguyên vẫn 400)',
        () async {
      cookingApi.onCompleteError = ValidationException(
          'ERR_VALIDATION_FAILED', 'bad',
          fieldErrors: const <String, String>{});
      final store = newStore();
      await store.init();
      await store.complete();
      expect(store.canRetryAction, isFalse);
      store.dispose();
    });

    test(
        '"Thử lại" resync từ snackbar → isResyncing khoá nút (complete KHÔNG bật)',
        () async {
      cookingApi
        ..onStart = ((_) async => session(totalSteps: 3))
        ..onCompleteError =
            BusinessException('ERR_SESSION_ALREADY_ENDED', 'stale')
        ..onGetByIdError = NetworkException();
      final store = newStore();
      await store.init();
      await store.complete(); // resync lỗi → retry = resync
      expect(store.canRetryAction, isTrue);
      final gate = Completer<void>();
      cookingApi
        ..onGetByIdError = null
        ..onGetById = (_) async {
          await gate.future;
          return CookingSessionResult(
              session: session(totalSteps: 3),
              deductions: const <IngredientDeduction>[]);
        };
      final retrying = store.retryLastAction();
      await Future<void>.delayed(Duration.zero);
      expect(store.isCompleting, isFalse);
      expect(store.isResyncing, isTrue);
      gate.complete();
      await retrying;
      expect(store.isResyncing, isFalse);
      store.dispose();
    });

    test('GET resync về muộn SAU khi đã huỷ bỏ → bỏ qua, phase giữ abandoned',
        () async {
      cookingApi
        ..onCompleteError =
            BusinessException('ERR_SESSION_ALREADY_ENDED', 'stale')
        ..onGetByIdError = NetworkException()
        ..onAbandonError = null
        ..onAbandon =
            (_) async => session(status: CookingSessionStatusWire.abandoned);
      final store = newStore();
      await store.init();
      await store.complete();
      expect(store.canRetryAction, isTrue);
      final gate = Completer<void>();
      cookingApi
        ..onGetByIdError = null
        ..onGetById = (_) async {
          await gate.future;
          return CookingSessionResult(session: session(), deductions: const []);
        };
      final resync = store.retryLastAction();
      await Future<void>.delayed(Duration.zero);
      await store.abandon();
      expect(store.phase, CookingScreenPhase.abandoned);
      gate.complete();
      await resync;
      expect(store.phase, CookingScreenPhase.abandoned);
      expect(store.timerRunning, isFalse);
      store.dispose();
    });

    test('canRetryAction là Observable — reaction thấy khi retry được gắn/xoá',
        () async {
      final store = newStore();
      await store.init();
      final seen = <bool>[];
      final dispose = reaction<bool>((_) => store.canRetryAction, seen.add);
      await store.complete();
      store.clearActionError();
      dispose();
      expect(seen, <bool>[true, false]);
      store.dispose();
    });
  });

  group('widget', () {
    late CookingSessionStore store;

    setUp(() {
      // WakelockPlus gọi kênh pigeon — trả "thành công" để không ném lỗi.
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

    Future<void> unmount(WidgetTester tester) async {
      await tester
          .pumpWidget(const SizedBox()); // dispose → huỷ timer của store
    }

    testWidgets('snackbar lỗi hiện ĐÚNG 1 lần dù timer build lại mỗi giây',
        (tester) async {
      await pumpActive(tester);
      await store.complete();
      await tester.pumpAndSettle();
      // Có "Thử lại" → SnackBar persist (Flutter: action != null) — ở lại tới khi
      // người dùng xử lý; nếu xếp hàng 1 cái/giây thì đóng cái này sẽ lộ cái kế.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(SnackBar), findsOneWidget);
      // Người dùng vuốt bỏ → lỗi không còn UI, phải dọn.
      ScaffoldMessenger.of(tester.element(find.byType(SnackBar)))
          .removeCurrentSnackBar(reason: SnackBarClosedReason.swipe);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(store.actionError, isNull,
          reason: 'snackbar bị vuốt → lỗi không còn UI, phải dọn');
      await unmount(tester);
    });

    testWidgets(
        'snackbar khác (thông báo toàn cục) đẩy snackbar lỗi ra → lỗi GIỮ, "Thử lại" hiện lại sau đó',
        (tester) async {
      await pumpActive(tester);
      await store.complete();
      await tester.pumpAndSettle();
      final messenger =
          ScaffoldMessenger.of(tester.element(find.byType(SnackBar)));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('push'), duration: Duration(seconds: 2)));
      await tester.pumpAndSettle();
      expect(store.actionError, isNotNull);
      expect(find.text('push'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('push'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets(
        'rời màn khi snackbar "Thử lại" đang hiện → snackbar đóng, không treo sang màn khác',
        (tester) async {
      await pumpActive(tester);
      await store.complete();
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
      await tester.pumpAppWidget(const Text('màn khác'));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsNothing);
      expect(store.actionError, isNull);
    });

    testWidgets(
        'lỗi không retry được (abandon) → snackbar KHÔNG có "Thử lại", tự ẩn → dọn lỗi',
        (tester) async {
      await pumpActive(tester);
      await store.abandon();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(store.actionError, isNull);
      await unmount(tester);
    });

    testWidgets('lỗi đã bị xoá bởi bước local mới → snackbar cũ tự ẩn',
        (tester) async {
      cookingApi.onStart = (_) async => session(totalSteps: 3);
      await pumpActive(tester);
      await store.complete();
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
      await store.advanceOrComplete();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      await unmount(tester);
    });

    testWidgets(
        'lỗi không retry được (ERR_SESSION_NOT_FOUND) → snackbar KHÔNG có "Thử lại"',
        (tester) async {
      cookingApi.onCompleteError =
          BusinessException('ERR_SESSION_NOT_FOUND', 'x');
      await pumpActive(tester);
      await store.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
      await unmount(tester);
    });

    testWidgets('bấm "Thử lại" → gọi lại complete thật', (tester) async {
      await pumpActive(tester);
      await store.complete();
      await tester.pumpAndSettle();
      completeSucceeds();
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump();
      expect(completeCalls, 1);
      expect(store.phase, CookingScreenPhase.completed);
      await unmount(tester);
    });
  });
}

class _MemoryProgress implements CookingProgressStore {
  int? _step;
  @override
  Future<int?> read(String user, String household, String session) async =>
      _step;
  @override
  Future<void> write(
      String user, String household, String session, int step) async {
    _step = step;
  }

  @override
  Future<void> clear(String user, String household, String session) async {
    _step = null;
  }
}
