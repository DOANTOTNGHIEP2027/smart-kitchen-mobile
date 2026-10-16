import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_api.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_transaction.dart';

/// Stub InventoryApi programable cho test inventory store — bám pattern
/// _StubHealthApi ở profile_store_test.dart.
class FakeInventoryApi implements InventoryApi {
  Future<InventoryItemModel> Function(Map<String, dynamic>)? onCreate;
  Future<InventoryItemModel> Function(String, int, Map<String, dynamic>)?
      onUpdate;
  Future<void> Function(String, int, String)? onDelete;
  Future<InventoryItemModel> Function(String)? onGetById;
  Future<InventoryListPage> Function({int page, int size})? onList;
  Future<InventoryTransactionPage> Function(String, int, int)? onTransactions;
  String? lastDeleteWasteCause;

  Object? onCreateError;
  Object? onUpdateError;
  Object? onDeleteError;
  Object? onGetByIdError;
  Object? onListError;
  Object? onTransactionsError;

  /// Idempotency key nhận được ở các lần gọi [create], theo thứ tự (#55).
  final List<String?> createIdempotencyKeys = <String?>[];

  @override
  Future<InventoryItemModel> create(
    Map<String, dynamic> payload, {
    String? idempotencyKey,
  }) async {
    createIdempotencyKeys.add(idempotencyKey);
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
    lastDeleteWasteCause = wasteCause;
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

  @override
  Future<InventoryTransactionPage> transactions(
    String id, {
    int page = 0,
    int size = 20,
  }) async {
    if (onTransactionsError != null) throw onTransactionsError!;
    if (onTransactions != null) return onTransactions!(id, page, size);
    return const InventoryTransactionPage(
      items: <InventoryTransactionModel>[],
      page: 0,
      size: 20,
      totalElements: 0,
      totalPages: 0,
    );
  }
}
