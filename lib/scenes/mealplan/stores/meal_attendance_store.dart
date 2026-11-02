import 'package:mobx/mobx.dart';
import '../../../data/network/api_exception.dart';
import '../data/meal_attendance_api.dart';
import '../domain/meal_attendance.dart';

class MealAttendanceStore {
  MealAttendanceStore(this._api, this.planId, this.slotId);
  final MealAttendanceApi _api;
  final String planId, slotId;
  final Observable<MealAttendance?> _value = Observable(null);
  final Observable<bool> _loading = Observable(false),
      _saving = Observable(false);
  final Observable<ApiException?> _error = Observable(null);
  int _sequence = 0;
  MealAttendance? get value => _value.value;
  bool get loading => _loading.value;
  bool get saving => _saving.value;
  ApiException? get error => _error.value;
  Future<void> load() async {
    if (saving) return;
    final seq = ++_sequence;
    runInAction(() {
      _loading.value = true;
      _error.value = null;
    });
    try {
      final data = await _api.get(planId, slotId);
      if (seq == _sequence) runInAction(() => _value.value = data);
    } on ApiException catch (e) {
      if (seq == _sequence) runInAction(() => _error.value = e);
    } finally {
      if (seq == _sequence) runInAction(() => _loading.value = false);
    }
  }

  Future<void> update(AttendanceStatus status) async {
    if (saving || loading || value?.editable != true) return;
    final seq = ++_sequence;
    runInAction(() {
      _saving.value = true;
      _error.value = null;
    });
    try {
      final data = await _api.update(planId, slotId, status);
      if (seq == _sequence) runInAction(() => _value.value = data);
    } on ApiException catch (e) {
      if (seq == _sequence) runInAction(() => _error.value = e);
    } finally {
      if (seq == _sequence) runInAction(() => _saving.value = false);
    }
  }

  void dispose() {
    _sequence++;
  }
}
