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

  /// #201: BE trả 409 khi bữa đã qua — UI ghi rõ lý do thay vì "chưa lưu được".
  bool get isClosedError => _error.value?.code == 'ERR_PLAN_ATTENDANCE_CLOSED';

  Future<void> load() async {
    // Đang lưu thì kết quả lưu là bản mới nhất — không tải chen vào.
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

  /// Đổi xác nhận của chính mình. `unknown` = xoá phản hồi (DELETE .../me,
  /// không bao giờ gửi "UNKNOWN").
  ///
  /// #201: KHÔNG chặn khi đang `load()` (vd. app vừa resume tự tải lại) — trước
  /// đây bấm lúc đó bị nuốt im lặng. Lần lưu tăng `_sequence` nên kết quả tải
  /// cũ về sau bị bỏ qua, và phải tự tắt cờ `loading` của lần tải đó (finally
  /// của nó không còn khớp sequence).
  Future<void> update(AttendanceStatus status) async {
    final current = value;
    if (saving || current == null || !current.editable) return;
    if (current.myStatus == status) return;
    final seq = ++_sequence;
    runInAction(() {
      _saving.value = true;
      _loading.value = false;
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
    // Bữa vừa đóng (409) → tải lại để có `editable=false`, giữ lỗi để hiện lý do.
    if (seq == _sequence && isClosedError) {
      final closedError = _error.value;
      await load();
      if (_error.value == null) runInAction(() => _error.value = closedError);
    }
  }

  void dispose() {
    _sequence++;
  }
}
