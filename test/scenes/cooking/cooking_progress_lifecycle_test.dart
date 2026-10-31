import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/data/db/read_cache_dao.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/data/cooking_progress_store.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_result.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/domain/cooking_session_step.dart';
import 'package:smart_kitchen_mobile/scenes/cooking/stores/cooking_session_store.dart';

import 'fake_cooking_api.dart';

const progressKey = 'cooking-progress:v1:u:h:s';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  CookingSessionStore screen(CookingProgressCoordinator progress,
      {CookingSessionStatusWire status = CookingSessionStatusWire.inProgress}) {
    final session = CookingSession(
      id: 's',
      householdId: 'h',
      recipeId: 'r',
      recipeName: 'Rice',
      startedBy: 'u',
      status: status,
      totalSteps: 4,
      startedAt: DateTime.utc(2026),
    );
    final api = FakeCookingApi()
      ..onGetById =
          (_) async => CookingSessionResult(session: session, deductions: []);
    final recipes = FakeRecipeApi()
      ..onGetSteps = (_) async => List.generate(
          4, (i) => CookingSessionStep(stepNumber: i + 1, instruction: 'Step'));
    final store = CookingSessionStore(
      cookingApi: api,
      recipeApi: recipes,
      progressStore: progress,
      userId: 'u',
      entryMode: CookingEntryMode.resume,
      sessionId: 's',
    );
    addTearDown(store.dispose);
    return store;
  }

  test(
      'FE-R1: reopening waits for old writes and preserves subsequent navigation',
      () async {
    final cache = DelayedWriteCache(db);
    final progress =
        CookingProgressCoordinator(DriftCookingProgressStore(cache));
    final old = screen(progress);
    await old.init();
    final oldWrite = old.advanceOrComplete();
    await cache.started.future;
    old.dispose();

    final reopened = screen(progress);
    var loaded = false;
    final opening = reopened.init().then((_) => loaded = true);
    await Future<void>.delayed(Duration.zero);
    expect(loaded, isFalse,
        reason: 'resume must join the outstanding write queue');
    cache.release.complete();
    await oldWrite;
    await opening;
    expect(reopened.currentStep, 2);
    await reopened.advanceOrComplete();
    expect(reopened.currentStep, 3);
    expect(await progress.read('u', 'h', 's'), 3);

    final thirdScreen = screen(progress);
    await thirdScreen.init();
    expect(thirdScreen.currentStep, 3);
  });

  test(
      'FE-R1: terminal session clear runs after pending writes from disposed screen',
      () async {
    final cache = DelayedWriteCache(db);
    final progress =
        CookingProgressCoordinator(DriftCookingProgressStore(cache));
    final old = screen(progress);
    await old.init();
    final oldWrite = old.advanceOrComplete();
    await cache.started.future;
    old.dispose();
    final terminal =
        screen(progress, status: CookingSessionStatusWire.completed);
    final opening = terminal.init();
    await Future<void>.delayed(Duration.zero);
    expect(terminal.phase, CookingScreenPhase.completed);
    cache.release.complete();
    await Future.wait([oldWrite, opening]);
    expect(await progress.read('u', 'h', 's'), isNull);
    expect(await ReadCacheDao(db).get(progressKey), isNull);
  });

  test(
      'FE-R2: failed read keeps valid cached progress and the next resume recovers it',
      () async {
    await ReadCacheDao(db).put(progressKey, {'version': 1, 'step': 3});
    final cache = ReadOnceFailCache(db);
    final progress =
        CookingProgressCoordinator(DriftCookingProgressStore(cache));
    final first = screen(progress);
    await first.init();
    expect(first.phase, CookingScreenPhase.active);
    expect(first.currentStep, 1);
    expect((await ReadCacheDao(db).get(progressKey))!.payload['step'], 3);
    expect(cache.writes, 0,
        reason: 'fallback during init must never enqueue a write');
    first.dispose();

    final reopened = screen(progress);
    await reopened.init();
    expect(reopened.currentStep, 3);
    await reopened.advanceOrComplete();
    expect(await progress.read('u', 'h', 's'), 4);
  });

  test(
      'load is read-only for missing/invalid data and still clamps valid progress',
      () async {
    final progress =
        CookingProgressCoordinator(DriftCookingProgressStore(ReadCacheDao(db)));
    final missing = screen(progress);
    await missing.init();
    expect(missing.currentStep, 1);
    expect(await ReadCacheDao(db).get(progressKey), isNull);
    missing.dispose();

    await ReadCacheDao(db).put(progressKey, {'version': 1, 'step': 'bad'});
    final invalid = screen(progress);
    await invalid.init();
    expect(invalid.currentStep, 1);
    await invalid.advanceOrComplete();
    expect(await progress.read('u', 'h', 's'), 2);
    invalid.dispose();

    await progress.write('u', 'h', 's', 99);
    final clamped = screen(progress);
    await clamped.init();
    expect(clamped.currentStep, 4);
    expect(clamped.isLastStep, isTrue);
  });

  test('a failed write does not poison later clear/read operations for its key',
      () async {
    final progress = CookingProgressCoordinator(
        DriftCookingProgressStore(WriteOnceFailCache(db)));
    final failed = progress.write('u', 'h', 's', 2);
    final clear = progress.clear('u', 'h', 's');
    await expectLater(failed, throwsStateError);
    await clear;
    expect(await progress.read('u', 'h', 's'), isNull);
    await progress.write('u', 'h', 's', 3);
    expect(await progress.read('u', 'h', 's'), 3);
  });

  test('a blocked key does not block a different household and user key',
      () async {
    final cache = DelayedWriteCache(db);
    final progress =
        CookingProgressCoordinator(DriftCookingProgressStore(cache));
    final blocked = progress.write('u', 'h', 's', 2);
    await cache.started.future;
    await progress.write('other', 'other-household', 's', 3);
    expect(await progress.read('other', 'other-household', 's'), 3);
    cache.release.complete();
    await blocked;
    expect(await progress.read('u', 'h', 's'), 2);
  });
}

/// Keep real Drift serialization/cache format; only control the timing of one I/O.
class DelayedWriteCache extends ReadCacheDao {
  DelayedWriteCache(super.db);
  final started = Completer<void>();
  final release = Completer<void>();
  bool _blocked = false;

  @override
  Future<void> put(String key, Map<String, dynamic> payload) async {
    if (!_blocked && payload['step'] == 2) {
      _blocked = true;
      started.complete();
      await release.future;
    }
    await super.put(key, payload);
  }
}

class ReadOnceFailCache extends ReadCacheDao {
  ReadOnceFailCache(super.db);
  bool _failNextRead = true;
  int writes = 0;

  @override
  Future<CachedEntry?> get(String key) async {
    if (_failNextRead) {
      _failNextRead = false;
      throw StateError('transient read failure');
    }
    return super.get(key);
  }

  @override
  Future<void> put(String key, Map<String, dynamic> payload) async {
    writes++;
    await super.put(key, payload);
  }
}

class WriteOnceFailCache extends ReadCacheDao {
  WriteOnceFailCache(super.db);
  bool _failNextWrite = true;

  @override
  Future<void> put(String key, Map<String, dynamic> payload) async {
    if (_failNextWrite) {
      _failNextWrite = false;
      throw StateError('transient write failure');
    }
    await super.put(key, payload);
  }
}
