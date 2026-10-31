import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';
import 'package:smart_kitchen_mobile/data/network/api_exception.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_result.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/ingredient_deduction.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_session_store.dart';

import 'fake_cooking_api.dart';

void main() {
  late FakeCookingApi cookingApi;
  late FakeRecipeApi recipeApi;

  setUp(() {
    cookingApi = FakeCookingApi();
    recipeApi = FakeRecipeApi();
  });

  CookingSession session({
    String id = 's1',
    CookingSessionStatusWire status = CookingSessionStatusWire.inProgress,
    int totalSteps = 3,
  }) {
    return CookingSession(
      id: id,
      householdId: 'h1',
      recipeId: 'r1',
      recipeName: 'Canh chua',
      startedBy: 'u1',
      status: status,
      totalSteps: totalSteps,
      startedAt: DateTime.parse('2026-09-16T07:00:00Z'),
      endedAt: null,
    );
  }

  List<CookingSessionStep> steps() => const <CookingSessionStep>[
        CookingSessionStep(
            stepNumber: 1, instruction: 'Sơ chế', durationSeconds: 300),
        CookingSessionStep(stepNumber: 2, instruction: 'Nấu'),
        CookingSessionStep(stepNumber: 3, instruction: 'Thưởng thức'),
      ];

  CookingSessionStore startStore() {
    return CookingSessionStore(
      cookingApi: cookingApi,
      recipeApi: recipeApi,
      progressStore: CookingProgressCoordinator(MemoryProgressStore()),
      userId: 'u1',
      entryMode: CookingEntryMode.start,
      recipeId: 'r1',
    );
  }

  group('init — entryMode start', () {
    test('success → phase=active + session/steps load + viewedStep=1',
        () async {
      cookingApi.onStart = (recipeId) async => session();
      recipeApi.onGetSteps = (_) async => steps();

      final store = startStore();
      await store.init();

      expect(store.phase, CookingScreenPhase.active);
      expect(store.session, isNotNull);
      expect(store.currentStep, 1);
      expect(store.steps.length, 3);
      expect(store.viewedStep, 1);
    });

    test('recipe fetch lỗi (sau start OK) → phase=error + loadErrorIsRetryable',
        () async {
      cookingApi.onStart = (_) async => session();
      recipeApi.onGetStepsError = NetworkException();

      final store = startStore();
      await store.init();

      expect(store.phase, CookingScreenPhase.error);
      expect(store.loadError, isA<NetworkException>());
      expect(store.loadErrorIsRetryable, isTrue,
          reason: 'NetworkException → user có thể Thử lại');
    });

    test('ERR_SESSION_RECIPE_NOT_FOUND → loadErrorIsRetryable = false',
        () async {
      cookingApi.onStartError =
          BusinessException('ERR_SESSION_RECIPE_NOT_FOUND', 'not found');

      final store = startStore();
      await store.init();

      expect(store.phase, CookingScreenPhase.error);
      expect(store.loadErrorIsRetryable, isFalse,
          reason: 'id/recipe sai — gọi lại chỉ lặp lại đúng lỗi');
    });

    test('ERR_SESSION_NOT_FOUND → loadErrorIsRetryable = false', () async {
      cookingApi.onStartError =
          BusinessException('ERR_SESSION_NOT_FOUND', 'not found');
      final store = CookingSessionStore(
        cookingApi: cookingApi,
        recipeApi: recipeApi,
        progressStore: CookingProgressCoordinator(MemoryProgressStore()),
        userId: 'u1',
        entryMode: CookingEntryMode.resume,
        sessionId: 's1',
      );
      cookingApi.onGetByIdError =
          BusinessException('ERR_SESSION_NOT_FOUND', 'not found');

      await store.init();

      expect(store.phase, CookingScreenPhase.error);
      expect(store.loadErrorIsRetryable, isFalse);
    });
  });

  group('retryLoad — không gọi start() lần 2 (Guard §9.9)', () {
    test('sessionId có sẵn + steps rỗng → gọi getSteps lại, không gọi start',
        () async {
      var startCallCount = 0;
      cookingApi.onStart = (_) async {
        startCallCount++;
        return session();
      };
      // Cung cấp getById cho retry (vì _session.value có thể chưa gán khi
      // getSteps fail lần đầu).
      cookingApi.onGetById = (id) async => CookingSessionResult(
            session: session(),
            deductions: const <IngredientDeduction>[],
          );
      var getStepsCallCount = 0;
      recipeApi.onGetSteps = (_) async {
        getStepsCallCount++;
        if (getStepsCallCount == 1) throw NetworkException();
        return steps();
      };

      final store = startStore();
      await store.init();
      expect(startCallCount, 1);
      expect(getStepsCallCount, 1);
      expect(store.phase, CookingScreenPhase.error);

      await store.retryLoad();

      expect(startCallCount, 1,
          reason: 'PHẢI KHÔNG gọi start() lần 2 — sẽ tạo session mồ côi');
      expect(getStepsCallCount, 2);
      expect(store.phase, CookingScreenPhase.active);
    });
  });

  group('complete — 3 nhánh DoD FE-6', () {
    test('nhánh 1: đủ nguyên liệu (shortfall=0) → phase=completed', () async {
      cookingApi.onStart = (_) async => session(totalSteps: 1);
      recipeApi.onGetSteps = (_) async => const <CookingSessionStep>[
            CookingSessionStep(stepNumber: 1, instruction: 'Nấu'),
          ];
      cookingApi.onComplete = (id) async => CookingSessionResult(
            session: session(
              status: CookingSessionStatusWire.completed,
              totalSteps: 1,
            ),
            deductions: const <IngredientDeduction>[
              IngredientDeduction(
                ingredientName: 'Cá lóc',
                requiredQuantity: 500,
                requiredUnit: 'GRAM',
                deductedQuantity: 500,
                shortfallQuantity: 0,
                matchedItemCount: 1,
              ),
            ],
          );

      final store = startStore();
      await store.init();
      await store.complete();

      expect(store.phase, CookingScreenPhase.completed);
      expect(store.deductions.first.hasShortfall, isFalse);
    });

    test(
        'nhánh 2: THIẾU nguyên liệu (shortfall>0) → phase=completed vẫn, '
        'UI show hasShortfall=true — KHÔNG rollback', () async {
      cookingApi.onStart = (_) async => session(totalSteps: 1);
      recipeApi.onGetSteps = (_) async => const <CookingSessionStep>[
            CookingSessionStep(stepNumber: 1, instruction: 'Nấu'),
          ];
      // OD-04: BE trả 200 với shortfall trong deductions (KHÔNG raise lỗi).
      cookingApi.onComplete = (id) async => CookingSessionResult(
            session: session(
                status: CookingSessionStatusWire.completed, totalSteps: 1),
            deductions: const <IngredientDeduction>[
              IngredientDeduction(
                ingredientName: 'Cà chua',
                requiredQuantity: 200,
                requiredUnit: 'GRAM',
                deductedQuantity: 120,
                shortfallQuantity: 80,
                matchedItemCount: 2,
              ),
            ],
          );

      final store = startStore();
      await store.init();
      await store.complete();

      expect(store.phase, CookingScreenPhase.completed,
          reason: 'không có lỗi — phase chuyển completed');
      expect(store.deductions.first.hasShortfall, isTrue,
          reason: 'UI dùng flag này để warning badge');
      expect(store.actionError, isNull,
          reason: 'shortfall không phải actionError');
    });

    test('nhánh 3: 409 ERR_SESSION_ALREADY_ENDED → _resyncSessionFromServer()',
        () async {
      cookingApi.onStart = (_) async => session(totalSteps: 1);
      recipeApi.onGetSteps = (_) async => const <CookingSessionStep>[
            CookingSessionStep(stepNumber: 1, instruction: 'Nấu'),
          ];
      cookingApi.onCompleteError =
          BusinessException('ERR_SESSION_ALREADY_ENDED', 'ended elsewhere');
      cookingApi.onGetById = (id) async => CookingSessionResult(
            session: session(
              // Server bảo đã COMPLETED ở nơi khác
              status: CookingSessionStatusWire.completed,
              totalSteps: 1,
            ),
            deductions: const <IngredientDeduction>[],
          );

      final store = startStore();
      await store.init();
      await store.complete();

      expect(store.phase, CookingScreenPhase.completed,
          reason: 'resync phải resolve thẳng phase về completed');
      expect(store.actionError, isNull,
          reason: '409 ALREADY_ENDED không phải banner retry');
    });

    test('409 ERR_SESSION_COMPLETE_CONFLICT → actionError set (retry an toàn)',
        () async {
      cookingApi.onStart = (_) async => session(totalSteps: 1);
      recipeApi.onGetSteps = (_) async => const <CookingSessionStep>[
            CookingSessionStep(stepNumber: 1, instruction: 'Nấu'),
          ];
      cookingApi.onCompleteError =
          BusinessException('ERR_SESSION_COMPLETE_CONFLICT', 'deadlock');

      final store = startStore();
      await store.init();
      await store.complete();

      expect(store.phase, CookingScreenPhase.active,
          reason: 'session vẫn IN_PROGRESS — chưa complete đâu');
      expect(store.actionError!.code, 'ERR_SESSION_COMPLETE_CONFLICT');
    });
  });

  group('local progress', () {
    test('advance is local, review does not advance, last step completes',
        () async {
      cookingApi.onStart = (_) async => session();
      recipeApi.onGetSteps = (_) async => steps();
      cookingApi.onComplete = (_) async => CookingSessionResult(
          session: session(status: CookingSessionStatusWire.completed),
          deductions: const []);
      final store = startStore();
      addTearDown(store.dispose);
      await store.init();
      await store.advanceOrComplete();
      expect(store.currentStep, 2);
      store.viewPreviousStep();
      await store.advanceOrComplete();
      expect(store.currentStep, 2);
      store.returnToCurrentStep();
      await store.advanceOrComplete();
      expect(store.currentStep, 3);
      await store.advanceOrComplete();
      expect(store.phase, CookingScreenPhase.completed);
    });

    test('resume restores local progress and clamps to actual recipe steps',
        () async {
      final progress = MemoryProgressStore()..step = 99;
      cookingApi.onGetById = (_) async =>
          CookingSessionResult(session: session(), deductions: const []);
      recipeApi.onGetSteps = (_) async => steps().take(2).toList();
      final store = CookingSessionStore(
          cookingApi: cookingApi,
          recipeApi: recipeApi,
          progressStore: CookingProgressCoordinator(progress),
          userId: 'u1',
          entryMode: CookingEntryMode.resume,
          sessionId: 's1');
      addTearDown(store.dispose);
      await store.init();
      expect(store.currentStep, 2);
      expect(store.totalSteps, 2);
      expect(store.isLastStep, isTrue);
    });

    test('completed session clears local progress without fetching recipe',
        () async {
      final progress = MemoryProgressStore()..step = 2;
      cookingApi.onGetById = (_) async => CookingSessionResult(
          session: session(status: CookingSessionStatusWire.completed),
          deductions: const []);
      final store = CookingSessionStore(
          cookingApi: cookingApi,
          recipeApi: recipeApi,
          progressStore: CookingProgressCoordinator(progress),
          userId: 'u1',
          entryMode: CookingEntryMode.resume,
          sessionId: 's1');
      addTearDown(store.dispose);
      await store.init();
      expect(store.phase, CookingScreenPhase.completed);
      expect(progress.step, isNull);
    });

    test('storage errors do not block local navigation', () async {
      final progress = MemoryProgressStore()..fail = true;
      cookingApi.onGetById = (_) async =>
          CookingSessionResult(session: session(), deductions: const []);
      recipeApi.onGetSteps = (_) async => steps();
      final store = CookingSessionStore(
          cookingApi: cookingApi,
          recipeApi: recipeApi,
          progressStore: CookingProgressCoordinator(progress),
          userId: 'u1',
          entryMode: CookingEntryMode.resume,
          sessionId: 's1');
      addTearDown(store.dispose);
      await store.init();
      await store.advanceOrComplete();
      expect(store.currentStep, 2);
      expect(store.phase, CookingScreenPhase.active);
    });

    test('rapid advances persist in order; failed completion retains progress',
        () async {
      final progress = DelayedProgressStore();
      cookingApi.onStart = (_) async => session();
      recipeApi.onGetSteps = (_) async => steps();
      cookingApi.onCompleteError = NetworkException();
      final store = CookingSessionStore(
          cookingApi: cookingApi,
          recipeApi: recipeApi,
          progressStore: CookingProgressCoordinator(progress),
          userId: 'u1',
          entryMode: CookingEntryMode.start,
          recipeId: 'r1');
      addTearDown(store.dispose);
      await store.init();
      final first = store.advanceOrComplete();
      final second = store.advanceOrComplete();
      expect(store.currentStep, 3);
      progress.release.complete();
      await Future.wait([first, second]);
      expect(progress.writes, [2, 3]);
      await store.complete();
      expect(store.phase, CookingScreenPhase.active);
      expect(progress.step, 3);
      expect(store.currentStep, 3);
      cookingApi.onAbandon =
          (_) async => session(status: CookingSessionStatusWire.abandoned);
      await store.abandon();
      expect(progress.step, isNull);
    });

    test('empty recipe is a load error instead of an invalid step index',
        () async {
      cookingApi.onStart = (_) async => session();
      recipeApi.onGetSteps = (_) async => [];
      final store = startStore();
      addTearDown(store.dispose);
      await store.init();
      expect(store.phase, CookingScreenPhase.error);
      expect(store.loadError?.code, 'ERR_SESSION_RECIPE_NO_STEPS');
    });
  });

  group('abandon', () {
    test('success → phase=abandoned, actionError null', () async {
      cookingApi.onStart = (_) async => session();
      recipeApi.onGetSteps = (_) async => steps();
      cookingApi.onAbandon =
          (id) async => session(status: CookingSessionStatusWire.abandoned);

      final store = startStore();
      await store.init();
      await store.abandon();

      expect(store.phase, CookingScreenPhase.abandoned);
      expect(store.actionError, isNull);
    });
  });

  test('dispose huỷ timer không crash', () {
    final store = CookingSessionStore(
      cookingApi: cookingApi,
      recipeApi: recipeApi,
      progressStore: CookingProgressCoordinator(MemoryProgressStore()),
      userId: 'u1',
      entryMode: CookingEntryMode.start,
      recipeId: 'r1',
    );
    // dispose khi chưa start cũng phải an toàn
    store.dispose();
    expect(true, isTrue); // pass nếu không throw
  });
}

class MemoryProgressStore implements CookingProgressStore {
  int? step;
  bool fail = false;
  @override
  Future<int?> read(String userId, String householdId, String sessionId) async {
    if (fail) throw StateError('storage unavailable');
    return step;
  }

  @override
  Future<void> write(
      String userId, String householdId, String sessionId, int value) async {
    if (fail) throw StateError('storage unavailable');
    step = value;
  }

  @override
  Future<void> clear(
      String userId, String householdId, String sessionId) async {
    step = null;
  }
}

class DelayedProgressStore extends MemoryProgressStore {
  final release = Completer<void>();
  final writes = <int>[];
  @override
  Future<void> write(
      String userId, String householdId, String sessionId, int value) async {
    if (value == 2) await release.future;
    writes.add(value);
    await super.write(userId, householdId, sessionId, value);
  }
}
