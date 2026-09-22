import 'package:flutter/material.dart';

import '../../../constants/app_dimens.dart';
import '../../../utils/l10n_x.dart';
import '../domain/inventory_item.dart';
import '../stores/inventory_form_store.dart';

/// Dialog hiển thị 2 cột: local (draft người dùng vừa nhập) vs server
/// (snapshot mới nhất từ `GET /inventory-items/{id}`). (FE-5 §10 D11.)
///
/// Đây là **AC 2 Phase 0 US 2.1**: nhận 409 optimistic locking → dialog
/// *"Dữ liệu đã bị thay đổi bởi thành viên khác. Đang làm mới…"* → auto refetch.
class ConflictDialog extends StatelessWidget {
  const ConflictDialog({
    super.key,
    required this.conflict,
    required this.onKeepMine,
    required this.onUseServer,
  });

  /// `local` = draft người dùng vừa cố lưu. `server` = state thật từ
  /// `_api.getById(itemId)` sau khi 409 (body 409 không mang server state,
  /// phải GET — D11).
  final InventoryConflict conflict;
  final VoidCallback onKeepMine;
  final VoidCallback onUseServer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(context.l10n.inventoryConflictMessage),
      content: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _Column(
                title: context.l10n.inventoryYours,
                item: conflict.local,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: _Column(
                title: context.l10n.inventoryServer,
                item: conflict.server,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: onUseServer, child: Text(context.l10n.inventoryUseServer)),
        FilledButton(onPressed: onKeepMine, child: Text(context.l10n.inventoryKeepMine)),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.title,
    required this.item,
    required this.color,
  });

  final String title;
  final InventoryItemModel item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: AppDimens.xs),
        _Pair(label: context.l10n.inventoryName, value: item.name),
        _Pair(
            label: context.l10n.inventoryQuantityLabel,
            value: '${item.displayQuantity ?? item.quantity} ${item.displayUnit ?? item.unit}'),
        _Pair(label: context.l10n.inventoryCategory, value: item.category ?? '—'),
        if (item.expiryDate != null)
          _Pair(
              label: context.l10n.inventoryExpiry,
              value:
                  '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}'),
        _Pair(label: context.l10n.inventoryVersion, value: 'v${item.version}'),
      ],
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}
