import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../widgets/states/view_state.dart';
import '../../profile/stores/form_status.dart';
import '../../profile/stores/store_error.dart';
import '../data/meal_slot_api.dart';
import '../domain/meal_slot_template_item.dart';

/// Lỗi validate client-side thuần (chưa chạm mạng) — KHÔNG mượn
/// `ApiException` (thiết kế §7.1 Fix HIGH-2). UI map sang chuỗi l10n.
enum MealSlotDraftError { empty, tooMany, duplicateKey, blankLabel }

/// State cho `MealSlotConfigScene` (flexible-meal-planning-screens.md §7.1) —
/// MobX thủ công (Observable + runInAction). Không optimistic write.
class MealSlotStore {
  MealSlotStore(this._api);

  static const int maxSlots = 10;

  final MealSlotApi _api;

  final Observable<ViewState<List<MealSlotTemplateItem>>> _templateState =
      Observable<ViewState<List<MealSlotTemplateItem>>>(
          const LoadingState<List<MealSlotTemplateItem>>());

  /// Bản nháp — chỉ gửi lên khi `save()`. Slot rời khỏi draft = BE tự
  /// soft-deactivate ở PUT kế tiếp (không có API xoá riêng).
  final ObservableList<MealSlotTemplateItem> draftSlots =
      ObservableList<MealSlotTemplateItem>();
  final Observable<FormStatus> _saveStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _saveError = Observable<ApiException?>(null);
  final Observable<MealSlotDraftError?> _draftError =
      Observable<MealSlotDraftError?>(null);

  /// User đã thêm/sửa/xoá slot từ lần load/save gần nhất.
  final Observable<bool> _draftTouched = Observable<bool>(false);

  ViewState<List<MealSlotTemplateItem>> get templateState =>
      _templateState.value;
  FormStatus get saveStatus => _saveStatus.value;
  ApiException? get saveError => _saveError.value;
  MealSlotDraftError? get draftError => _draftError.value;
  bool get isSaving => _saveStatus.value == FormStatus.submitting;

  /// Household chưa từng PUT → BE trả 3 DEFAULT_SLOTS ảo. Banner biến mất
  /// ngay khi user sửa/thêm/xoá 1 slot bất kỳ (thiết kế §8.1).
  bool get isUsingDefaults =>
      !_draftTouched.value &&
      draftSlots.isNotEmpty &&
      draftSlots.every((s) => s.isDefault);

  List<MealSlotTemplateItem> get draftEveryDay => slotsOfDay(null);

  /// Slot riêng của 1 ngày — CỘNG THÊM vào nhóm "mọi ngày", không thay thế.
  List<MealSlotTemplateItem> slotsOfDay(int? dayOfWeek) =>
      draftSlots.where((s) => s.dayOfWeek == dayOfWeek).toList()
        ..sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));

  Future<void> load() async {
    runInAction(() {
      _templateState.value = const LoadingState<List<MealSlotTemplateItem>>();
    });
    try {
      final slots = await _api.getTemplate();
      runInAction(() {
        _templateState.value = SuccessState<List<MealSlotTemplateItem>>(slots);
        draftSlots
          ..clear()
          ..addAll(slots);
        _draftTouched.value = false;
      });
    } catch (e) {
      // Lỗi parse (vd. `scheduledTime` lạ) cũng phải ra ErrorState.
      runInAction(() {
        _templateState.value =
            ErrorState<List<MealSlotTemplateItem>>(storeApiException(e));
      });
    }
  }

  void addSlot(MealSlotTemplateItem slot) => runInAction(() {
        draftSlots.add(slot);
        _clearErrors();
      });

  void removeSlot(MealSlotTemplateItem slot) => runInAction(() {
        draftSlots.remove(slot);
        _clearErrors();
      });

  void replaceSlot(MealSlotTemplateItem oldSlot, MealSlotTemplateItem newSlot) =>
      runInAction(() {
        final index = draftSlots.indexOf(oldSlot);
        if (index < 0) return;
        draftSlots[index] = newSlot;
        _clearErrors();
      });

  /// `slotKey` tự sinh cho bữa tự đặt tên (label tiếng Việt có dấu không
  /// khớp `[A-Z0-9_]`) — `CUSTOM_<n>` nhỏ nhất chưa dùng trong nhóm ngày.
  String nextCustomKey(int? dayOfWeek) {
    final used = draftSlots
        .where((s) => s.dayOfWeek == dayOfWeek)
        .map((s) => s.slotKey)
        .toSet();
    var n = 1;
    while (used.contains('CUSTOM_$n')) {
      n++;
    }
    return 'CUSTOM_$n';
  }

  /// Chặn lỗi rõ trước khi tốn 1 round-trip — KHÔNG thay validate BE.
  MealSlotDraftError? validate() {
    if (draftSlots.isEmpty) return MealSlotDraftError.empty;
    if (draftSlots.length > maxSlots) return MealSlotDraftError.tooMany;
    final seen = <String>{};
    for (final s in draftSlots) {
      if (s.label.trim().isEmpty) return MealSlotDraftError.blankLabel;
      if (!seen.add('${s.dayOfWeek}|${s.slotKey}')) {
        return MealSlotDraftError.duplicateKey;
      }
    }
    return null;
  }

  Future<bool> save() async {
    final error = validate();
    if (error != null) {
      runInAction(() => _draftError.value = error);
      return false;
    }
    runInAction(() {
      _draftError.value = null;
      _saveError.value = null;
      _saveStatus.value = FormStatus.submitting;
    });
    try {
      final saved = await _api.putTemplate(resequence(draftSlots));
      runInAction(() {
        _templateState.value = SuccessState<List<MealSlotTemplateItem>>(saved);
        draftSlots
          ..clear()
          ..addAll(saved);
        _draftTouched.value = false;
        _saveStatus.value = FormStatus.success;
      });
      return true;
    } catch (e) {
      runInAction(() {
        _saveError.value = storeApiException(e);
        _saveStatus.value = FormStatus.failure;
      });
      return false;
    }
  }

  /// Gán lại `sortOrder` 1..n theo giờ trong TỪNG nhóm `dayOfWeek` — BE bắt
  /// unique sortOrder trong cùng (household, dayOfWeek).
  static List<MealSlotTemplateItem> resequence(
      List<MealSlotTemplateItem> slots) {
    final byDay = <int?, List<MealSlotTemplateItem>>{};
    for (final s in slots) {
      byDay.putIfAbsent(s.dayOfWeek, () => <MealSlotTemplateItem>[]).add(s);
    }
    final result = <MealSlotTemplateItem>[];
    for (final group in byDay.values) {
      group.sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
      for (var i = 0; i < group.length; i++) {
        result.add(group[i].copyWith(sortOrder: i + 1));
      }
    }
    return result;
  }

  void clearSaveStatus() => runInAction(() {
        _saveStatus.value = FormStatus.idle;
        _saveError.value = null;
      });

  void _clearErrors() {
    _draftTouched.value = true;
    _draftError.value = null;
    if (_saveStatus.value == FormStatus.failure) {
      _saveStatus.value = FormStatus.idle;
      _saveError.value = null;
    }
  }
}
