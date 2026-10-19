import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../widgets/states/view_state.dart';
import '../../profile/api/health_api.dart';
import '../../profile/domain/allergen.dart';
import '../../profile/stores/form_status.dart';
import '../../profile/stores/store_error.dart';
import '../data/guest_diner_api.dart';
import '../domain/guest_diner.dart';

/// State cho `GuestDinerScene` (flexible-meal-planning-screens.md §7.2) —
/// MobX thủ công. Không optimistic write: list chỉ đổi SAU khi BE trả OK.
class GuestDinerStore {
  GuestDinerStore(this._api, this._healthApi, this.mealPlanId);

  final GuestDinerApi _api;
  final HealthApi _healthApi;

  /// Id kế hoạch tuần (OD-06).
  final String mealPlanId;

  final Observable<ViewState<List<GuestDiner>>> _dinersState =
      Observable<ViewState<List<GuestDiner>>>(
          const LoadingState<List<GuestDiner>>());
  final Observable<ViewState<List<Allergen>>> _catalogState =
      Observable<ViewState<List<Allergen>>>(
          const LoadingState<List<Allergen>>());
  final Observable<FormStatus> _mutationStatus =
      Observable<FormStatus>(FormStatus.idle);
  final Observable<ApiException?> _mutationError =
      Observable<ApiException?>(null);

  /// Khách VỪA xoá — UI hiện banner "không tự mở lại món đã chặn" 1 lần.
  final Observable<GuestDiner?> _lastRemoved = Observable<GuestDiner?>(null);

  int _dinersLoadSeq = 0;

  ViewState<List<GuestDiner>> get dinersState => _dinersState.value;
  ViewState<List<Allergen>> get catalogState => _catalogState.value;
  FormStatus get mutationStatus => _mutationStatus.value;
  ApiException? get mutationError => _mutationError.value;
  GuestDiner? get lastRemoved => _lastRemoved.value;
  bool get isSubmitting => _mutationStatus.value == FormStatus.submitting;
  bool get isCatalogReady => _catalogState.value is SuccessState<List<Allergen>>;

  /// 2 fetch ĐỘC LẬP — lỗi catalog không chặn danh sách khách và ngược lại.
  Future<void> loadAll() async {
    runInAction(() {
      _dinersState.value = const LoadingState<List<GuestDiner>>();
      _catalogState.value = const LoadingState<List<Allergen>>();
    });
    await Future.wait<void>(<Future<void>>[_loadDiners(), loadCatalog()]);
  }

  Future<void> _loadDiners() async {
    // Nhiều lần tải có thể chồng nhau (load đầu + reload sau add/404) — chỉ
    // áp kết quả của lần gọi MỚI NHẤT, tránh list cũ ghi đè list mới.
    final seq = ++_dinersLoadSeq;
    try {
      final diners = await _api.list(mealPlanId);
      if (seq != _dinersLoadSeq) return;
      runInAction(() => _setDiners(diners));
    } catch (e) {
      if (seq != _dinersLoadSeq) return;
      // Lỗi parse (TypeError/FormatException) cũng phải ra ErrorState, không
      // để spinner treo mãi.
      runInAction(() => _dinersState.value =
          ErrorState<List<GuestDiner>>(storeApiException(e)));
    }
  }

  Future<void> loadCatalog() async {
    runInAction(
        () => _catalogState.value = const LoadingState<List<Allergen>>());
    try {
      final catalog = await _healthApi.getAllergenCatalog();
      runInAction(
          () => _catalogState.value = SuccessState<List<Allergen>>(catalog));
    } catch (e) {
      // HealthApi chưa `_unwrap` — có thể ném DioException thay vì ApiException.
      runInAction(() => _catalogState.value =
          ErrorState<List<Allergen>>(storeApiException(e)));
    }
  }

  Future<bool> add({String? displayName, required Set<int> allergenIds}) {
    final name = displayName?.trim();
    return _mutate(() async {
      final created = await _api.add(
        mealPlanId,
        displayName: name == null || name.isEmpty ? null : name,
        allergenIds: allergenIds.toList()..sort(),
      );
      if (_isDinersLoaded) {
        runInAction(
            () => _setDiners(<GuestDiner>[..._currentDiners, created]));
      } else {
        // List chưa tải được — nối vào list rỗng sẽ giấu khách đã có trên BE.
        await _loadDiners();
      }
    });
  }

  Future<bool> updateAllergens(String guestDinerId, Set<int> allergenIds) =>
      _mutate(() async {
        final updated = await _api.updateAllergens(
            mealPlanId, guestDinerId, allergenIds.toList()..sort());
        runInAction(() => _setDiners(<GuestDiner>[
              for (final d in _currentDiners) d.id == guestDinerId ? updated : d,
            ]));
      });

  Future<bool> remove(GuestDiner diner) => _mutate(() async {
        await _api.remove(mealPlanId, diner.id);
        runInAction(() {
          _setDiners(_currentDiners.where((d) => d.id != diner.id).toList());
          _lastRemoved.value = diner;
        });
      });

  void clearLastRemoved() => runInAction(() => _lastRemoved.value = null);

  /// Không reset khi đang có request — nếu không, guard `isSubmitting` của
  /// [_mutate] bị vô hiệu và kết quả request cũ đổ vào form mới.
  void clearMutationStatus() {
    if (isSubmitting) return;
    runInAction(() {
      _mutationStatus.value = FormStatus.idle;
      _mutationError.value = null;
    });
  }

  bool get _isDinersLoaded {
    final state = _dinersState.value;
    return state is SuccessState<List<GuestDiner>> ||
        state is EmptyState<List<GuestDiner>>;
  }

  List<GuestDiner> get _currentDiners {
    final state = _dinersState.value;
    return state is SuccessState<List<GuestDiner>>
        ? state.data
        : const <GuestDiner>[];
  }

  void _setDiners(List<GuestDiner> diners) {
    _dinersState.value = diners.isEmpty
        ? const EmptyState<List<GuestDiner>>()
        : SuccessState<List<GuestDiner>>(diners);
  }

  Future<bool> _mutate(Future<void> Function() call) async {
    if (isSubmitting) return false;
    runInAction(() {
      _mutationStatus.value = FormStatus.submitting;
      _mutationError.value = null;
    });
    try {
      await call();
      runInAction(() => _mutationStatus.value = FormStatus.success);
      return true;
    } catch (error) {
      final e = storeApiException(error);
      runInAction(() {
        _mutationError.value = e;
        _mutationStatus.value = FormStatus.failure;
      });
      // §12: khách đã bị xoá ở thiết bị khác → tải lại list cho khớp BE.
      if (e.code == 'ERR_MEAL_GUEST_DINER_NOT_FOUND') {
        unawaited(_loadDiners());
      }
      return false;
    }
  }
}
