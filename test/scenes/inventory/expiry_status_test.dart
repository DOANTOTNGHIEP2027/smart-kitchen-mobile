import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen_mobile/constants/app_colors.dart';
import 'package:smart_kitchen_mobile/l10n/app_localizations_vi.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/expiry_status.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/inventory_item.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/domain/sync_status.dart';
import 'package:smart_kitchen_mobile/scenes/inventory/widgets/inventory_item_tile.dart';

import '../../helpers/pump_app.dart';

/// Ngày server gửi được mapper parse thành UTC 00:00 (`yyyy-MM-ddT00:00:00Z`).
DateTime _serverDate(int y, int m, int d) => DateTime.utc(y, m, d);

InventoryItemModel _item(String id, DateTime? expiry, {bool serverFlag = true}) =>
    InventoryItemModel(
      id: id,
      householdId: 'h1',
      name: 'Món $id',
      category: null,
      quantity: 1,
      unit: 'PIECE',
      displayQuantity: 1,
      displayUnit: 'cái',
      lowStockThreshold: null,
      expiryDate: expiry,
      note: null,
      version: 1,
      isLowStock: false,
      // Cờ server cũ luôn bật cho món quá hạn — nhãn không được dựa vào nó.
      isExpiringSoon: serverFlag,
      createdBy: 'u1',
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
      syncStatus: SyncStatus.synced,
    );

void main() {
  final l10n = AppLocalizationsVi();
  // 23:59 giờ máy — ngày local vẫn là 28/11 dù UTC đã sang ngày khác ở múi khác.
  final now = DateTime(2026, 11, 28, 23, 59);

  group('expiryStatusOf (so theo NGÀY)', () {
    test('hôm qua → đã hết hạn', () {
      expect(expiryStatusOf(_serverDate(2026, 11, 27), now), ExpiryStatus.expired);
    });

    test('hôm nay (kể cả 23:59, date UTC 00:00) → đến hạn hôm nay', () {
      expect(expiryStatusOf(_serverDate(2026, 11, 28), now), ExpiryStatus.today);
      expect(expiryStatusOf(_serverDate(2026, 11, 28), DateTime(2026, 11, 28)), ExpiryStatus.today);
      expect(expiryStatusOf(DateTime(2026, 11, 28), now), ExpiryStatus.today);
    });

    test('+1 và +3 ngày → sắp hết hạn; +4 → không nhấn mạnh', () {
      expect(expiryStatusOf(_serverDate(2026, 11, 29), now), ExpiryStatus.soon);
      expect(expiryStatusOf(_serverDate(2026, 12, 1), now), ExpiryStatus.soon);
      expect(expiryStatusOf(_serverDate(2026, 12, 2), now), ExpiryStatus.none);
    });

    test('không có hạn → none', () {
      expect(expiryStatusOf(null, now), ExpiryStatus.none);
    });
  });

  group('InventoryItemTile — nhãn và màu theo trạng thái', () {
    Future<void> pumpTile(WidgetTester tester, InventoryItemModel item) =>
        tester.pumpAppWidget(InventoryItemTile(item: item, onTap: () {}, now: now));

    Color labelColor(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;

    testWidgets('đã hết hạn → "Đã hết hạn" màu đỏ', (tester) async {
      await pumpTile(tester, _item('a', _serverDate(2026, 11, 20)));
      expect(find.text(l10n.inventoryExpired), findsOneWidget);
      expect(find.text(l10n.inventoryExpiringSoon), findsNothing);
      expect(labelColor(tester, l10n.inventoryExpired), AppColors.error);
    });

    testWidgets('đến hạn hôm nay → "Đến hạn hôm nay" màu cam', (tester) async {
      await pumpTile(tester, _item('b', _serverDate(2026, 11, 28)));
      expect(find.text(l10n.inventoryExpiresToday), findsOneWidget);
      expect(labelColor(tester, l10n.inventoryExpiresToday), AppColors.secondary);
    });

    testWidgets('sắp hết hạn → giữ "HSD sắp tới" màu vàng hổ phách', (tester) async {
      await pumpTile(tester, _item('c', _serverDate(2026, 11, 30)));
      expect(find.text(l10n.inventoryExpiringSoon), findsOneWidget);
      expect(labelColor(tester, l10n.inventoryExpiringSoon), AppColors.warning);
    });

    testWidgets('còn xa hạn → không nhãn, dù cờ server còn bật', (tester) async {
      await pumpTile(tester, _item('d', _serverDate(2026, 12, 20)));
      expect(find.text(l10n.inventoryExpired), findsNothing);
      expect(find.text(l10n.inventoryExpiresToday), findsNothing);
      expect(find.text(l10n.inventoryExpiringSoon), findsNothing);
    });
  });
}
