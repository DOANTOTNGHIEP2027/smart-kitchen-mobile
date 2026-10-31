import 'dart:async';

import '../../../data/db/read_cache_dao.dart';

/// Device-local progress, isolated by authenticated user, household and session.
abstract interface class CookingProgressStore {
  Future<int?> read(String userId, String householdId, String sessionId);
  Future<void> write(
      String userId, String householdId, String sessionId, int step);
  Future<void> clear(String userId, String householdId, String sessionId);
}

/// Shared for the app lifetime. Reads join the same queue as writes/clear so
/// reopening a screen cannot race outstanding operations from its predecessor.
class CookingProgressCoordinator implements CookingProgressStore {
  CookingProgressCoordinator(this._storage);

  final CookingProgressStore _storage;
  final _tails = <(String, String, String), Future<void>>{};

  Future<T> _run<T>(
      (String, String, String) key, Future<T> Function() operation) {
    final result =
        (_tails[key] ?? Future<void>.value()).then<T>((_) => operation());
    // Keep the queue usable after an I/O failure while returning the original
    // error to the caller that owns the UI fallback/logging decision.
    final tail =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _tails[key] = tail;
    unawaited(tail.then((_) {
      if (identical(_tails[key], tail)) _tails.remove(key);
    }));
    return result;
  }

  @override
  Future<int?> read(String userId, String householdId, String sessionId) =>
      _run((userId, householdId, sessionId),
          () => _storage.read(userId, householdId, sessionId));

  @override
  Future<void> write(
          String userId, String householdId, String sessionId, int step) =>
      _run((userId, householdId, sessionId),
          () => _storage.write(userId, householdId, sessionId, step));

  @override
  Future<void> clear(String userId, String householdId, String sessionId) =>
      _run((userId, householdId, sessionId),
          () => _storage.clear(userId, householdId, sessionId));
}

class DriftCookingProgressStore implements CookingProgressStore {
  DriftCookingProgressStore(this._cache);
  final ReadCacheDao _cache;

  String _key(String user, String household, String session) =>
      'cooking-progress:v1:$user:$household:$session';

  @override
  Future<int?> read(String userId, String householdId, String sessionId) async {
    final entry = await _cache.get(_key(userId, householdId, sessionId));
    final payload = entry?.payload;
    if (payload == null || payload['version'] != 1) return null;
    final step = payload['step'];
    return step is int && step > 0 ? step : null;
  }

  @override
  Future<void> write(
          String userId, String householdId, String sessionId, int step) =>
      _cache.put(
          _key(userId, householdId, sessionId), {'version': 1, 'step': step});

  @override
  Future<void> clear(String userId, String householdId, String sessionId) =>
      _cache.remove(_key(userId, householdId, sessionId));
}
