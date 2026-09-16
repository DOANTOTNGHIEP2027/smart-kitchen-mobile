import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';

/// Stub InventoryApi programable cho test inventory store — bám pattern
/// _StubHealthApi ở profile_store_test.dart.
class FakeInventoryApi implements InventoryApi {
  Future<InventoryItemModel> Function(Map<String, dynamic>)? onCreate;
  Future<InventoryItemModel> Function(
      String, int, Map<String, dynamic>)? onUpdate;
  Future<void> Function(String, int, String)? onDelete;
  Future<InventoryItemModel> Function(String)? onGetById;
  Future<InventoryListPage> Function({int page, int size})? onList;

  Object? onCreateError;
  Object? onUpdateError;
  Object? onDeleteError;
  Object? onGetByIdError;
  Object? onListError;

  @override
  Future<InventoryItemModel> create(Map<String, dynamic> payload) async {
    if (onCreateError != null) throw onCreateError!;
    if (onCreate != null) return onCreate!(payload);
    throw UnimplementedError();
  }

  @override
  Future<InventoryItemModel> update(
    String id, {
    required int version,
    required Map<String, dynamic> payload,
  }) async {
    if (onUpdateError != null) throw onUpdateError!;
    if (onUpdate != null) return onUpdate!(id, version, payload);
    throw UnimplementedError();
  }

  @override
  Future<void> delete(
    String id, {
    required int version,
    required String reason,
    String? wasteCause,
  }) async {
    if (onDeleteError != null) throw onDeleteError!;
    if (onDelete != null) {
      await onDelete!(id, version, reason);
      return;
    }
    throw UnimplementedError();
  }

  @override
  Future<InventoryItemModel> getById(String id) async {
    if (onGetByIdError != null) throw onGetByIdError!;
    if (onGetById != null) return onGetById!(id);
    throw UnimplementedError();
  }

  @override
  Future<InventoryListPage> list({int page = 0, int size = 100}) async {
    if (onListError != null) throw onListError!;
    if (onList != null) return onList!(page: page, size: size);
    throw UnimplementedError();
  }
}
