import 'dart:async';
import 'dart:math';

import 'package:mobx/mobx.dart';

import '../../../stores/session_store.dart';
import '../data/shopping_category_dao.dart';
import '../domain/shopping_category.dart';

/// Lỗi validate CỤC BỘ của category — KHÔNG phải ApiException, không có network
/// round-trip nào đằng sau (Guard #9). UI dịch qua l10n.
enum CategoryError { empty, tooLong, duplicate, saveFailed }

/// Category đi chợ local-only (#69 §8). Đăng ký DUY NHẤT ở `ShoppingListBinding`
/// (Guard #11).
class CategoryStore {
  CategoryStore(this._dao, this._session);

  final ShoppingCategoryDao _dao;
  final SessionStore _session;

  /// Khớp `@Size(max=100)` của `shopping_items.category` ở BE.
  static const int maxNameLength = 100;

  StreamSubscription<List<ShoppingCategory>>? _sub;
  final ObservableList<ShoppingCategory> _categories = ObservableList<ShoppingCategory>();
  final Observable<bool> _loading = Observable<bool>(true);
  final Observable<CategoryError?> _error = Observable<CategoryError?>(null);
  final Observable<bool> _loadFailed = Observable<bool>(false);
  String? _loadedHousehold;

  List<ShoppingCategory> get categories => List.unmodifiable(_categories);
  bool get isLoading => _loading.value;
  /// Stream Drift báo lỗi (DB hỏng…) — màn hiện trạng thái lỗi + thử lại,
  /// không quay loading mãi.
  bool get loadFailed => _loadFailed.value;
  CategoryError? get error => _error.value;

  /// Idempotent: đang nghe đúng household thì giữ nguyên (không nháy loading
  /// khi mở màn quản lý); [force] = nghe lại (nút thử lại). Đổi household →
  /// huỷ subscription cũ và nghe lại.
  Future<void> loadCategories({bool force = false}) async {
    final householdId = _session.householdId;
    if (!force && _sub != null && householdId != null && householdId == _loadedHousehold) return;
    // Gỡ subscription cũ và gắn cái mới ĐỒNG BỘ, chỉ await huỷ ở cuối: một
    // `await` trước khi gán `_sub` (kể cả `await null`) mở khe cho lần gọi
    // song song cũng lọt qua kiểm tra trên → 2 subscription, 1 cái rò.
    final old = _sub;
    _sub = null;
    final switched = householdId != _loadedHousehold;
    _loadedHousehold = householdId;
    if (householdId == null) {
      runInAction(() {
        _categories.clear();
        _loading.value = false;
      });
      await old?.cancel();
      return;
    }
    runInAction(() {
      // Đổi household → bỏ danh mục cũ ngay, không để sheet hiện chip của
      // household trước trong lúc chờ stream mới emit.
      if (switched) _categories.clear();
      _loading.value = true;
      _loadFailed.value = false;
    });
    _sub = _dao.watchAll(householdId).listen(
      (rows) => runInAction(() {
        _categories
          ..clear()
          ..addAll(rows);
        _loading.value = false;
        _loadFailed.value = false;
      }),
      onError: (Object _) => runInAction(() {
        _loading.value = false;
        _loadFailed.value = true;
      }),
    );
    await old?.cancel();
  }

  /// Trả về tên đã trim nếu hợp lệ; ngược lại đặt [error] và trả `null`.
  Future<String?> _validate(String householdId, String name, {String? exceptId}) async {
    final trimmed = name.trim();
    CategoryError? err;
    if (trimmed.isEmpty) {
      err = CategoryError.empty;
    } else if (trimmed.length > maxNameLength) {
      err = CategoryError.tooLong;
    } else {
      // Đọc Drift lỗi phải về saveFailed như lúc ghi — ném ra ngoài thì
      // dialog kẹt `_saving = true`, nút Lưu disabled vĩnh viễn.
      try {
        if (await _dao.existsByName(householdId, trimmed, exceptId: exceptId)) {
          err = CategoryError.duplicate;
        }
      } catch (_) {
        err = CategoryError.saveFailed;
      }
    }
    if (err != null) runInAction(() => _error.value = err);
    return err == null ? trimmed : null;
  }

  Future<bool> addCategory({required String name, required String colorHex}) async {
    clearError();
    final householdId = _session.householdId;
    if (householdId == null) return _fail();
    final trimmed = await _validate(householdId, name);
    if (trimmed == null) return false;
    return _guard(() async => _dao.insert(ShoppingCategory(
          id: 'cat-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}',
          householdId: householdId,
          name: trimmed,
          colorHex: colorHex,
          // Tính trong DB, không theo list đang hiển thị (có thể chưa emit).
          sortOrder: await _dao.nextSortOrder(householdId),
          createdAt: DateTime.now(),
        )));
  }

  Future<bool> updateCategory(String id, {required String name, required String colorHex}) async {
    clearError();
    final householdId = _session.householdId;
    final existing = _categories.where((c) => c.id == id).firstOrNull;
    if (householdId == null || existing == null) return _fail();
    final trimmed = await _validate(householdId, name, exceptId: id);
    if (trimmed == null) return false;
    return _guard(() => _dao.update(existing.copyWith(name: trimmed, colorHex: colorHex)));
  }

  /// Chỉ xoá bảng local — KHÔNG đụng `shopping_items.category` nào (Guard #4).
  /// Id không tồn tại → no-op. Gỡ khỏi list NGAY (optimistic) — `Dismissible`
  /// đòi rời cây ngay sau `onDismissed`; lỗi ghi → trả đúng snapshot cũ.
  Future<bool> deleteCategory(String id) => _optimistic(
        (list) => list.removeWhere((c) => c.id == id),
        () => _dao.delete(id),
      );

  /// [orderedIds] PHẢI là danh sách ĐẦY ĐỦ theo thứ tự mới. Đổi thứ tự trong
  /// list ngay (không giật về chỗ cũ chờ Drift emit); lỗi ghi → snapshot cũ.
  Future<bool> reorderCategories(List<String> orderedIds) => _optimistic(
        (list) {
          final byId = <String, ShoppingCategory>{for (final c in list) c.id: c};
          list
            ..clear()
            ..addAll(<ShoppingCategory>[for (final id in orderedIds) if (byId[id] != null) byId[id]!]);
        },
        () => _dao.reorder(orderedIds),
      );

  Future<bool> _optimistic(void Function(List<ShoppingCategory> list) apply, Future<void> Function() write) async {
    final snapshot = List<ShoppingCategory>.of(_categories);
    final household = _loadedHousehold;
    runInAction(() => apply(_categories));
    final ok = await _guard(write);
    // Đã đổi household trong lúc ghi → snapshot là của household cũ, không
    // được đè lên danh mục mới.
    if (!ok && household == _loadedHousehold) {
      runInAction(() => _categories
        ..clear()
        ..addAll(snapshot));
    }
    return ok;
  }

  /// Ghi Drift lỗi hiếm (disk full/corrupt) → báo, không crash (§14).
  Future<bool> _guard(Future<void> Function() write) async {
    try {
      await write();
      return true;
    } catch (_) {
      runInAction(() => _error.value = CategoryError.saveFailed);
      return false;
    }
  }

  /// Không có household / category đã bị xoá dưới tay — báo lỗi thay vì trả
  /// `false` im lặng (dialog sẽ đứng yên, không lý do).
  bool _fail() {
    runInAction(() => _error.value = CategoryError.saveFailed);
    return false;
  }

  void clearError() => runInAction(() => _error.value = null);

  void dispose() => _sub?.cancel();
}
