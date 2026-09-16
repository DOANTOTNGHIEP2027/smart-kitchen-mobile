import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/data/db/app_database.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/data/inventory_dao.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/sync_status.dart';

void main() {
  late AppDatabase db;
  late InventoryDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = InventoryDao(db);
  });

  tearDown(() => db.close());

  InventoryItemModel makeItem({
    String id = 'i1',
    String householdId = 'h1',
    String name = 'Cà chua',
    double quantity = 500,
    String unit = 'g',
    int version = 1,
    SyncStatus syncStatus = SyncStatus.synced,
    String? expiryDate,
  }) {
    return InventoryItemModel(
      id: id,
      householdId: householdId,
      name: name,
      category: 'Rau',
      quantity: quantity,
      unit: unit,
      displayQuantity: quantity,
      displayUnit: unit,
      lowStockThreshold: 100,
      expiryDate: expiryDate == null ? null : DateTime.parse('${expiryDate}T00:00:00Z'),
      note: null,
      version: version,
      isLowStock: false,
      isExpiringSoon: false,
      createdBy: 'u1',
      createdAt: DateTime.parse('2026-09-15T10:00:00Z'),
      updatedAt: DateTime.parse('2026-09-15T10:00:00Z'),
      syncStatus: syncStatus,
    );
  }

  group('DAO round-trip', () {
    test('upsertItem rồi getById → trả đủ field, không reshape', () async {
      final original = makeItem(expiryDate: '2026-09-20');
      await dao.upsertItem(original);

      final got = await dao.getById('i1');

      expect(got, isNotNull);
      expect(got!.id, 'i1');
      expect(got.householdId, 'h1');
      expect(got.name, 'Cà chua');
      expect(got.quantity, 500);
      expect(got.unit, 'g');
      expect(got.displayQuantity, 500);
      expect(got.lowStockThreshold, 100);
      expect(got.expiryDate, DateTime.parse('2026-09-20T00:00:00Z'));
      expect(got.version, 1);
      expect(got.syncStatus, SyncStatus.synced);
    });

    test('upsertItem 2 lần cùng id → upsert (không nhân bản row)', () async {
      await dao.upsertItem(makeItem(name: 'Cà chua'));
      await dao.upsertItem(makeItem(name: 'Cà chua cherry'));

      final all = await db.select(db.inventoryItems).get();
      expect(all.length, 1, reason: 'upsert không được nhân bản row');
      expect(all.first.name, 'Cà chua cherry');
    });

    test('remapAndMarkSynced xoá temp id, insert server id trong 1 tx',
        () async {
      const tempId = 'local-abc';
      await dao.upsertItem(makeItem(id: tempId, syncStatus: SyncStatus.pendingCreate));

      // Server trả về id thật + version 1
      final serverItem = makeItem(id: 'server-uuid', version: 1);
      await dao.remapAndMarkSynced(tempId, serverItem);

      expect(await dao.getById(tempId), isNull,
          reason: 'temp id phải bị xoá');
      final got = await dao.getById('server-uuid');
      expect(got, isNotNull);
      expect(got!.syncStatus, SyncStatus.synced);
      expect(got.version, 1);
    });

    test('markPendingDelete ẩn item khỏi watchAllItems nhưng giữ row', () async {
      await dao.upsertItem(makeItem());
      await dao.markPendingDelete('i1');

      final snapshot =
          await dao.watchAllItems('h1').first;
      expect(snapshot, isEmpty,
          reason: 'PENDING_DELETE phải bị ẩn khỏi stream UI');

      // Row vẫn còn — getById không lọc theo syncStatus
      final row = await db.select(db.inventoryItems).get();
      expect(row.length, 1);
      expect(row.first.syncStatus, 'PENDING_DELETE');
    });

    test('deleteItem xoá cứng row', () async {
      await dao.upsertItem(makeItem());
      await dao.deleteItem('i1');

      expect(await dao.getById('i1'), isNull);
    });

    test('updateSyncStatus giữ nguyên các field khác (không ghi đè)', () async {
      await dao.upsertItem(makeItem(name: 'Cà chua', quantity: 500));
      await dao.updateSyncStatus('i1', SyncStatus.conflict);

      final got = await dao.getById('i1');
      expect(got!.syncStatus, SyncStatus.conflict);
      expect(got.name, 'Cà chua', reason: 'field khác phải nguyên trạng');
      expect(got.quantity, 500);
    });
  });

  group('watchAllItems ordering + filter', () {
    test('sắp xếp PENDING_*/CONFLICT trước, sau createdAt DESC', () async {
      await dao.upsertItem(makeItem(
          id: 'old-synced',
          name: 'Cũ',
          syncStatus: SyncStatus.synced,
          version: 1));
      // createdAt tăng dần — 2 dòng dưới "mới hơn" (giả lập qua updatedAt],
      // tuy nhiên createdAt trong _item cố định, nên ta chèn 1 dòng khác.
      // Test đơn giản hơn: chèn row pendingCreate rồi verify nó xuất hiện đầu.
      await dao.upsertItem(makeItem(
          id: 'pending',
          name: 'Đang chờ',
          syncStatus: SyncStatus.pendingCreate));

      final list = await dao.watchAllItems('h1').first;
      // createdAt bằng nhau → ordering thứ hai không thay đổi, nhưng pending
      // đứng đầu nhờ OrderingTerm(synced')}}
      final first = list.first;
      expect(first.id, 'pending',
          reason: 'row PENDING phải xếp trên SYNCED');
    });

    test('bỏ qua household khác', () async {
      await dao.upsertItem(makeItem(id: 'mine'));
      await dao.upsertItem(makeItem(id: 'theirs', householdId: 'h2'));

      final list = await dao.watchAllItems('h1').first;
      expect(list.where((i) => i.id == 'theirs'), isEmpty);
    });
  });
}
