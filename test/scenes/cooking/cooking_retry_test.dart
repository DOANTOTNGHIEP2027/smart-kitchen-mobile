import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
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

  CookingSession session({CookingSessionStatusWire status = CookingSessionStatusWire.inProgress, int currentStep = 1, int totalSteps = 1}) => CookingSession(
        id: 's1',
        householdId: 'h1',
        recipeId: 'r1',
        recipeName: 'Canh chua',
        startedBy: 'u1',
        status: status,
        currentStep: currentStep,
        totalSteps: totalSteps,
        startedAt: DateTime.parse('2026-09-16T07:00:00Z'),
        endedAt: null,
      );

  setUp(() {
    completeCalls = 0;
    cookingApi = FakeCookingApi()
      ..onStart = ((_) async => session())
      ..onCompleteError = BusinessException('ERR_SESSION_COMPLETE_CONFLICT', 'deadlock')
      ..onAbandonError = NetworkException();
    recipeApi = FakeRecipeApi()
      ..onGetSteps = ((_) async => const <CookingSessionStep>[
            // Có timer → Observer build lại mỗi giây.
            CookingSessionStep(stepNumber: 1, instruction: 'Nấu', durationSeconds: 300),
          ]);
  });

  CookingSessionStore newStore() => CookingSessionStore(
        cookingApi: cookingApi,
        recipeApi: recipeApi,
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
    test('complete lỗi → retryLastAction gọi lại complete (không chỉ xoá lỗi)', () async {
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

    test('abandon lỗi → KHÔNG có retry từ snackbar (dialog Huỷ bỏ tự bấm lại)', () async {
      final store = newStore();
      await store.init();
      await store.abandon();
      expect(store.actionError, isNotNull);
      expect(store.canRetryAction, isFalse);
      store.dispose();
    });

    test('advance lỗi, đang xem lại bước cũ → retry quay về bước hiện tại rồi advance thật', () async {
      cookingApi
        ..onStart = ((_) async => session(currentStep: 2, totalSteps: 3))
        ..onAdvanceStepError = NetworkException();
      final store = newStore();
      await store.init();
      await store.advanceOrComplete();
      store.viewPreviousStep();
      expect(store.isViewingCurrentStep, isFalse);

      var advanced = 0;
      cookingApi
        ..onAdvanceStepError = null
        ..onAdvanceStep = (_, step) async {
          advanced++;
          return session(currentStep: step, totalSteps: 3);
        };
      await store.retryLastAction();
      expect(advanced, 1);
      expect(store.session!.currentStep, 3);
      store.dispose();
    });

    test('thao tác MỚI bắt đầu → huỷ retry cũ (không advance 2 lần)', () async {
      cookingApi
        ..onStart = ((_) async => session(totalSteps: 3))
        ..onAdvanceStepError = NetworkException();
      final store = newStore();
      await store.init();
      await store.advanceOrComplete();
      var advanced = 0;
      cookingApi
        ..onAdvanceStepError = null
        ..onAdvanceStep = (_, step) async {
          advanced++;
          return session(currentStep: step, totalSteps: 3);
        };
      await store.advanceOrComplete(); // người dùng bấm thẳng nút chính
      expect(store.canRetryAction, isFalse);
      await store.retryLastAction(); // bấm "Thử lại" trên snackbar cũ
      expect(advanced, 1);
      expect(store.session!.currentStep, 2);
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

  group('widget', () {
    late CookingSessionStore store;

    setUp(() {
      // WakelockPlus gọi kênh pigeon — trả "thành công" để không ném lỗi.
      for (final api in <String>['toggle', 'isEnabled']) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$api',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[api == 'isEnabled' ? false : null]),
        );
      }
      store = newStore();
      Get.put<CookingSessionStore>(store);
    });
    tearDown(Get.reset);

    Future<void> pumpActive(WidgetTester tester) async {
      await tester.pumpAppWidget(const CookingSessionScene(), wrapInScaffold: false);
      await tester.pump();
      await tester.pump();
      expect(store.phase, CookingScreenPhase.active);
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox()); // dispose → huỷ timer của store
    }

    testWidgets('snackbar lỗi hiện ĐÚNG 1 lần dù timer build lại mỗi giây', (tester) async {
      await pumpActive(tester);
      await store.complete();
      await tester.pumpAndSettle();
      // Có "Thử lại" → SnackBar persist (Flutter: action != null) — ở lại tới khi
      // người dùng xử lý; nếu xếp hàng 1 cái/giây thì đóng cái này sẽ lộ cái kế.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.byType(SnackBar), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(SnackBar))).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(store.actionError, isNull, reason: 'snackbar bị ẩn → lỗi không còn UI, phải dọn');
      await unmount(tester);
    });

    testWidgets('lỗi không retry được (abandon) → snackbar KHÔNG có "Thử lại", tự ẩn → dọn lỗi', (tester) async {
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

    testWidgets('lỗi đã bị xoá bởi thao tác mới → snackbar "Thử lại" (persist) tự ẩn, không treo', (tester) async {
      cookingApi.onAdvanceStepError = NetworkException();
      cookingApi.onStart = ((_) async => session(totalSteps: 3));
      await pumpActive(tester);
      await store.advanceOrComplete();
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);

      // Người dùng bấm thẳng nút chính, lần này thành công.
      cookingApi
        ..onAdvanceStepError = null
        ..onAdvanceStep = (_, step) async => session(currentStep: step, totalSteps: 3);
      await store.advanceOrComplete();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
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
