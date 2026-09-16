import 'dart:async';
import 'dart:math';

import 'package:mobx/mobx.dart';

import '../../../data/network/api_exception.dart';
import '../../../stores/session_store.dart';
import '../data/inventory_api.dart';
import '../data/inventory_dao.dart';
import '../domain/inventory_item.dart';
import '../domain/sync_status.dart';
import '../../../services/connectivity_service.dart';

/// Sinh id cục bộ duy nhất cho optimistic CREATE. Không thêm dependency `uuid`
/// (ngoài danh sách §6.1 D-05). Identifiier chỉ cần duy nhất trong phạm vi
/// device, không phải UUID chuẩn — BE sẽ cấp id thật khi CREATE thành công.
String _localId() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  final r = Random().nextInt(1 << 32);
  return 'local-$ts-$r';
}

enum InventoryFormMode { create, edit }

/// Lựa chọn resolve xung đột (FE-5 §10 InventoryConflict).
enum ConflictResolution { keepMine, useServer }

/// Hộp thoại xung đột 409 — 2 column "của tôi" vs "trên server" (D11 — body
/// 409 không mang state, phải GET lại để dựng dialog).
class InventoryConflict {
  const InventoryConflict({required this.local, required this.server});

  /// Snapshot người dùng vừa cố lưu (đã được ghi optimistic vào DB tạm thời,
  /// hoặc bản `previous` nếu là DELETE).
  final InventoryItemModel local;

  /// State thật từ server, lấy bằng `GET /inventory-items/{id}`.
  final InventoryItemModel server;
}

/// Form add/edit inventory + optimistic write/rollback/conflict (FE-5 §10).
///
/// Scope bản demo (Phase 0 US 2.1) — 3 điều bắt buộc đối chiếu §9.0:
/// 1. PUT/DELETE trả 409 ERR_INVENTORY_VERSION_CONFLICT → hiện dialog rồi tự
///    GET lại item (KHÔNG văng lỗi đỏ chung chung) — đây là AC 2 của Phase 0.
/// 2. Rollback phải exact snapshot `previous`, không phải null.
/// 3. Validate client-side chặn số âm/rỗng/không nguyên khi PIECE/UNIT.
class InventoryFormStore {
  InventoryFormStore({
    required this.mode,
    this.itemId,
    required InventoryDao dao,
    required InventoryApi api,
    required ConnectivityService connectivity,
    required SessionStore sessionStore,
    String Function()? localIdGen,
  })  : _dao = dao,
        _api = api,
        _connectivity = connectivity,
        _session = sessionStore,
        _localIdGen = localIdGen ?? _localId;

  final InventoryFormMode mode;
  final String? itemId;
  final InventoryDao _dao;
  final InventoryApi _api;
  final ConnectivityService _connectivity;
  final SessionStore _session;
  final String Function() _localIdGen;

  final Observable<bool> _isSaving = Observable<bool>(false);
  final Observable<ApiException?> _saveError =
      Observable<ApiException?>(null);
  final Observable<InventoryConflict?> _conflict =
      Observable<InventoryConflict?>(null);

  bool get isSaving => _isSaving.value;
  ApiException? get saveError => _saveError.value;
  InventoryConflict? get conflict => _conflict.value;

  // ── Validation helpers (FE-5 §10.1) ─────────────────────────────────────

  /// Trả null nếu OK, ngược lại chuỗi lỗi (đã được i18n key thay bằng text
  /// tiếng Việt trực tiếp vì convention l10n chưa hoàn thiện — xem file arb]).
  static String? validateName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Tên không được để trống';
    return null;
  }

  static String? validateQuantity(
    String? v, {
    required InventoryFormMode mode,
    required bool mustBeWhole,
  }) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Số lượng không được để trống';
    final n = double.tryParse(s);
    if (n == null) return 'Phải là số';
    if (mode == InventoryFormMode.create && n <= 0) {
      return 'Số lượng phải lớn hơn 0';
    }
    if (mode == InventoryFormMode.edit && n < 0) {
      return 'Số lượng không được âm'; // Phase 0 AC 4 — chặn số âm
    }
    if (mustBeWhole && n != n.roundToDouble()) {
      return 'Với đơn vị "quả/cái", phải là số nguyên';
    }
    return null;
  }

  // ── Public actions ──────────────────────────────────────────────────────

  /// Tạo/sửa optimistic. Trả `true` khi API online thành công VÀ khi offline
  /// (đã enqueue — FE-5 §10 "Offline echo").
  Future<bool> save({
    required String name,
    String? category,
    required double quantity,
    required String unit,
    double? lowStockThreshold,
    DateTime? expiryDate,
    String? note,
  }) async {
    if (_isSaving.value) return false;
    runInAction(() {
      _isSaving.value = true;
      _saveError.value = null;
    });

    final payload = <String, dynamic>{
      'name': name.trim(),
      'category': category?.trim().isEmpty == true ? null : category?.trim(),
      'quantity': quantity,
      'unit': unit,
      'lowStockThreshold': lowStockThreshold,
      'expiryDate':
          expiryDate?.toUtc().toIso8601String().split('T').first,
      'note': note?.trim().isEmpty == true ? null : note?.trim(),
    };

    final isOnline = await _isOnline();
    final now = DateTime.now();

    try {
      if (mode == InventoryFormMode.create) {
        final tempId = _localIdGen();
        final optimistic = InventoryItemModel(
          id: tempId,
          householdId: _session.householdId ?? '',
          name: name.trim(),
          category: category?.trim().isEmpty == true ? null : category?.trim(),
          quantity: quantity,
          unit: unit,
          displayQuantity: quantity,
          displayUnit: unit,
          lowStockThreshold: lowStockThreshold,
          expiryDate: expiryDate,
          note: note?.trim().isEmpty == true ? null : note?.trim(),
          version: 0,
          isLowStock: lowStockThreshold != null && quantity <= lowStockThreshold,
          isExpiringSoon: expiryDate != null &&
              !expiryDate.isAfter(now.add(const Duration(days: 3))),
          createdBy: _session.currentUser?.id ?? 'unknown',
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
        );
        // Optimistic ghi ngay — UI list thấy item mới trước khi API trả.
        await _dao.upsertItem(optimistic);

        if (!isOnline) {
          runInAction(() => _isSaving.value = false);
          return true; // đã enqueue — save() interface vẫn thành công
        }
        try {
          final serverItem = await _api.create(payload);
          // Remap: temp id không đổi được (PK) — xoá row temp + insert server
          await _dao.remapAndMarkSynced(tempId, serverItem);
          runInAction(() => _isSaving.value = false);
          return true;
        } on ApiException catch (e) {
          await _dao.deleteItem(tempId); // rollback CREATE = xoá temp row
          runInAction(() {
            _saveError.value = e;
            _isSaving.value = false;
          });
          return false;
        }
      }

      // EDIT
      final id = itemId!;
      final previous = await _dao.getById(id);
      if (previous == null) {
        runInAction(() {
          _saveError.value = BusinessException(
            'ERR_INVENTORY_NOT_FOUND',
            'Không tìm thấy mặt hàng — có thể đã bị xoá ở thiết bị khác.',
          );
          _isSaving.value = false;
        });
        return false;
      }

      final optimistic = previous.copyWith(
        name: name.trim(),
        category: category?.trim().isEmpty == true ? null : category?.trim(),
        quantity: quantity,
        unit: unit,
        displayQuantity: quantity,
        displayUnit: unit,
        lowStockThreshold: lowStockThreshold,
        expiryDate: expiryDate,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        updatedAt: now,
        version: previous.version + 1,
        isLowStock: lowStockThreshold != null && quantity <= lowStockThreshold,
        isExpiringSoon: expiryDate != null &&
            !expiryDate.isAfter(now.add(const Duration(days: 3))),
        syncStatus: SyncStatus.pendingUpdate,
      );
      await _dao.upsertItem(optimistic);

      try {
        final serverItem = await _api.update(
          id,
          version: previous.version,
          payload: payload,
        );
        await _dao.markSynced(id, serverItem);
        runInAction(() {
          _isSaving.value = false;
          _conflict.value = null;
        });
        return true;
      } on BusinessException catch (e) {
        if (e.code == 'ERR_INVENTORY_VERSION_CONFLICT') {
          // PhASE 0 US 2.1 AC 2: dialog + auto refetch, không văng lỗi đỏ.
          await _dao.updateSyncStatus(id, SyncStatus.conflict);
          await _buildConflict(local: optimistic, itemId: id);
          runInAction(() => _isSaving.value = false);
          return false;
        }
        if (e.code == 'ERR_INVENTORY_NOT_FOUND') {
          // Fix HIGH-1: item không còn ở server — xoá cục bộ, không rollback.
          await _dao.deleteItem(id);
          runInAction(() {
            _saveError.value = e;
            _isSaving.value = false;
          });
          return false;
        }
        // Lỗi khác → rollback về đúng snapshot trước đó.
        await _dao.upsertItem(previous);
        runInAction(() {
          _saveError.value = e;
          _isSaving.value = false;
        });
        return false;
      } on ApiException catch (e) {
        await _dao.upsertItem(previous);
        runInAction(() {
          _saveError.value = e;
          _isSaving.value = false;
        });
        return false;
      }
    } catch (e) {
      runInAction(() {
        _saveError.value =
            ServerException('ERR_UNKNOWN', e.toString());
        _isSaving.value = false;
      });
      return false;
    }
  }

  /// Xoá item (FE-5 §10 `delete`). `reason` bắt buộc: 'COOKED' | 'WASTE' |
  /// 'CORRECTED' (Decision D8 + fix M12).
  Future<bool> delete({required String reason}) async {
    if (_isSaving.value) return false;
    runInAction(() {
      _isSaving.value = true;
      _saveError.value = null;
    });
    final id = itemId!;
    final previous = await _dao.getById(id);
    if (previous == null) {
      runInAction(() {
        _saveError.value = BusinessException(
          'ERR_INVENTORY_NOT_FOUND',
          'Không tìm thấy mặt hàng.',
        );
        _isSaving.value = false;
      });
      return false;
    }

    // Optimistic hide — list sẽ bỏ item ngay qua watchAllItems filter.
    await _dao.markPendingDelete(id);
    final isOnline = await _isOnline();

    if (!isOnline) {
      runInAction(() => _isSaving.value = false);
      return true;
    }

    try {
      await _api.delete(
        id,
        version: previous.version,
        reason: reason,
      );
      await _dao.deleteItem(id);
      runInAction(() {
        _isSaving.value = false;
        _conflict.value = null;
      });
      return true;
    } on BusinessException catch (e) {
      if (e.code == 'ERR_INVENTORY_VERSION_CONFLICT') {
        await _dao.updateSyncStatus(id, SyncStatus.conflict);
        await _buildConflict(local: previous, itemId: id);
        runInAction(() => _isSaving.value = false);
        return false;
      }
      if (e.code == 'ERR_INVENTORY_NOT_FOUND') {
        // Item đã không còn — cùng ý người dùng, coi là thành công.
        await _dao.deleteItem(id);
        runInAction(() {
          _isSaving.value = false;
          _conflict.value = null;
        });
        return true;
      }
      await _dao.upsertItem(previous); // rollback — item hiện lại
      runInAction(() {
        _saveError.value = e;
        _isSaving.value = false;
      });
      return false;
    } on ApiException catch (e) {
      await _dao.upsertItem(previous);
      runInAction(() {
        _saveError.value = e;
        _isSaving.value = false;
      });
      return false;
    } catch (e) {
      runInAction(() {
        _saveError.value =
            ServerException('ERR_UNKNOWN', e.toString());
        _isSaving.value = false;
      });
      return false;
    }
  }

  /// Xoá optimistic bằng cách retry lưu — giữ field user đã nhập, nâng version
  /// lên của server (FE-5 §10 `resolveConflict`).
  Future<bool> resolveConflict(ConflictResolution resolution) async {
    final c = _conflict.value;
    if (c == null) return false;

    if (resolution == ConflictResolution.useServer) {
      await _dao.upsertItem(
          c.server.copyWith(syncStatus: SyncStatus.synced));
      runInAction(() => _conflict.value = null);
      return true;
    }

    // keepMine — retry save
    final ok = await save(
      name: c.local.name,
      category: c.local.category,
      quantity: c.local.quantity,
      unit: c.local.unit,
      lowStockThreshold: c.local.lowStockThreshold,
      expiryDate: c.local.expiryDate,
      note: c.local.note,
    );
    if (ok) {
      runInAction(() => _conflict.value = null);
    }
    return ok;
  }

  void clearError() => runInAction(() => _saveError.value = null);

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// D11 — 409 không mang state server trong body; phải GET lại để dựng
  /// dialog hai cột. Bỏ bước này là đoán mò state.
  Future<void> _buildConflict({
    required InventoryItemModel local,
    required String itemId,
  }) async {
    try {
      final server = await _api.getById(itemId);
      runInAction(() => _conflict.value =
          InventoryConflict(local: local, server: server));
    } on ApiException catch (e) {
      runInAction(() => _saveError.value = e);
    }
  }

  Future<bool> _isOnline() async {
    try {
      return await _connectivity.isOnline();
    } catch (_) {
      return true; // không detect được → cố gửi, BE sẽ phán quyết
    }
  }
}
