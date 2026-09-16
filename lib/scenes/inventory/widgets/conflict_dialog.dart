import 'package:flutter/material.dart';

import '../../../constants/app_dimens.dart';
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
      title: const Text(
          'Dữ liệu đã bị thay đổi bởi thành viên khác. Đang làm mới…'),
      content: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _Column(
                title: 'Của bạn',
                item: conflict.local,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: _Column(
                title: 'Trên server',
                item: conflict.server,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: onUseServer, child: const Text('Dùng của server')),
        FilledButton(onPressed: onKeepMine, child: const Text('Giữ của tôi')),
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
        _Pair(label: 'Tên', value: item.name),
        _Pair(
            label: 'Số lượng',
            value: '${item.displayQuantity ?? item.quantity} ${item.displayUnit ?? item.unit}'),
        _Pair(label: 'Nhóm', value: item.category ?? '—'),
        if (item.expiryDate != null)
          _Pair(
              label: 'HSD',
              value:
                  '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}'),
        _Pair(label: 'Version', value: 'v${item.version}'),
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
