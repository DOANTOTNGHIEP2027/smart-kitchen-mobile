import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../data/meal_composition_api.dart';
import '../domain/meal_composition.dart';
import 'meal_plan_store.dart';

/// Automatic composition owns its request lifecycle independently of week loading.
class MealCompositionStore {
  MealCompositionStore(this._api, this._plans, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  final MealCompositionApi _api;
  final MealPlanStore _plans;
  final FlutterSecureStorage _storage;
  final ObservableMap<String, CompositionContext> contexts = ObservableMap();
  final ObservableMap<String, bool> busy = ObservableMap();
  final ObservableMap<String, String> messages = ObservableMap();
  final Map<String, Set<String>> _selected = {};
  final Observable<int> _selectionVersion = Observable(0);
  bool _disposed = false;
  String _key(String pid, String sid) => 'meal-compose:$pid:$sid';
  bool selected(String sid, String id) {
    _selectionVersion.value;
    return _selected[sid]?.contains(id) ?? false;
  }

  void toggle(String sid, String id, bool value) {
    final values = _selected.putIfAbsent(sid, () => {});
    if (value) {
      values.add(id);
    } else {
      values.remove(id);
    }
    runInAction(() => _selectionVersion.value++);
  }

  Future<void> load(String sid) async {
    final pid = _plans.currentPlanId;
    if (pid == null || busy[sid] == true) return;
    runInAction(() => busy[sid] = true);
    try {
      final context = await _api.context(pid, sid);
      if (_disposed || pid != _plans.currentPlanId) return;
      _updateContext(sid, context);
      await _recover(pid, sid);
    } on ApiException catch (e) {
      _message(sid, e.code);
    } catch (_) {
      _message(sid, 'ERR_MEAL_COMPOSITION_FAILED');
    } finally {
      if (!_disposed) runInAction(() => busy[sid] = false);
    }
  }

  Future<void> generate(String sid, {required bool replaceExisting}) async {
    final pid = _plans.currentPlanId;
    final context = contexts[sid];
    if (pid == null ||
        context == null ||
        busy[sid] == true ||
        _plans.isConfirmed) {
      return;
    }
    runInAction(() {
      busy[sid] = true;
      messages.remove(sid);
    });
    try {
      if (await _recover(pid, sid)) return;
      final random = Random.secure();
      final bytes = List<int>.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 15) | 64;
      bytes[8] = (bytes[8] & 63) | 128;
      final hex = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
      final rid =
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
      await _storage.write(key: _key(pid, sid), value: rid);
      final chosen = _selected[sid] ?? {};
      final receipt = await _api.generate(
        pid,
        sid,
        requestId: rid,
        version: context.version,
        replaceExisting: replaceExisting,
        dependents: context.diners
            .where((d) => d.kind == 'DEPENDENT' && chosen.contains(d.id))
            .map((d) => d.id)
            .toList(),
        guests: context.diners
            .where((d) => d.kind == 'GUEST' && chosen.contains(d.id))
            .map((d) => d.id)
            .toList(),
      );
      await _accept(pid, sid, receipt);
    } on ApiException catch (e) {
      _message(sid, e.code);
      // Keep the durable request ID: the server may have committed after a lost response.
      try {
        await _recover(pid, sid);
      } on ApiException catch (_) {
        /* Retry explicitly on next open/tap. */
      }
    } catch (_) {
      _message(sid, 'ERR_MEAL_COMPOSITION_FAILED');
    } finally {
      if (!_disposed) runInAction(() => busy[sid] = false);
    }
  }

  Future<bool> _recover(String pid, String sid) async {
    final rid = await _storage.read(key: _key(pid, sid));
    if (rid == null) return false;
    try {
      await _accept(pid, sid, await _api.read(pid, sid, rid));
    } on ApiException catch (e) {
      if (e.code == 'ERR_MEAL_COMPOSITION_NOT_FOUND') {
        await _storage.delete(key: _key(pid, sid));
        return false;
      }
      rethrow;
    }
    return true;
  }

  Future<void> _accept(
    String pid,
    String sid,
    CompositionReceipt receipt,
  ) async {
    if (_disposed || pid != _plans.currentPlanId) return;
    _message(sid, receipt.status);
    try {
      if (receipt.status == 'APPLIED' && !await _plans.refreshPlan()) {
        _message(sid, 'APPLIED_SYNC_PENDING');
        return;
      }
      if (receipt.terminal) {
        final context = await _api.context(pid, sid);
        if (!_disposed && pid == _plans.currentPlanId) {
          _updateContext(sid, context);
          // Retain the journal until both the calendar and context reconcile.
          await _storage.delete(key: _key(pid, sid));
        }
      }
    } catch (_) {
      if (receipt.status != 'APPLIED') rethrow;
      // The server already saved the menu. Retrying must only reload it.
      _message(sid, 'APPLIED_SYNC_PENDING');
    }
  }

  void _updateContext(String sid, CompositionContext context) {
    final previous = contexts[sid]?.diners ?? [];
    final current = context.diners.where((d) => d.kind != 'MEMBER');
    final values = _selected.putIfAbsent(sid, () => {});
    values.retainAll(current.map((d) => d.id));
    for (final diner in current) {
      if (!previous.any((d) => d.id == diner.id && d.kind == diner.kind)) {
        values.add(diner.id);
      }
    }
    runInAction(() {
      contexts[sid] = context;
      _selectionVersion.value++;
    });
  }

  void _message(String sid, String code) {
    if (!_disposed) runInAction(() => messages[sid] = code);
  }

  void dispose() {
    _disposed = true;
  }
}
